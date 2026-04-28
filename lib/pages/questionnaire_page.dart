import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../storage/local_store.dart';

/// FULL QUESTIONNAIRE PAGE!!!!
/// - Saves locally (Hive)
/// - Sends to backend
/// - Navigates to /swipe after completion

class QuestionnairePage extends StatefulWidget {
  const QuestionnairePage({super.key});

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
 // ================= STATE =================

  int page = 0;
  String username = "";
  String playMode = "";
  String worldType = "";
  String difficulty = "";
  String sessionLength = "";
  String competitive = "";
  String grinding = "";
  String releasePreference = "";
  String budget = "";
  String hasSteam = "";
  String otherPlatformText = "";

  double storyImportance = 3;
  double replayability = 3;

  Set<String> selectedPlatforms = {};
  Set<String> selectedGenres = {};
  Set<String> selectedArtStyles = {};
  Set<String> selectedTones = {};
  Set<String> gameplayElements = {};

  final platforms = ["PC","Playstation","Xbox","Nintendo Switch","Mobile","Other"];

  final genres = [
    "Action","Adventure","RPG","Strategy","Simulation",
    "Shooter","Platformer","Puzzle","Horror","Survival",
    "Roguelike","Indie","Fighting","Sports","Racing",
    "Sandbox","MMO","Visual Novel","Card","Party"
  ];

  // backend base, same as main.dart
  final String baseUrl = 'http://${LocalStore.demo()}:8000';

  // ================= SUBMIT =================

