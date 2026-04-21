import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/local_store.dart';
import './swipe_page.dart';

class GenreQuestionnairePage extends StatefulWidget {
  const GenreQuestionnairePage({super.key});

  @override
  State<GenreQuestionnairePage> createState() => _GenreQuestionnairePageState();
}

class _GenreQuestionnairePageState extends State<GenreQuestionnairePage> {
  // NOTE:
  // These are "categories" (some are IGDB Genres, some are IGDB Themes).
  // Example: Horror is a Theme on IGDB, not a Genre.
  //
  // You can replace this later by fetching real genres/themes from your backend.
  final _allCategories = const [
    'Action',
    'Adventure',
    'RPG',
    'Shooter',
    'Strategy',
    'Puzzle',
    'Racing',
    'Sports',
    'Simulation',
    'Horror', // Theme on IGDB
    'Indie',  // Often shows up as Theme / tag in some datasets
  ];

  final Set<String> _selected = {};

  Future<void> _continue() async {
    // Keep using the same storage method/key so the rest of your app stays compatible.
    await LocalStore.saveSelectedGenres(_selected.toList()..sort());
    if (!mounted) return;
      context.push('/swipe');
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick categories')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tap bubbles to select categories:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Some choices are IGDB themes (e.g., Horror).',
              style: TextStyle(color: Colors.black.withOpacity(0.60)),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allCategories.map((g) {
                final selected = _selected.contains(g);
                return InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() {
                    if (selected) {
                      _selected.remove(g);
                    } else {
                      _selected.add(g);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(),
                      color: selected ? Colors.blue.withOpacity(0.15) : null,
                    ),
                    child: Text(g),
                  ),
                );
              }).toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canContinue ? _continue : null,
                child: Text(canContinue ? 'Continue' : 'Pick at least one'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
