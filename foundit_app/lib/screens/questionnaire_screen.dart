// ...
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui';

import 'chat_screen.dart'; // ✅ Updated import

class QuestionnaireScreen extends StatefulWidget {
  final String questionnaireId;

  const QuestionnaireScreen({super.key, required this.questionnaireId});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  List<String> questions = [];
  List<String> answers = [];
  String? imageUrl;
  String? finderId;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();
  final String baseUrl =
      kIsWeb ? "http://localhost:8000" : "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/items/${widget.questionnaireId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (!mounted) return;
        setState(() {
          questions = List<String>.from(data["questions"]);
          answers = List.filled(questions.length, '');
          imageUrl = data["image_url"];
          finderId = data["finder_id"];
        });
      } else {
        throw Exception("Failed to load item data: ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading questions: $e")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> submitAnswers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to submit")),
      );
      return;
    }

    final emptyIndex = answers.indexWhere((a) => a.trim().isEmpty);
    if (emptyIndex != -1) {
      _scrollController.animateTo(
        emptyIndex * 140,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please answer all questions")),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/evaluate-match"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "item_id": widget.questionnaireId,
          "user_answers": Map.fromIterables(questions, answers),
          "user_id": currentUser.uid,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final match = data["match"];
        final score = data["score"];
        final showImage = data["show_image"];
        final imageUrl = data["image_url"];
        final chatEnabled = data["chat_enabled"];

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              match
                  ? "✅ Match confirmed! Score: ${(score * 100).toStringAsFixed(0)}%"
                  : "❌ Not a match. Score: ${(score * 100).toStringAsFixed(0)}%",
            ),
            backgroundColor: match ? Colors.green : Colors.red,
          ),
        );

        if (match) {
          await FirebaseFirestore.instance.collection('matches').add({
            'user_id': currentUser.uid,
            'item_id': widget.questionnaireId,
            'score': score,
            'timestamp': Timestamp.now(),
          });

          if (showImage && imageUrl != null) {
            setState(() => this.imageUrl = imageUrl);
          }

          if (chatEnabled) {
            _showChatButton(context);
          }
        }
      } else {
        throw Exception("Submission failed: ${response.body}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Submission error: $e")),
      );
    }
  }

  void _showChatButton(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || finderId == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "✅ Ownership Verified!",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text("You can now contact the finder to arrange pickup"),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      itemId: widget.questionnaireId,
                      currentUserId: currentUser.uid,
                      currentUserName: currentUser.displayName ?? "Anonymous",
                      currentUserAvatar: currentUser.photoURL,
                      receiverId: finderId!,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Start Chat with Finder"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final showSubmitButton = finderId != currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Item Verification"),
        backgroundColor: const Color(0x66000000), // <- Avoid withOpacity
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  if (imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            height: 200,
                            width: double.infinity,
                          ),
                          BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                            child: Container(
                              height: 200,
                              color:
                                  const Color(0x1A000000), // semi-transparent
                            ),
                          ),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: LinearProgressIndicator(
                      value: answers.where((a) => a.trim().isNotEmpty).length /
                          questions.length,
                      color: Colors.blue,
                      backgroundColor: Colors.grey[300],
                      minHeight: 8,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: questions.length,
                      itemBuilder: (context, index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Q${index + 1}: ${questions[index]}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              onChanged: (val) => answers[index] = val,
                              decoration: InputDecoration(
                                hintText: "Your answer...",
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (showSubmitButton)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.send),
                        label: const Text("Submit Answers"),
                        onPressed: submitAnswers,
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
