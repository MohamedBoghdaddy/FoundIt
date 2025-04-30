import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

import 'screens/homepage.dart';
import 'screens/create_post.dart';
import 'screens/home.dart';
import 'screens/login.dart';
import 'screens/register_screen.dart';
import 'screens/profile_page.dart';
import 'screens/questionnaire_screen.dart'; // Import the questionnaire screen

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

  final client = StreamChatClient(
    'b67pax5b2wdq',
    logLevel: Level.INFO,
  );

  await client.connectUser(
    User(id: 'tutorial-flutter'),
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidHV0b3JpYWwtZmx1dHRlciJ9.S-MJpoSwDiqyXpUURgO5wVqJ4vKlIVFLSEyrFYCOE1c',
  );

  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final StreamChatClient client;

  const MyApp({super.key, required this.client});

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

    final streamChatTheme = StreamChatThemeData.fromTheme(themeData).merge(
      StreamChatThemeData(
        channelPreviewTheme: StreamChannelPreviewThemeData(
          avatarTheme: StreamAvatarThemeData(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        ownMessageTheme: StreamMessageThemeData(
          messageBackgroundColor: Colors.blue.shade300,
          messageTextStyle: const TextStyle(color: Colors.white),
        ),
        otherMessageTheme: StreamMessageThemeData(
          messageBackgroundColor: Colors.blue.shade100,
          messageTextStyle: const TextStyle(color: Colors.black),
        ),
      ),
    );

    return MaterialApp(
      title: 'FoundIt App',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      builder: (context, child) => StreamChat(
        client: client,
        streamChatThemeData: streamChatTheme,
        child: child,
      ),
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
              questionnaireId: '', // Pass the actual questionnaireId here
              postId: '', // Pass the actual postId here
            ), // Add the route for the questionnaire screen
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
        Navigator.pushReplacementNamed(context, '/home');
      }
    });

    return const Scaffold(
      body: Center(child: Text("FoundIt", style: TextStyle(fontSize: 24))),
    );
  }
}

class ChannelPage extends StatelessWidget {
  const ChannelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StreamChannelHeader(),
      body: Column(
        children: const [
          Expanded(child: StreamMessageListView()),
          StreamMessageInput(),
        ],
      ),
    );
  }
}
