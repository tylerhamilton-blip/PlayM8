import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../storage/local_store.dart';
import 'package:http/http.dart' as http;
import './genre_questionnaire_page.dart';
import '../pages/auth_page.dart';
import './history_page.dart';
import './swipe_page.dart';
import 'package:play_m8/storage/local_store.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{
  //Add a get method here to implement custom user profiles later
  String? username;
  bool _loading = false;

  //Used to initialized the variables/ attributes above(userName)
  @override
  void initState()
  {
    super.initState();
    _loadUsername();//Using the username from the constructor to initialize
  }
  //Loads username into the page
  Future<void> _loadUsername() async{
    final userName= await LocalStore.loadUsername();
    setState((){
      username=userName!;
    }
    );
  }

  Future<void> browseGenre() async {
    setState(() {
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    // Navigate to genres page(very important section for page switching)
    context.push('/genres');
    setState(() {
      _loading = false;
    });
  }


  Future<void> history() async {
    setState(() {
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    // Navigate to genres page(very important section for page switching)
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const HistoryPage()),

    );
    setState(() {
      _loading = false;
    });
  }
  Future<void> gameBrowse() async {
    setState(() {
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    // Navigate to genres page(very important section for page switching)
    context.push('/swipe');
    setState(() {
      _loading = false;
    });
  }

  Future<void> authPage() async {
    setState(() {
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await LocalStore.resetAll();

    if (!mounted) return;
    // Navigate to genres page(very important section for page switching)
    context.go('/auth');
    setState(() {
      _loading = false;
    });
  }

  //Steam login -> deep link -> main.dart routes to /swipe
  Future<void> steamLogin() async {
    setState(() {
      _loading = true;
      String? _error=null;
    });

    try {
      final uri = Uri.parse('http://10.0.2.2:8000/steam/login_url');
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

      //Steam callback deep-links into app -> main.dart handles it -> /swipe
    } catch (e) {
      if (!mounted) return;
      setState(() {
        var _error = 'Steam login failed: $e';
      });
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Align(
          alignment: Alignment(0.35, 0.9),
          child: Text("PlayM8 Home",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.logout,
                color: Colors.white),
            onPressed: () => authPage(),
          ),
        ],
      ),

      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  browseGenre();
                },
                icon: Icon(Icons.category,color: Colors.white),
                label: Text("Hello $username lets browse!!!"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            SizedBox(height: 25),


            // Quick Actions
            Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 10),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  buildCard(Icons.category, "Genres", context,browseGenre),
                  buildCard(Icons.person, "Browse", context,gameBrowse),
                  buildCard(Icons.menu_book_rounded, "Library", context,history),
                  buildCard(Icons.gamepad, "Link Account", context,steamLogin),

                ],
              ),
            ),
          ],
        ),
        color: Colors.white,
      ),
    );
  }
//Function for easily making cards
  Widget buildCard(IconData icon, String title, BuildContext context, Future<void> Function () navigate) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.redAccent,
      child: InkWell(
        onTap: navigate,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(title,
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 30
                )),
          ],

        ),
      ),
    );
  }
}
