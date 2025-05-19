import 'package:flutter/material.dart';

class MainScaffold extends StatelessWidget {
  final int selectedIndex;
  final Widget body;

  const MainScaffold({
    super.key,
    required this.selectedIndex,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FoundIt Feed"),
        automaticallyImplyLeading: false,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacementNamed(context, '/home');
          else if (index == 1) Navigator.pushReplacementNamed(context, '/profile');
          else if (index == 2) Navigator.pushReplacementNamed(context, '/channels');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        ],
      ),
    );
  }
}
