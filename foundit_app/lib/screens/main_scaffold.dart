import 'package:flutter/material.dart';

class MainScaffold extends StatelessWidget {
  final int selectedIndex;
  final Widget body;
  final BuildContext context;

  const MainScaffold({
    super.key,
    required this.selectedIndex,
    required this.body,
    required this.context,
  });

  @override
  Widget build(BuildContext _) {
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
          if (index == 1) Navigator.pushReplacementNamed(context, '/profile');
          if (index == 2) Navigator.pushReplacementNamed(context, '/chat');
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
