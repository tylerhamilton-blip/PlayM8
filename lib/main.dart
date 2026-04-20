import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'pages/sign_up.dart';
import 'pages/splash_page.dart';
import 'pages/auth_page.dart';
import 'pages/genre_questionnaire_page.dart';
import 'pages/swipe_page.dart';
import 'pages/history_page.dart';

import 'storage/local_store.dart';
import 'services/igdb_service.dart';//for Steam -> IGDB taste categories

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await LocalStore.init();

  runApp(const PlayM8App());
}

class PlayM8App extends StatefulWidget {
  const PlayM8App({super.key});

  @override
  State<PlayM8App> createState() => _PlayM8AppState();
}

class _PlayM8AppState extends State<PlayM8App> {
  late final GoRouter _router;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;

  //backend base (Android emulator -> host machine)
  static const String _baseUrl = 'http://10.0.2.2:8000';

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
        GoRoute(path: '/genres', builder: (_, __) => const GenreQuestionnairePage()),
        GoRoute(path: '/swipe', builder: (_, __) => const SwipePage()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
        GoRoute(path: '/signup', builder: (_,__) => const SignupPage()),
      ],
    );

    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    //Cold start deep link (app_links returns Uri?)
    try {
      final Uri? initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleDeepLink(initial);
      }
    } catch (_) {
      // ignore
    }

    //Deep links while app is running
    _sub = _appLinks.uriLinkStream.listen((Uri uri) async {
      await _handleDeepLink(uri);
    });
  }

  //Fetch and save Steam owned games so HistoryPage can show them
  Future<void> _fetchAndSaveSteamGames(String steamid) async {
    final uri = Uri.parse('$_baseUrl/steam/owned_games?steamid=$steamid');
    final resp = await http.get(uri).timeout(const Duration(seconds: 30));

    if (resp.statusCode != 200) {
      throw Exception('Steam games backend error ${resp.statusCode}: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);

    // backend returns: {steamid, game_count, games:[{appid,name,playtime_forever,header_image},...]}
    if (decoded is Map && decoded['games'] is List) {
      await LocalStore.saveSteamGames(decoded['games'] as List);
    } else {
      // if backend ever changes shape, fail safely
      await LocalStore.saveSteamGames(const []);
    }
  }

  //Fetch Steam->IGDB taste categories and save them as selected genres for swiping
  //RETURN the imported list so we can show a popup on SwipePage
  Future<List<String>> _fetchAndSaveSteamTasteGenres(String steamid) async {
    //Calls the endpoint /steam/profile_categories (inside IgdbService)
    //and writes into LocalStore.saveSelectedGenres(...)
    //
    //includeThemes=true lets "Horror" work even if it’s a Theme on IGDB.
    await IgdbService.applySteamTasteToLocalGenres(
      steamid: steamid,
      topN: 25,
      topK: 6,
      maxToSave: 10,
      includeThemes: true,
    );

    //Read back what was saved so we can display it in the popup
    final imported = await LocalStore.loadSelectedGenres();
    return imported;
  }

  Future<void> _handleDeepLink(Uri uri) async {
    //Expected from backend callback:
    //playm8://auth/steam?steamid=7656119...
    if (uri.scheme == 'playm8' && uri.host == 'auth' && uri.path == '/steam') {
      final steamid = uri.queryParameters['steamid'];
      if (steamid == null || steamid.isEmpty) return;

      try {
        //Save steamid + mark logged in
        await LocalStore.saveSteamId(steamid);
        await LocalStore.setLoggedIn(true);

        //Prevent mixing users on shared devices
        await LocalStore.clearSteamGames();

        //Pull owned games (for History)
        await _fetchAndSaveSteamGames(steamid);

        //Pull Steam taste categories -> save as selected genres (for Swipe filtering)
        //and capture them for the popup
        final importedGenres = await _fetchAndSaveSteamTasteGenres(steamid);

        //Navigate into the app and pass popup data to SwipePage
        _router.go('/swipe', extra: {
          'steamLinked': true,
          'importedGenres': importedGenres,
        });

        //If you'd rather show the user the genre bubbles page instead:
        //_router.go('/genres', extra: {...});
      } catch (e) {
        //If anything fails, still let user into the app
        _router.go('/swipe');
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PlayM8',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      routerConfig: _router,
    );
  }
}
