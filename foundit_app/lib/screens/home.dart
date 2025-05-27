import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:collection/collection.dart';
import 'chat_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("FoundIt",
            style: TextStyle(
                color: Color(0xFF1B2A49), fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            child:
                const Text("Home", style: TextStyle(color: Color(0xFF1B2A49))),
          ),
          TextButton(
            onPressed: () {},
            child:
                const Text("About", style: TextStyle(color: Color(0xFF1B2A49))),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("Contact",
                style: TextStyle(color: Color(0xFF1B2A49))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    const Text(
                      "Welcome to FoundIt!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B2A49),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Helping the MIU community find lost items quickly & efficiently.",
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B67CA),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child:
                          const Text("Login", style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/register'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF5B67CA)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Register",
                          style: TextStyle(
                              color: Color(0xFF5B67CA), fontSize: 16)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                "Who We Are",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2A49)),
              ),
              const SizedBox(height: 8),
              const Text(
                "FoundIt is a community-driven app built by students for students. We are a team of MIU developers passionate about solving real-life campus problems.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              const Text(
                "What is FoundIt?",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2A49)),
              ),
              const SizedBox(height: 8),
              const Text(
                "FoundIt allows you to post about lost or found items around campus. By using smart questionnaires and matching logic, we increase the chances of finding your lost belongings or reuniting found ones with their owners.",
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 60),
              const Divider(),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: const [
                    Text("© 2025 FoundIt App - MIU",
                        style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email, size: 16, color: Colors.grey),
                        SizedBox(width: 6),
                        Text("contact@foundit.app",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
