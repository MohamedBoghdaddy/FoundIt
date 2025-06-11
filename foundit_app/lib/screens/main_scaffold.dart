import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Adjust path if needed

class MainScaffold extends StatelessWidget {
  final int selectedIndex;
  final Widget body;

  const MainScaffold({
    super.key,
    required this.selectedIndex,
    required this.body,
  });

  void _handleLogout(BuildContext context) async {
    await AuthService().logoutUser();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FoundIt Feed"),
        automaticallyImplyLeading: false,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/channels');
              break;
            case 3:
              _handleLogout(context);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}