  Future<void> submit() async {

    final userId = await LocalStore.loadUserID();

    final data = {
      "user_id": userId,
      "birthday": birthday,
      "username": username,
      "platforms": selectedPlatforms.toList(),
      "other_platform": otherPlatformText,
      "genres": selectedGenres.toList(),
      "play_mode": playMode,
      "story_importance": storyImportance.toInt(),
      "world_type": worldType,
      "difficulty": difficulty,
      "session_length": sessionLength,
      "competitive": competitive,
      "grinding": grinding,
      "art_styles": selectedArtStyles.toList(),
      "tones": selectedTones.toList(),
      "gameplay_elements": gameplayElements.toList(),
      "release_preference": releasePreference,
      "replayability": replayability.toInt(),
      "budget": budget,
      "has_steam": hasSteam
    };

    // Save locally (Hive)
    await LocalStore.saveQuestionnaire(data);

    // Send to backend
    try {
      await http.post(
        Uri.parse('$baseUrl/questionnaire'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
    } catch (_) {
      // fail silently (offline safe)
    }

    // Navigate forward
    if (mounted) context.go('/swipe');
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Questionnaire")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // Progress bar
            LinearProgressIndicator(
              value: (page + 1) / 18,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),

            const SizedBox(height: 12),

            Text("Question ${page + 1} of 18",
                style: theme.textTheme.labelMedium),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(child: buildPage()),
            ),

            Row(
              children: [
                if (page > 0)
                  ElevatedButton(
                    onPressed: () => setState(() => page--),
                    child: const Text("Back"),
                  ),

                const Spacer(),

                ElevatedButton(
                  onPressed: () {
                    if (page < 17) {
                      setState(() => page++);
                    } else {
                      submit();
                    }
                  },
                  child: Text(page == 17 ? "Finish" : "Next"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // ================= QUESTIONS =================

  Widget buildPage() {

    switch (page) {

      // 0 Birthday
      case 0:
        return TextField(
          decoration: const InputDecoration(labelText: "MM/DD/YYYY"),
          onChanged: (input) {
            final digits = input.replaceAll(RegExp(r'[^0-9]'), '').substring(0, input.length.clamp(0, 8));
            String formatted = "";
            for (int i = 0; i < digits.length; i++) {
              formatted += digits[i];
              if (i == 1 || i == 3) formatted += "/";
            }
            setState(() => birthday = formatted);
          },
        );

      // 1 Username
      case 1:
        return TextField(
          decoration: const InputDecoration(labelText: "Username"),
          onChanged: (v) => username = v,
        );

      // 2 Platforms
      case 2:
        return Column(
          children: platforms.map((p) {
            return Column(
              children: [
                CheckboxListTile(
                  title: Text(p),
                  value: selectedPlatforms.contains(p),
                  onChanged: (_) {
                    setState(() {
                      selectedPlatforms.contains(p)
                          ? selectedPlatforms.remove(p)
                          : selectedPlatforms.add(p);
                    });
                  },
                ),
                if (p == "Other" && selectedPlatforms.contains("Other"))
                  TextField(
                    decoration: const InputDecoration(labelText: "Other platform"),
                    onChanged: (v) => otherPlatformText = v,
                  )
              ],
            );
          }).toList(),
        );

      // 3 Genres
      case 3:
        return Wrap(
          spacing: 8,
          children: genres.map((g) {
            final selected = selectedGenres.contains(g);
            return FilterChip(
              label: Text(g),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  selected
                      ? selectedGenres.remove(g)
                      : selectedGenres.add(g);
                });
              },
            );
          }).toList(),
        );

      // 4 Play mode
      case 4:
        return radio(["Single-player","Multiplayer","Co-op","No preference"],
            playMode, (v) => setState(() => playMode = v));

      // 5 Story
      case 5:
        return slider(storyImportance, (v) => setState(() => storyImportance = v));

      // 6 World
      case 6:
        return radio(["Open-world","Linear","Hybrid","No Preference"],
            worldType, (v) => setState(() => worldType = v));

      // 7 Difficulty
      case 7:
        return radio(["Casual","Moderate","Challenging","Extreme"],
            difficulty, (v) => setState(() => difficulty = v));

      // 8 Session
      case 8:
        return radio(["<30m","30-60m","1-2h","2h+"],
            sessionLength, (v) => setState(() => sessionLength = v));

      // 9 Competitive
      case 9:
        return radio(["Yes","Sometimes","No"],
            competitive, (v) => setState(() => competitive = v));

      // 10 Grinding
      case 10:
        return radio(["Yes","Neutral","No"],
            grinding, (v) => setState(() => grinding = v));

      // 11 Art styles
      case 11:
        return checkboxMulti([
          "Realistic","Stylized","Pixel Art","Anime",
          "Cartoon","Retro","Indie","No Preference"
        ], selectedArtStyles);

      // 12 Tone
      case 12:
        return checkboxMulti([
          "Dark","Light","Funny","Emotional","Horror","Epic","No Preference"
        ], selectedTones);

      // 13 Gameplay
      case 13:
        return checkboxMulti([
          "Customization","Skill trees","Loot","Crafting",
          "Exploration","Puzzles","Base building","Dialogue",
          "Romance","Roguelike","Strategy","Fast combat"
        ], gameplayElements);

      // 14 Release
      case 14:
        return radio(["New","Mix","Old","No Preference"],
            releasePreference, (v) => setState(() => releasePreference = v));

      // 15 Replay
      case 15:
        return slider(replayability, (v) => setState(() => replayability = v));

      // 16 Budget
      case 16:
        return radio(["Free","<5","<10","<20","<30","30-60","No limit"],
            budget, (v) => setState(() => budget = v));

      // 17 Steam
      case 17:
        return radio(["Yes","No"],
            hasSteam, (v) => setState(() => hasSteam = v));

      default:
        return const SizedBox();
    }
  }

  // ================= HELPERS =================

  Widget radio(List<String> options, String value, Function(String) onChanged) {
    return Column(
      children: options.map((o) {
        return RadioListTile(
          title: Text(o),
          value: o,
          groupValue: value,
          onChanged: (v) => onChanged(v!),
        );
      }).toList(),
    );
  }

  Widget slider(double val, Function(double) onChanged) {
    return Column(
      children: [
        Slider(value: val, min: 1, max: 5, divisions: 4, onChanged: onChanged),
        Text(val.toInt().toString())
      ],
    );
  }

  Widget checkboxMulti(List<String> options, Set<String> set) {
    return Column(
      children: options.map((o) {
        return CheckboxListTile(
          title: Text(o),
          value: set.contains(o),
          onChanged: (_) {
            setState(() {
              set.contains(o) ? set.remove(o) : set.add(o);
            });
          },
        );
      }).toList(),
    );
  }
}
