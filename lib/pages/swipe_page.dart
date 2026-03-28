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
  List<String> _genres = [];
  String _activeGenre = 'All';

  // ✅ platform filter state
  List<String> _allPlatforms = []; // from IGDB
  Set<String> _selectedPlatforms = {}; // user’s selection

  final Set<String> _swipedIds = {};
  SwipeGlow _glow = SwipeGlow.none;

  // drag tracking for progressive tint
  Offset? _dragStart;
  double _glowStrength = 0.0; // 0..1

  String? _flashText;
  IconData? _flashIcon;
  Color? _flashColor;
  Timer? _flashTimer;

  // IGDB-loaded cards (already filtered by genre (and optionally platforms) SERVER-SIDE)
  List<GameCard> _allCards = [];
  bool _loading = true; // ✅ only for initial load / full error screen
  bool _refreshing = false; // ✅ for genre/console changes (overlay, does NOT unmount swiper)
  String? _error;

  // ✅ NEW: show Steam import popup only once per page instance
  bool _didShowSteamImportDialog = false;

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

  // ✅ NEW: shows popup if we arrived from Steam link with extra data
  void _maybeShowSteamImportDialog() {
    if (_didShowSteamImportDialog) return;

    final extra = GoRouterState.of(context).extra;
    if (extra is! Map) return;

    final steamLinked = extra['steamLinked'] == true;
    if (!steamLinked) return;

    final imported = extra['importedGenres'];
    final importedGenres = (imported is List)
        ? imported.map((e) => e.toString()).where((s) => s.trim().isNotEmpty).toList()
        : <String>[];

    _didShowSteamImportDialog = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) {
          return AlertDialog(
            title: const Text('Steam linked ✅'),
            content: SizedBox(
              width: double.maxFinite,
              child: importedGenres.isEmpty
                  ? const Text(
                'Linking was successful, but no genres/themes were imported yet.',
              )
                  : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Linking was successful! Imported genres/themes:',
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: importedGenres
                        .map(
                          (g) => Chip(
                        label: Text(g),
                      ),
                    )
                        .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _bootstrap() async {
    try {
      final selectedGenres = await LocalStore.loadSelectedGenres();
      final history = await LocalStore.loadHistory();

      // ✅ load saved platform selection
      final savedPlatforms = await LocalStore.loadSelectedPlatforms();

      // ✅ fetch platforms list for the selector UI
      final platforms = await IgdbService.fetchPlatforms(limit: 250);

      // ✅ pick a starting genre:
      // If user selected genres, default to first one; otherwise "All"
      final startGenre = selectedGenres.isNotEmpty ? selectedGenres.first : 'All';

      if (!mounted) return;
      setState(() {
        _genres = selectedGenres;
        _activeGenre = startGenre;
        _swipedIds.addAll(history.map((h) => h.card.id));

        _allPlatforms = platforms;
        _selectedPlatforms = savedPlatforms.toSet();

        _loading = false; // we’ll show refreshing overlay while fetching first batch
        _refreshing = true;
        _error = null;
      });

      await _refetchGames(); // ✅ initial fetch uses genre + consoles
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = e.toString();
      });
    }
  }

  // ✅ Always fetch from backend by GENRE (and optional platforms)
  Future<void> _refetchGames() async {
    try {
      final fetched = await IgdbService.fetchGames(
        limit: 40,
        genre: _activeGenre, // ✅ primary filter
        platforms: _selectedPlatforms.toList(), // ✅ optional console filter
      );

      if (!mounted) return;
      setState(() {
        _allCards = fetched;
        _refreshing = false;
        _error = null;

        // reset glow state
        _glow = SwipeGlow.none;
        _glowStrength = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _refreshing = false;
        _error = e.toString();
      });
    }
  }

  // ✅ Now filtering is ONLY: not swiped (genre+platform already done server-side)
  List<GameCard> get _filteredCards {
    return _allCards.where((c) => !_swipedIds.contains(c.id)).toList();
  }

  Color? get _glowColor {
    if (_glow == SwipeGlow.none || _glowStrength <= 0) return null;

    final maxOpacity = 0.35;
    final o = (maxOpacity * _glowStrength).clamp(0.0, 0.40);

    switch (_glow) {
      case SwipeGlow.like:
        return Colors.green.withOpacity(o);
      case SwipeGlow.maybe:
        return Colors.yellow.withOpacity(o);
      case SwipeGlow.nope:
        return Colors.red.withOpacity(o);
      case SwipeGlow.none:
        return null;
    }
  }

  void _onPointerDown(PointerDownEvent e) {
    _dragStart = e.position;
    if (!mounted) return;
    setState(() {
      _glow = SwipeGlow.none;
      _glowStrength = 0;
    });
  }

  void _onPointerMove(PointerMoveEvent e) {
    final start = _dragStart;
    if (start == null || !mounted) return;

    final delta = e.position - start;
    final dx = delta.dx;
    final dy = delta.dy;

    final ax = dx.abs();
    final ay = dy.abs();

    SwipeGlow nextGlow = SwipeGlow.none;

    if (ax > ay && ax > 2) {
      nextGlow = dx > 0 ? SwipeGlow.like : SwipeGlow.nope;
    } else if (ay > ax && ay > 2) {
      nextGlow = dy < 0 ? SwipeGlow.maybe : SwipeGlow.none;
    }

    final dist = ax > ay ? ax : ay;
    final strength = (dist / 180.0).clamp(0.0, 1.0);

    setState(() {
      _glow = nextGlow;
      _glowStrength = strength;
    });
  }

  void _onPointerEnd(PointerEvent e) {
    _dragStart = null;
    if (!mounted) return;
    setState(() {
      _glow = SwipeGlow.none;
      _glowStrength = 0;
    });
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
    if (!mounted) return;

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
    if (!mounted) return;

    if (direction == CardSwiperDirection.right) {
      setState(() {
        _glow = SwipeGlow.like;
        _glowStrength = 1.0;
      });
      _flash(text: "LIKE", icon: Icons.thumb_up, color: Colors.green);
      await _saveDecision(card, SwipeDecision.like);
    } else if (direction == CardSwiperDirection.left) {
      setState(() {
        _glow = SwipeGlow.nope;
        _glowStrength = 1.0;
      });
      _flash(text: "NOPE", icon: Icons.thumb_down, color: Colors.red);
      await _saveDecision(card, SwipeDecision.nope);
    } else if (direction == CardSwiperDirection.top) {
      setState(() {
        _glow = SwipeGlow.maybe;
        _glowStrength = 1.0;
      });
      _flash(text: "MAYBE", icon: Icons.help, color: Colors.amber);
      await _saveDecision(card, SwipeDecision.maybe);
    } else {
      setState(() {
        _glow = SwipeGlow.none;
        _glowStrength = 0.0;
      });
    }

    await Future<void>.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    setState(() {
      _glow = SwipeGlow.none;
      _glowStrength = 0.0;
    });
  }

  Future<void> _resetEverything() async {
    await LocalStore.resetAll();
    if (!mounted) return;
    context.go('/auth');
  }

  // ✅ Platform selector dialog (refreshes games from backend)
  Future<void> _openPlatformFilter() async {
    if (_allPlatforms.isEmpty) {
      try {
        final platforms = await IgdbService.fetchPlatforms(limit: 250);
        if (!mounted) return;
        setState(() => _allPlatforms = platforms);
      } catch (_) {}
    }

    if (!mounted) return;
    final chosen = await showDialog<Set<String>>(
      context: context,
      builder: (_) => _PlatformPickerDialog(
        allPlatforms: _allPlatforms,
        initiallySelected: _selectedPlatforms,
      ),
    );

    if (chosen == null || !mounted) return;

    setState(() {
      _error = null;
      _selectedPlatforms = chosen;
      _refreshing = true; // overlay spinner, swiper stays mounted
    });

    await LocalStore.saveSelectedPlatforms(chosen.toList());

    // ✅ refetch using current genre + new platforms
    await _refetchGames();
  }

  // ✅ When genre changes, refetch from backend by genre (and current consoles)
  Future<void> _setGenreAndRefetch(String value) async {
    if (!mounted) return;
    setState(() {
      _activeGenre = value;
      _refreshing = true;
      _error = null;
    });
    await _refetchGames();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ NEW: show Steam success popup if needed
    _maybeShowSteamImportDialog();

    final cards = _filteredCards;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        leading: PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list),
          onSelected: (value) => _setGenreAndRefetch(value),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'All', child: Text('All')),
            ..._genres.map((g) => PopupMenuItem(value: g, child: Text(g))),
          ],
        ),
        actions: [
          // 🎮 platform filter button + badge
          Stack(
            children: [
              IconButton(
                onPressed: _openPlatformFilter,
                icon: const Icon(Icons.sports_esports),
                tooltip: 'Filter by console',
              ),
              if (_selectedPlatforms.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_selectedPlatforms.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
        duration: const Duration(milliseconds: 120),
        color: _glowColor,
        child: Stack(
          children: [
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null && _allCards.isEmpty)
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
                          if (!mounted) return;
                          setState(() {
                            _error = null;
                            _refreshing = true;
                          });
                          _refetchGames();
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
                    ? Center(
                  child: Text(
                    _selectedPlatforms.isEmpty
                        ? "No games to show for this genre.\nTry a different genre!"
                        : "No games match your genre + console filter.\nTap 🎮 to change consoles.",
                    textAlign: TextAlign.center,
                  ),
                )
                    : Listener(
                  onPointerDown: _onPointerDown,
                  onPointerMove: _onPointerMove,
                  onPointerUp: _onPointerEnd,
                  onPointerCancel: _onPointerEnd,
                  child: CardSwiper(
                    // ✅ NO external controller -> avoids disposed-controller crash
                    cardsCount: cards.length,
                    onSwipe: (previousIndex, currentIndex, direction) async {
                      if (!mounted) return false;
                      if (previousIndex < 0 || previousIndex >= cards.length) {
                        return false;
                      }
                      final card = cards[previousIndex];
                      await _handleSwipe(card, direction);
                      return mounted;
                    },
                    cardBuilder: (context, index) {
                      final c = cards[index];
                      return GameCoverCard(card: c);
                    },
                  ),
                ),
              ),

            // ✅ flash
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

            // ✅ overlay spinner while switching genre/consoles (CardSwiper stays mounted)
            if (_refreshing)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: CircularProgressIndicator()),
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
    final platforms = card.platforms;

    return Card(
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((card.imageUrl ?? '').isNotEmpty)
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
              height: 210,
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
                const SizedBox(height: 8),
                _Bubble(text: card.genre),
                const SizedBox(height: 10),
                if (platforms.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: platforms.take(6).map((p) => _Bubble(text: p)).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  const _Bubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.55),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ✅ Dialog widget (fixed height list, no Expanded)
class _PlatformPickerDialog extends StatefulWidget {
  final List<String> allPlatforms;
  final Set<String> initiallySelected;

  const _PlatformPickerDialog({
    required this.allPlatforms,
    required this.initiallySelected,
  });

  @override
  State<_PlatformPickerDialog> createState() => _PlatformPickerDialogState();
}

class _PlatformPickerDialogState extends State<_PlatformPickerDialog> {
  late Set<String> _tempSelected;
  String _q = "";

  @override
  void initState() {
    super.initState();
    _tempSelected = {...widget.initiallySelected};
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allPlatforms.where((p) {
      if (_q.trim().isEmpty) return true;
      return p.toLowerCase().contains(_q.trim().toLowerCase());
    }).toList();

    return AlertDialog(
      title: const Text('Select consoles'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search platforms (IGDB)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => _q = v),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 320,
              child: filtered.isEmpty
                  ? const Center(child: Text('No matches'))
                  : ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final name = filtered[i];
                  final checked = _tempSelected.contains(name);

                  return CheckboxListTile(
                    value: checked,
                    title: Text(name),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _tempSelected.add(name);
                        } else {
                          _tempSelected.remove(name);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() => _tempSelected.clear()),
          child: const Text('Clear'),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop<Set<String>>(context, _tempSelected),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
