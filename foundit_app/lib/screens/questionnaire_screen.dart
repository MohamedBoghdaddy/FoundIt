import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<List<String>> getQuestions(String questionnaireId) async {
    final doc = await _firestore
        .collection('questionnaires')
        .doc(questionnaireId)
        .get();
    if (doc.exists && doc.data() != null) {
      return List<String>.from(doc['questions']);
    } else {
      throw Exception("Questionnaire not found");
    }
  }

  static Future<int> submitAnswers(
      String questionnaireId, List<String> answers) async {
    final doc = await _firestore
        .collection('questionnaires')
        .doc(questionnaireId)
        .get();
    final correctAnswers = List<String>.from(doc['correctAnswers']);
    int score = 0;

    for (int i = 0; i < answers.length; i++) {
      if (answers[i].trim().toLowerCase() ==
          correctAnswers[i].trim().toLowerCase()) {
        score++;
      }
    }

    await _firestore
        .collection('questionnaires')
        .doc(questionnaireId)
        .collection('responses')
        .add({
      'respondentId': FirebaseAuth.instance.currentUser?.uid,
      'answers': answers,
      'score': score,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });

    return score;
  }

  static Future<String> getImageUrl(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    return postDoc['imageUrl'] ?? '';
  }

  static Future<String?> getPostOwner(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    return postDoc['userId'];
  }

  static Future<String> getPostType(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    return postDoc['type'];
  }
}

class QuestionnaireScreen extends StatefulWidget {
  final String questionnaireId;
  final String postId;

  const QuestionnaireScreen(
      {super.key, required this.questionnaireId, required this.postId});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  List<String> questions = [];
  List<String> answers = [];
  String? imageUrl;
  String? postOwner;
  String? postType;
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  void fetchData() async {
    try {
      await Future.wait([
        FirebaseService.getQuestions(widget.questionnaireId).then((value) {
          questions = value;
          answers = List.filled(questions.length, '');
        }),
        FirebaseService.getImageUrl(widget.postId)
            .then((value) => imageUrl = value),
        FirebaseService.getPostOwner(widget.postId)
            .then((value) => postOwner = value),
        FirebaseService.getPostType(widget.postId)
            .then((value) => postType = value),
      ]);
    } catch (e) {
      print("Error fetching data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final showQuestionnaireButton =
        postType == 'lost' && postOwner != currentUser?.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Item Verification"),
        backgroundColor: Colors.black.withOpacity(0.4),
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
                              color: Colors.black.withOpacity(0.1),
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
                  if (showQuestionnaireButton)
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
                        label: const Text("Submit"),
                        onPressed: () async {
                          final emptyIndex =
                              answers.indexWhere((a) => a.trim().isEmpty);
                          if (emptyIndex != -1) {
                            _scrollController.animateTo(
                              emptyIndex * 140,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please answer all questions")),
                            );
                            return;
                          }

                          final score = await FirebaseService.submitAnswers(
                              widget.questionnaireId, answers);
                          if (!mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  "Submitted! Score: $score/ ${questions.length}"),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: Colors.green[600],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
