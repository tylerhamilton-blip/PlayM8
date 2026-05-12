import 'dart:convert';
import 'package:http/http.dart' as http;

import '../types/models.dart';
import '../storage/local_store.dart'; //NEW: so we can save categories locally

class IgdbService {
  static final String _baseUrl = 'http://${LocalStore.demo()}:8000';

  static Future<List<GameCard>> fetchGames({
    int limit = 30,
    String? genre, 
    List<String>? platforms, 
  }) async {
    final params = <String, String>{
      'limit': '$limit',
    };

    if (genre != null && genre.trim().isNotEmpty && genre != 'All') {
      params['genre'] = genre.trim();
    }

    if (platforms != null && platforms.isNotEmpty) {
      params['platforms'] = platforms.join(',');
    }

    final uri =
    Uri.parse('$_baseUrl/igdb/games').replace(queryParameters: params);

    print('IGDB FETCH -> $uri');

    final resp = await http.get(uri).timeout(const Duration(seconds: 200));
    if (resp.statusCode != 200) {
      throw Exception('Backend error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) {
      final m = e as Map<String, dynamic>;

      final platformsOut = (m['platforms'] as List?)
          ?.map((p) => p.toString())
          .toList() ??
          const <String>[];

      return GameCard(
        id: (m['id']).toString(),
        title: (m['title'] ?? 'Unknown') as String,
        genre: (m['genre'] ?? 'Unknown') as String,
        imageUrl: (m['imageUrl'] as String?) ?? '',
        platforms: platformsOut,
      );
    }).toList();
  }

  static Future<List<String>> fetchPlatforms({int limit = 200}) async {
    final uri = Uri.parse('$_baseUrl/igdb/platforms?limit=$limit');
    print('IGDB PLATFORMS -> $uri');

    final resp = await http.get(uri).timeout(const Duration(seconds: 60));
    if (resp.statusCode != 200) {
      throw Exception('Backend error ${resp.statusCode}: ${resp.body}');
    }

    final decoded = jsonDecode(resp.body);

    if (decoded is List) {
      return decoded.map((e) => e.toString()).toList();
    }

    if (decoded is Map && decoded['platforms'] is List) {
      return (decoded['platforms'] as List).map((e) => e.toString()).toList();
    }

    return <String>[];
  }

  // ==========================================================
  //NEW: Steam -> IGDB category profile
  //GET /steam/profile_categories?steamid=...&top_n=25&top_k=6
  // ==========================================================
  static Future<SteamCategoryProfile> fetchSteamProfileCategories({
    required String steamid,
    int topN = 25,
    int topK = 6,
  }) async {
    final uri = Uri.parse('$_baseUrl/steam/profile_categories').replace(
      queryParameters: {
        'steamid': steamid,
        'top_n': '$topN',
        'top_k': '$topK',
      },
    );

    print('STEAM PROFILE CATEGORIES -> $uri');

    final resp = await http.get(uri).timeout(const Duration(seconds: 120));
    if (resp.statusCode != 200) {
      throw Exception('Backend error ${resp.statusCode}: ${resp.body}');
    }

    final m = jsonDecode(resp.body) as Map<String, dynamic>;

    return SteamCategoryProfile.fromJson(m);
  }

  // ==========================================================
  //NEW: convenience helper
  //Call this once after Steam login (when we have the steamid),
  //and it will save categories as the app's selected genres.
  // ==========================================================
  static Future<List<String>> applySteamTasteToLocalGenres({
    required String steamid,
    int topN = 25,
    int topK = 6,
    int maxToSave = 10, // how many categories you want in your genre picker
    bool includeThemes = true,
  }) async {
    final profile = await fetchSteamProfileCategories(
      steamid: steamid,
      topN: topN,
      topK: topK,
    );

    //How we use the combined ranking list (best overall)
    //Optionally filter out themes by only using top_genres if we want.
    List<String> categories;

    if (includeThemes) {
      categories = profile.allCategoriesRanked;
    } else {
      categories = profile.topGenres;
    }

    // Trim + de-dupe
    final out = <String>[];
    final seen = <String>{};
    for (final c in categories) {
      final t = c.trim();
      if (t.isEmpty) continue;
      if (seen.add(t)) out.add(t);
      if (out.length >= maxToSave) break;
    }

    await LocalStore.saveSelectedGenres(out);

    return out;
  }
}

// ==========================================================
//NEW model for /steam/profile_categories response
// ==========================================================
class SteamCategoryProfile {
  final String steamid;
  final List<String> topGenres;
  final List<String> topThemes;
  final List<String> allCategoriesRanked;
  final int computedFromGames;

  const SteamCategoryProfile({
    required this.steamid,
    required this.topGenres,
    required this.topThemes,
    required this.allCategoriesRanked,
    required this.computedFromGames,
  });

  static SteamCategoryProfile fromJson(Map<String, dynamic> json) {
    List<String> listFrom(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      return const <String>[];
    }

    return SteamCategoryProfile(
      steamid: (json['steamid'] ?? '').toString(),
      topGenres: listFrom(json['top_genres']),
      topThemes: listFrom(json['top_themes']),
      allCategoriesRanked: listFrom(json['all_categories_ranked']),
      computedFromGames: (json['computed_from_games'] is num)
          ? (json['computed_from_games'] as num).toInt()
          : 0,
    );
  }
}
