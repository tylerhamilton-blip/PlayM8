import 'dart:convert';
import 'package:hive/hive.dart';
import '../types/models.dart';

class LocalStore {
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('playm8');
  }

  //--- Mock auth ---
  static Future<void> setLoggedIn(bool v) async => _box.put('logged_in', v);

  static Future<bool> isLoggedIn() async =>
      (_box.get('logged_in') as bool?) ?? false;

  // --- Steam (used for Steam login + recommendations) ---
  static Future<void> saveSteamId(String steamid) async {
    await _box.put('steam_id', steamid);
  }

  static Future<String?> loadSteamId() async {
    final v = _box.get('steam_id');
    return v is String ? v : null;
  }

  static Future<void> clearSteamId() async {
    await _box.delete('steam_id');
  }

  //Steam games list (raw JSON list so no Hive adapters needed)
  static Future<void> saveSteamGames(List<dynamic> games) async {
    await _box.put('steam_games', jsonEncode(games));
  }

  static Future<List<dynamic>> loadSteamGames() async {
    final raw = _box.get('steam_games');
    if (raw is String && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded;
    }
    return <dynamic>[];
  }

  static Future<void> clearSteamGames() async {
    await _box.delete('steam_games');
  }

  // --- Genres ---
  static Future<void> saveSelectedGenres(List<String> genres) async {
    await _box.put('genres', genres);
  }

  static Future<List<String>> loadSelectedGenres() async {
    final v = _box.get('genres');
    if (v is List) return v.cast<String>();
    return <String>[];
  }

  static Future<bool> hasSelectedGenres() async {
    final genres = await loadSelectedGenres();
    return genres.isNotEmpty;
  }

  //Console/platform filter persistence
  static Future<void> saveSelectedPlatforms(List<String> platforms) async {
    await _box.put('selected_platforms', platforms);
  }


  static Future<List<String>> loadSelectedPlatforms() async {
    final v = _box.get('selected_platforms');
    if (v is List) return v.cast<String>();
    return <String>[];
  }

  static Future<void> clearSelectedPlatforms() async {
    await _box.delete('selected_platforms');
  }

  // --- Swipe history ---
  static Future<void> addHistory(GameCard card, SwipeDecision decision) async {
    final List<String> raw = (_box.get('history') as List?)?.cast<String>() ?? [];
    final item = HistoryItem(card: card, decision: decision, at: DateTime.now());
    raw.add(jsonEncode(item.toJson()));
    await _box.put('history', raw);
  }


  static Future<List<HistoryItem>> loadHistory() async {
    final List<String> raw = (_box.get('history') as List?)?.cast<String>() ?? [];
    return raw.map((s) => HistoryItem.fromJson(jsonDecode(s))).toList();
  }

  // --- Used for storing the username of a user ---
  static Future<void> saveUsername(String username) async {
    await _box.put('username', username);
  }

  static Future<String?> loadUsername() async {
    final v = _box.get('username');
    return v is String ? v : null;
  }

  // --- Used for storing the userID of a user ---
  static Future<void> saveUserID(String userid) async {
    await _box.put('userid', userid);
  }

  static Future<String?> loadUserID() async {
    final v = _box.get('userid');
    return v is String ? v : null;
  }

  // --- Utility reset for testing ---
  static Future<void> resetAll() async {
    await _box.delete('history');
    await _box.delete('genres');
    await _box.delete('steam_id');
    await _box.delete('steam_games');
    await _box.delete('selected_platforms');
    await _box.delete('userid');
    await _box.put('logged_in', false);
  }
}
