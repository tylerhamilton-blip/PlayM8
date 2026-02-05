import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/local_store.dart';

class GenreQuestionnairePage extends StatefulWidget {
  const GenreQuestionnairePage({super.key});

  @override
  State<GenreQuestionnairePage> createState() => _GenreQuestionnairePageState();
}

class _GenreQuestionnairePageState extends State<GenreQuestionnairePage> {
  // Replace later with real IGDB genres
  final _allGenres = const [
    'Action', 'Adventure', 'RPG', 'Shooter', 'Strategy',
    'Puzzle', 'Racing', 'Sports', 'Simulation', 'Horror', 'Indie'
  ];

  final Set<String> _selected = {};

  Future<void> _continue() async {
    await LocalStore.saveSelectedGenres(_selected.toList()..sort());
    if (!mounted) return;
    context.go('/swipe');
  }

  @override
  Widget build(BuildContext context) {
    final canContinue = _selected.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Pick genres')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tap bubbles to select genres:'),
            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _allGenres.map((g) {
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
            )
          ],
        ),
      ),
    );
  }
}
