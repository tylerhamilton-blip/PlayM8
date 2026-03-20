import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/local_store.dart';
import 'package:http/http.dart' as http;
import './genre_questionnaire_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  const HomePage({Key? key, required this.username}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage>{
  //Add a get method here to implement custom user profiles later
  late String userName;

  //Used to initialized the variables/ attributes above(userName)
  @override
  void initState()
  {
    super.initState();
    userName=widget.username;//Using the username from the constructor to initialize
  }

  //Change anything in here but the heavily commented section below with navigator
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/login");
            },
          )
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👋 Greeting
            Text(
              "Hello, $userName 👋",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            //Adjust but main thing that works here
            //Brings you to the genres and leads you to discovery page
            //Adjust section how you like
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to genres page(very important section for page switching)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:(_) => const GenreQuestionnairePage()),
                    );//End of important section
                },
                icon: Icon(Icons.category),
                label: Text("Browse Genres"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  textStyle: TextStyle(fontSize: 16),
                ),
              ),
            ),

            SizedBox(height: 25),


            // 📦 Quick Actions
            Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 10),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  buildCard(Icons.category, "Genres", context),
                  buildCard(Icons.person, "Profile", context),
                  buildCard(Icons.shopping_cart, "Orders", context),
                  buildCard(Icons.settings, "Settings", context),
                ],
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.blue,
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, "/genres");
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: "Genres",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: "Account",
          ),
        ],
      ),
    );
  }

  Widget buildCard(IconData icon, String title, BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          if (title == "Genres") {
            Navigator.pushNamed(context, "/genres");
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            SizedBox(height: 10),
            Text(title),
          ],
        ),
      ),
    );
  }
}
