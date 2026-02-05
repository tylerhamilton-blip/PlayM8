import 'package:flutter/material.dart';
import '../storage/local_store.dart';
import '../types/models.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<HistoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await LocalStore.loadHistory();
    setState(() => _items = items.reversed.toList());
  }

  Color _badgeColor(SwipeDecision d) {
    switch (d) {
      case SwipeDecision.like:
        return Colors.green;
      case SwipeDecision.maybe:
        return Colors.amber;
      case SwipeDecision.nope:
        return Colors.red;
    }
  }

  String _badgeText(SwipeDecision d) {
    switch (d) {
      case SwipeDecision.like:
        return 'Liked';
      case SwipeDecision.maybe:
        return 'Maybe';
      case SwipeDecision.nope:
        return 'Nope';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: _items.isEmpty
          ? const Center(child: Text('No swipes yet.'))
          : Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemBuilder: (context, i) {
            final item = _items[i];
            final badgeColor = _badgeColor(item.decision);

            return Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (item.card.imageUrl != null)
                    Image.network(
                      item.card.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image),
                      ),
                    )
                  else
                    const Center(child: Icon(Icons.sports_esports, size: 48)),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 90,
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
                    left: 10,
                    right: 10,
                    bottom: 10,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.card.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: badgeColor, width: 1.5),
                            ),
                            child: Text(
                              _badgeText(item.decision),
                              style: TextStyle(
                                color: badgeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
