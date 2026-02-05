import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'pages/splash_page.dart';
import 'pages/auth_page.dart';
import 'pages/genre_questionnaire_page.dart';
import 'pages/swipe_page.dart';
import 'pages/history_page.dart';
import 'storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await LocalStore.init();

  runApp(const PlayM8App());
}

class PlayM8App extends StatelessWidget {
  const PlayM8App({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/splash',
      routes: [
        GoRoute(path: '/splash', builder: (_, __) => const SplashPage()),
        GoRoute(path: '/auth', builder: (_, __) => const AuthPage()),
        GoRoute(path: '/genres', builder: (_, __) => const GenreQuestionnairePage()),
        GoRoute(path: '/swipe', builder: (_, __) => const SwipePage()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryPage()),
      ],
    );

    return MaterialApp.router(
      title: 'PlayM8',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      routerConfig: router,
    );
  }
}
