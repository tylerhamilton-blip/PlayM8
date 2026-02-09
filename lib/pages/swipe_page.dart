import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';

import '../storage/local_store.dart';
import '../types/models.dart';
import '../services/igdb_service.dart';

class SwipePage extends StatefulWidget {
  const SwipePage({super.key});

  @override
  State<SwipePage> createState() => _SwipePageState();
}

class _SwipePageState extends State<SwipePage> {
  final CardSwiperController _controller = CardSwiperController();

  List<String> _genres = [];
  String _activeGenre = 'All';

  final Set<String> _swipedIds = {};
  SwipeGlow _glow = SwipeGlow.none;

  String? _flashText;
  IconData? _flashIcon;
  Color? _flashColor;
  Timer? _flashTimer;

  // IGDB-loaded cards
  List<GameCard> _allCards = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final selected = await LocalStore.loadSelectedGenres();
      final history = await LocalStore.loadHistory();
      final fetched = await IgdbService.fetchGames(limit: 40);

      setState(() {
        _genres = selected;
        _activeGenre = 'All';
        _swipedIds.addAll(history.map((h) => h.card.id));

        // NOTE: For now, genre is "Unknown" or whatever backend returns.
        // We’ll hook real genre-based filtering next.
        _allCards = fetched;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<GameCard> get _filteredCards {
    final base = (_activeGenre == 'All')
        ? _allCards
        : _allCards.where((c) => c.genre == _activeGenre).toList();

    return base.where((c) => !_swipedIds.contains(c.id)).toList();
  }

  Color? get _glowColor {
    switch (_glow) {
      case SwipeGlow.like:
        return Colors.green.withOpacity(0.15);
      case SwipeGlow.maybe:
        return Colors.yellow.withOpacity(0.15);
      case SwipeGlow.nope:
        return Colors.red.withOpacity(0.15);
      case SwipeGlow.none:
        return null;
    }
  }

  Future<void> _saveDecision(GameCard card, SwipeDecision decision) async {
    _swipedIds.add(card.id);
    await LocalStore.addHistory(card, decision);
  }

  void _flash({
    required String text,
    required IconData icon,
    required Color color,
  }) {
    _flashTimer?.cancel();
    setState(() {
      _flashText = text;
      _flashIcon = icon;
      _flashColor = color;
    });

    _flashTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      setState(() {
        _flashText = null;
        _flashIcon = null;
        _flashColor = null;
      });
    });
  }

  Future<void> _handleSwipe(GameCard card, CardSwiperDirection direction) async {
    if (direction == CardSwiperDirection.right) {
      setState(() => _glow = SwipeGlow.like);
      _flash(text: "LIKE", icon: Icons.thumb_up, color: Colors.green);
      await _saveDecision(card, SwipeDecision.like);
    } else if (direction == CardSwiperDirection.left) {
      setState(() => _glow = SwipeGlow.nope);
      _flash(text: "NOPE", icon: Icons.thumb_down, color: Colors.red);
      await _saveDecision(card, SwipeDecision.nope);
    } else if (direction == CardSwiperDirection.top) {
      setState(() => _glow = SwipeGlow.maybe);
      _flash(text: "MAYBE", icon: Icons.help, color: Colors.amber);
      await _saveDecision(card, SwipeDecision.maybe);
    } else {
      setState(() => _glow = SwipeGlow.none);
    }

    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (mounted) setState(() => _glow = SwipeGlow.none);
  }

  Future<void> _resetEverything() async {
    await LocalStore.resetAll();
    if (!mounted) return;
    context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final cards = _filteredCards;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) => setState(() => _activeGenre = value),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'All', child: Text('All')),
            ..._genres.map((g) => PopupMenuItem(value: g, child: Text(g))),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.grid_view),
          ),
          IconButton(
            onPressed: _resetEverything,
            icon: const Icon(Icons.logout),
            tooltip: 'Reset (mock logout)',
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _glowColor,
        child: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Could not load IGDB games.'),
                      const SizedBox(height: 10),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 14),
                      FilledButton(
                        onPressed: () {
                          setState(() {
                            _loading = true;
                            _error = null;
                          });
                          _bootstrap();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.all(16),
                child: cards.isEmpty
                    ? const Center(
                  child: Text(
                    "No more games to show.\nTry changing genres!",
                    textAlign: TextAlign.center,
                  ),
                )
                    : CardSwiper(
                  controller: _controller,
                  cardsCount: cards.length,
                  onSwipe: (previousIndex, currentIndex, direction) async {
                    final card = cards[previousIndex];
                    await _handleSwipe(card, direction);
                    return true;
                  },
                  // ✅ signature for your version:
                  cardBuilder: (context, index) {
                    final c = cards[index];
                    return GameCoverCard(card: c);
                  },
                ),
              ),

            if (_flashText != null && _flashIcon != null && _flashColor != null)
              Positioned(
                top: 26,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _flashColor!.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _flashColor!, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_flashIcon!, color: _flashColor!),
                        const SizedBox(width: 8),
                        Text(
                          _flashText!,
                          style: TextStyle(
                            color: _flashColor!,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class GameCoverCard extends StatelessWidget {
  final GameCard card;
  const GameCoverCard({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (card.imageUrl != null && card.imageUrl!.isNotEmpty)
            Image.network(
              card.imageUrl!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stack) {
                return const Center(child: Icon(Icons.broken_image, size: 48));
              },
            )
          else
            const Center(child: Icon(Icons.sports_esports, size: 64)),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 160,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.20)),
                  ),
                  child: Text(
                    card.genre,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
