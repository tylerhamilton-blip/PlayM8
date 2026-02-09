import 'dart:convert';
import 'package:http/http.dart' as http;

import '../types/models.dart';

class IgdbService {
  // For Android emulator -> host machine localhost is 10.0.2.2
  // If running on real phone, use your PC’s LAN IP instead.
  static const String _baseUrl = 'http://10.0.2.2:8000';

  static Future<List<GameCard>> fetchGames({
    int limit = 30,
  }) async {
    final uri = Uri.parse('$_baseUrl/igdb/games?limit=$limit');

    //Trying to fix game screenshot error
    print('IGDB FETCH -> $uri');

    final resp = await http.get(uri).timeout(const Duration(seconds: 200));
    if (resp.statusCode != 200) {
      throw Exception('Backend error ${resp.statusCode}: ${resp.body}');
    }

    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.map((e) {
      final m = e as Map<String, dynamic>;
      return GameCard(
        id: (m['id']).toString(),
        title: (m['title'] ?? 'Unknown') as String,
        genre: (m['genre'] ?? 'Unknown') as String,
        imageUrl: (m['imageUrl'] as String?) ?? '',
      );
    }).toList();
  }
}
