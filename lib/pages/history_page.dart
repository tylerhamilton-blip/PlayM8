import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:play_m8/pages/GamePage.dart';
import '../storage/local_store.dart';
import '../types/models.dart';
import 'package:http/http.dart' as http;

//New
final _baseUrl= 'http://10.0.2.2:8000';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = true;
  String? _error;

  List<Map<String, dynamic>> _steamGames = [];
  List<HistoryItem> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final steamRaw = await LocalStore.loadSteamGames(); // List<dynamic>
      final history = await LocalStore.loadHistory(); // List<HistoryItem>

      // Convert steam list items into Map<String, dynamic>
      final steam = <Map<String, dynamic>>[];
      for (final item in steamRaw) {
        if (item is Map) {
          steam.add(item.cast<String, dynamic>());
        }
      }

      // Sort by playtime_forever DESC (most played first)
      steam.sort((a, b) {
        final ap = (a['playtime_forever'] as int?) ?? 0;
        final bp = (b['playtime_forever'] as int?) ?? 0;
        return bp.compareTo(ap);
      });

      if (!mounted) return;
      setState(() {
        _steamGames = steam;
        _history = history.reversed.toList(); // newest first
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('History')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load history.'),
                const SizedBox(height: 10),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    final showSteam = _steamGames.isNotEmpty;
    final showHistory = _history.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: (!showSteam && !showHistory)
          ? const Center(child: Text('Nothing here yet. Swipe some games!'))
          : CustomScrollView(
        slivers: [
          if (showSteam) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
                child: Text(
                  'Most Played on Steam',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final g = _steamGames[index];
                    return SteamGameTile(game: g);
                  },
                  childCount: _steamGames.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 18)),
          ],
          if (showHistory) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Text(
                  'Swiped Games',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final item = _history[index];
                    return SwipedGameTile(item: item);
                  },
                  childCount: _history.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

//New
Future<String> getVideo(String gameName) async{
  final url= Uri.parse('$_baseUrl/steam/vids?gameName=$gameName');
  final response= await http.get(url).timeout(const Duration(seconds: 25));
  if (response.statusCode != 200) {
    throw Exception('Steam login_url failed: ${response.body}');
  }
  final data= jsonDecode(response.body) as Map <String, dynamic>;
  if (data.containsKey("HLS")) {
    print(data["HLS"]);
    return data["HLS"] as String;
  }
  else if (data.containsKey("MP4")){
    print(data["MP4"]);
    return data["MP4"] as String;
  }
  else{
    print(data["Error"]);
    return data["Error"] as String;
  }
}

class SteamGameTile extends StatelessWidget {
  final Map<String, dynamic> game;
  const SteamGameTile({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final name = (game['name'] ?? 'Unknown') as String;
    final header = (game['header_image'] ?? '') as String;
    final minutes = (game['playtime_forever'] as int?) ?? 0;
    final hours = (minutes / 60).toStringAsFixed(1);
    String link;//New
    
    //New 
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Material(
        child: InkWell(
          onTap: () async {
            link=await getVideo(name);
            if(link.startsWith("https")) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => Gamepage(videoUrl: link,gameName: name)),
              );
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (header.isNotEmpty)
                Image.network(
                  header,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black12),
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                )
              else
                const DecoratedBox(
                  decoration: BoxDecoration(color: Colors.black12),
                  child: Center(child: Icon(Icons.videogame_asset)),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: 70,
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
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$hours hrs played',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwipedGameTile extends StatelessWidget {
  final HistoryItem item;
  const SwipedGameTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final card = item.card;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if ((card.imageUrl ?? '').isNotEmpty)
            Image.network(
              card.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(color: Colors.black12),
                child: Center(child: Icon(Icons.broken_image)),
              ),
            )
          else
            const DecoratedBox(
              decoration: BoxDecoration(color: Colors.black12),
              child: Center(child: Icon(Icons.sports_esports)),
            ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 80,
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
                  card.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                _DecisionPill(decision: item.decision),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionPill extends StatelessWidget {
  final SwipeDecision decision;
  const _DecisionPill({required this.decision});

  @override
  Widget build(BuildContext context) {
    late final String text;
    late final Color color;

    switch (decision) {
      case SwipeDecision.like:
        text = 'Liked';
        color = Colors.green;
        break;
      case SwipeDecision.nope:
        text = 'Nope';
        color = Colors.red;
        break;
      case SwipeDecision.maybe:
        text = 'Maybe';
        color = Colors.amber;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
