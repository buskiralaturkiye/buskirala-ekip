import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'login_screen.dart';
import 'jobs_screen.dart';
import 'vehicles_screen.dart';
import 'colleagues_screen.dart';
import 'score_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const JobsScreen(),
    const VehiclesScreen(),
    const ColleaguesScreen(),
    const ScoreScreen(),
  ];

  Future<void> _signOut(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    navigator.pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    messenger.showSnackBar(const SnackBar(content: Text('Oturum kapatıldı')));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Image.asset(
          'assets/buskirala-logo.png',
          height: 36,
          fit: BoxFit.contain,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFDDDEE0),
            height: 1,
          ),
        ),
      ),
      body: _selectedIndex == 4 ? _buildProfile(user) : _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        backgroundColor: Colors.white,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'İşler'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_bus), label: 'Araçlarım'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Ekip'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Puanım'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildProfile(User? user) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: user?.photoURL != null
                  ? NetworkImage(user!.photoURL!)
                  : null,
              child: user?.photoURL == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 20),
            Text(
              user?.displayName ?? "Kullanıcı",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              user?.email ?? "",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _signOut(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('ÇIKIŞ YAP',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}