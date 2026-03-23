import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/local_store.dart';
import 'package:http/http.dart' as http;
import './genre_questionnaire_page.dart';
import './auth_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{
  //Add a get method here to implement custom user profiles later
  late String userName;
  bool _loading = false;

  //Used to initialized the variables/ attributes above(userName)
  @override
  void initState()
  {
    super.initState();
    userName=widget.username;//Using the username from the constructor to initialize
  }

  Future<void> browseGenre() async {
    setState(() {
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    // Navigate to genres page(very important section for page switching)
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => const GenreQuestionnairePage()),
    );
    setState(() {
      _loading = false;
    });
    }
  Future<void> authPage() async {
    setState(() {
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;
    // Navigate to genres page(very important section for page switching)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) => const AuthPage()),
    );
    setState(() {
      _loading = false;
    });
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
              onPressed: () {
                  authPage();
              },
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
                  label: Text("Hello $userName lets browse!!!"),
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
                    buildCard(Icons.person, "Browse", context,browseGenre),
                    buildCard(Icons.menu_book_rounded, "Library", context,browseGenre),
                    buildCard(Icons.settings, "Settings", context,browseGenre),

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
