import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../storage/local_store.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Set this to true after you add: assets/animations/logo.json
  static const bool kUseLottie = false;

  @override
  void initState() {
    super.initState();
    _routeAfterDelay();
  }

  Future<void> _routeAfterDelay() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final loggedIn = await LocalStore.isLoggedIn();
    final hasGenres = await LocalStore.hasSelectedGenres();

    if (!mounted) return;

    if (!loggedIn) {
      context.go('/auth');
      return;
    }

    if (hasGenres) {
      context.go('/swipe');
    } else {
      context.go('/genres');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: kUseLottie
            ? Lottie.asset('assets/animations/logo.json', width: 220, repeat: true)
            : const FlutterLogo(size: 140),
      ),
    );
  }
}
