enum SwipeDecision { like, nope, maybe }
enum SwipeGlow { none, like, nope, maybe }

class GameCard {
  final String id;
  final String title;
  final String? imageUrl;
  final String genre;

  GameCard({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.genre,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'imageUrl': imageUrl,
    'genre': genre,
  };

  static GameCard fromJson(Map<String, dynamic> json) => GameCard(
    id: json['id'] as String,
    title: json['title'] as String,
    imageUrl: json['imageUrl'] as String?,
    genre: json['genre'] as String,
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
