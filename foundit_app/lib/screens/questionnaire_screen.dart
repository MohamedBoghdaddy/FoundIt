import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<List<String>> getQuestions(String questionnaireId) async {
    final doc = await _firestore
        .collection('questionnaires')
        .doc(questionnaireId)
        .get();
    return List<String>.from(doc['questions']);
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
      'respondentId': 'currentUserId', // Replace with actual user ID
      'answers': answers,
      'score': score,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });

    return score;
  }
}

class QuestionnaireScreen extends StatefulWidget {
  final String questionnaireId;
  const QuestionnaireScreen({super.key, required this.questionnaireId});

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  List<String> questions = [];
  List<String> answers = [];

  @override
  void initState() {
    super.initState();
    fetchQuestions();
  }

  void fetchQuestions() async {
    questions = await FirebaseService.getQuestions(widget.questionnaireId);
    answers = List.filled(questions.length, '');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Item Verification")),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: questions.length,
        itemBuilder: (context, index) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              questions[index],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            TextFormField(
              onChanged: (val) => answers[index] = val,
              decoration: const InputDecoration(hintText: "Your Answer"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Submit"),
        icon: const Icon(Icons.send),
        onPressed: () async {
          final score = await FirebaseService.submitAnswers(
            widget.questionnaireId,
            answers,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Submitted! Your score: \$score")),
          );
        },
      ),
    );
  }
}
