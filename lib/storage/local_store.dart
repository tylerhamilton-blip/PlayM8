import 'dart:convert';
import 'package:hive/hive.dart';
import '../types/models.dart';

class LocalStore {
  static late Box _box;

  static Future<void> init() async {
    _box = await Hive.openBox('playm8');
  }

  // --- Mock auth ---
  static Future<void> setLoggedIn(bool v) async => _box.put('logged_in', v);

  static Future<bool> isLoggedIn() async =>
      (_box.get('logged_in') as bool?) ?? false;

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

  // --- Utility reset for testing ---
  static Future<void> resetAll() async {
    await _box.delete('history');
    await _box.delete('genres');
    await _box.put('logged_in', false);
  }
}
