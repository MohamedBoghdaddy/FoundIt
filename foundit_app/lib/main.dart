import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/homepage.dart';
import 'screens/create_post.dart';
import 'screens/splash_screen.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register_screen.dart';
import 'screens/profile_page.dart';
import 'screens/edit_post_screen.dart';
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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFeff3ff),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF3182bd),
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF6baed6),
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
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreenRedirect(), // instead of SplashScreen()
        '/welcome': (context) =>
            const HomeScreen(), // 👈 the login/register screen
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) =>
            const HomePage(), // 👈 the Facebook-style post feed
          '/createPost': (context) => const CreatePostScreen(),
          '/profile': (context) => const ProfilePage(),
          '/editPost': (context) => const Placeholder(),
      },
    );
  }
}
class SplashScreenRedirect extends StatelessWidget {
  const SplashScreenRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 2), () {
      if (FirebaseAuth.instance.currentUser == null) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return const Scaffold(
      body: Center(child: Text("FoundIt", style: TextStyle(fontSize: 24))),
    );
  }
}

