import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        FirebaseService.getImageUrl(widget.postId).then((value) {
          imageUrl = value;
        }),
        FirebaseService.getPostOwner(widget.postId).then((value) {
          postOwner = value;
        }),
        FirebaseService.getPostType(widget.postId).then((value) {
          postType = value;
        }),
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
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    // Check if the post is 'lost' and if the current user is not the owner
    final showQuestionnaireButton =
        postType == 'lost' && postOwner != currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Item Verification")),
      body: Column(
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              height: 200,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? (loadingProgress.cumulativeBytesLoaded /
                            (loadingProgress.expectedTotalBytes ?? 1))
                        : null,
                  ),
                );
              },
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: questions.length,
              itemBuilder: (context, index) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questions[index],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    onChanged: (val) => answers[index] = val,
                    decoration: const InputDecoration(hintText: "Your Answer"),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          if (showQuestionnaireButton)
            FloatingActionButton.extended(
              label: const Text("Submit"),
              icon: const Icon(Icons.send),
              onPressed: () async {
                final score = await FirebaseService.submitAnswers(
                    widget.questionnaireId, answers);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Submitted! Your score: $score")),
                );
              },
            ),
        ],
      ),
    );
  }
}
