import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home.dart'; // Optional: Replace with your initial screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyA0rHx4NLSi2HpUHsRD5f9YQaI5IKQpMME",
        authDomain: "founditapp-f63e5.firebaseapp.com",
        projectId: "founditapp-f63e5",
        storageBucket: "founditapp-f63e5.appspot.com",
        messagingSenderId: "975298750134",
        appId: "1:975298750134:web:7c6754e0038633dd9b6817",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoundIt App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:
          const SplashScreen(), // You can replace with RegisterScreen if needed
    );
  }
}
