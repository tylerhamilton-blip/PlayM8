enum SwipeDecision { like, nope, maybe }
enum SwipeGlow { none, like, nope, maybe }

class GameCard {
  final String id;
  final String title;
  final String? imageUrl;
  final String genre;

  //NEW: platforms / consoles from IGDB
  final List<String> platforms;

  GameCard({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.genre,
    List<String>? platforms,
  }) : platforms = platforms ?? const [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'genre': genre,
    'platforms': platforms,
  };

  static GameCard fromJson(Map<String, dynamic> json) => GameCard(
    id: (json['id']).toString(),
    title: (json['title'] ?? 'Unknown') as String,
    imageUrl: json['imageUrl'] as String?,
    genre: (json['genre'] ?? 'Unknown') as String,
    platforms: (json['platforms'] as List?)
        ?.map((e) => e.toString())
        .toList() ??
        const [],
  );
}

class HistoryItem {
  final GameCard card;
  final SwipeDecision decision;
  final DateTime at;

  HistoryItem({required this.card, required this.decision, required this.at});

  Map<String, dynamic> toJson() => {
    'card': card.toJson(),
    'decision': decision.name,
    'at': at.toIso8601String(),
  };

  static HistoryItem fromJson(Map<String, dynamic> json) => HistoryItem(
    card: GameCard.fromJson(Map<String, dynamic>.from(json['card'])),
    decision: SwipeDecision.values.byName(json['decision'] as String),
    at: DateTime.parse(json['at'] as String),
  );
}
