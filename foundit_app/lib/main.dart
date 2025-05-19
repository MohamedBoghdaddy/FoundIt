import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'screens/channel_list_screen.dart';
import 'screens/homepage.dart';
import 'screens/create_post.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register_screen.dart';
import 'screens/profile_page.dart';
import 'screens/questionnaire_screen.dart';
import 'screens/chat_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(
      scaffoldBackgroundColor: const Color(0xFFeff3ff),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF3182bd),
        foregroundColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6baed6),
        brightness: Brightness.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6baed6),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          textStyle: const TextStyle(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFc6dbef),
        border: OutlineInputBorder(),
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'FoundIt App',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreenRedirect(),
        '/welcome': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomePage(),
        '/createPost': (context) => const CreatePostScreen(),
        '/profile': (context) => const ProfilePage(),
        '/editPost': (context) => const Placeholder(),
        '/questionnaire': (context) => QuestionnaireScreen(
              questionnaireId: '',
              postId: '',
            ),
        '/channels': (context) => const ChannelListScreen(),
      },
    );
  }
}

class SplashScreenRedirect extends StatelessWidget {
  const SplashScreenRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (firebase_auth.FirebaseAuth.instance.currentUser == null) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/channels');  // غيرتها تدخل قائمة المحادثات
      }
    });

    return const Scaffold(
      body: Center(child: Text("FoundIt", style: TextStyle(fontSize: 24))),
    );
  }
}
