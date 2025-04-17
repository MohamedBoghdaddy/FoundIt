import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFeff3ff), // Lightest blue
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search, size: 100, color: Color(0xFF08519c)), // Darkest blue
            SizedBox(height: 20),
            Text(
              'FoundIt App',
              style: TextStyle(
                fontSize: 28,
                color: Color(0xFF08519c), // Darkest blue
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(
              color: Color(0xFF3182bd), // Primary progress blue
            ),
          ],
        ),
      ),
    );
  }
}
