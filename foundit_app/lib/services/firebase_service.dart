import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection references
  static CollectionReference get questionnaires =>
      _firestore.collection('questionnaires');
  static CollectionReference get messages => _firestore.collection('messages');

  /// Create a new questionnaire
  static Future<void> createQuestionnaire({
    required String questionnaireId,
    required String itemId,
    required List<String> questions,
    required List<String> correctAnswers,
    required DateTime foundDate,
  }) async {
    await questionnaires.doc(questionnaireId).set({
      'itemId': itemId,
      'questions': questions,
      'correctAnswers': correctAnswers,
      'foundDate': Timestamp.fromDate(foundDate),
    });
  }

  /// Add a response to a questionnaire
  static Future<void> addQuestionnaireResponse({
    required String questionnaireId,
    required String respondentId,
    required List<String> answers,
  }) async {
    final questionnaireDoc = await questionnaires.doc(questionnaireId).get();
    final correctAnswers =
        List<String>.from(questionnaireDoc['correctAnswers']);

    int score = 0;
    for (int i = 0; i < answers.length; i++) {
      if (answers[i].toLowerCase() == correctAnswers[i].toLowerCase()) score++;
    }

    await questionnaires.doc(questionnaireId).collection('responses').add({
      'respondentId': respondentId,
      'answers': answers,
      'score': score,
      'timestamp': Timestamp.now(),
      'status': 'pending',
    });
  }

  /// Retrieve questionnaire questions
  static Future<List<String>> getQuestions(String questionnaireId) async {
    final doc = await questionnaires.doc(questionnaireId).get();
    return List<String>.from(doc['questions']);
  }

  /// Retrieve chat messages for a specific item
  static Stream<QuerySnapshot> getChatMessages(String itemId) {
    return messages
        .where('itemId', isEqualTo: itemId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Send a chat message
  static Future<void> sendMessage({
    required String itemId,
    required String senderId,
    required String receiverId,
    required String text,
  }) async {
    await messages.add({
      'itemId': itemId,
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': Timestamp.now(),
    });
  }
}