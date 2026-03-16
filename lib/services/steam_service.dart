import 'dart:convert';
import 'package:http/http.dart' as http;

class SteamService {
  // Android emulator -> host machine localhost is 10.0.2.2
  static const String _baseUrl = 'http://10.0.2.2:8000';

  static Future<String> getLoginUrl() async {
    final uri = Uri.parse('$_baseUrl/steam/login_url');
    final resp = await http.get(uri).timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) {
      throw Exception('Steam login_url failed: ${resp.body}');
    }
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['url'] as String;
  }

  static Future<Map<String, dynamic>> fetchOwnedGames(String steamid) async {
    final uri = Uri.parse('$_baseUrl/steam/owned_games?steamid=$steamid');
    final resp = await http.get(uri).timeout(const Duration(seconds: 25));
    if (resp.statusCode != 200) {
      throw Exception('Steam owned_games failed: ${resp.body}');
    }
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }
}