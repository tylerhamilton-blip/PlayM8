import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../storage/local_store.dart';
import './home_page.dart';
import './sign_up.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  String? _error;

  static const String _baseUrl = 'http://10.0.2.2:8000';
  static const String _loginUrl = '$_baseUrl/login';

  // Sign up -> teammate’s flow
  Future<void> _mockSignUp() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    await Future<void>.delayed(const Duration(milliseconds: 150));
    await LocalStore.setLoggedIn(true);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignupPage()),
    );

    setState(() => _loading = false);
  }

  // Email login -> teammate’s backend + HomePage navigation
  Future<void> _mockSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final payload = <String, dynamic>{
        "email": _email.text.trim(),
        "password": _password.text,
        "username": "", // backend model includes it; safe to send empty
      };

      final response = await http
          .post(
            Uri.parse(_loginUrl),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        setState(() {
          _error = "Wrong password or email. Please try again.";
        });
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final username = (data["username"] ?? "").toString();

      await LocalStore.setLoggedIn(true);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(username: username)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Login failed: $e";
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  // ✅ Steam login -> deep link -> main.dart routes to /swipe
  Future<void> _steamLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Uri.parse('$_baseUrl/steam/login_url');
      final resp = await http.get(uri).timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        throw Exception('Backend ${resp.statusCode}: ${resp.body}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final url = (data['url'] ?? '').toString();

      if (url.isEmpty) {
        throw Exception('Backend did not return a login url.');
      }

      final steamUri = Uri.parse(url);

      final ok = await launchUrl(
        steamUri,
        mode: LaunchMode.externalApplication,
      );

      if (!ok) {
        throw Exception('Could not open Steam login URL.');
      }

      // ✅ DO NOT navigate here.
      // Steam callback deep-links into app -> main.dart handles it -> /swipe
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Steam login failed: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 14),

            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _loading ? null : _mockSignIn,
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : _mockSignUp,
                    child: const Text('Sign up'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loading ? null : _steamLogin,
                icon: const Icon(Icons.videogame_asset),
                label: const Text('Continue with Steam'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
