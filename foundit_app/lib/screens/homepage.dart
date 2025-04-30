import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'questionnaire_screen.dart';
import 'edit_post_screen.dart';

class FirebaseService {
  static final _firestore = FirebaseFirestore.instance;

  // Fetches the questions for the questionnaire
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

  // Submits answers and calculates score
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

  // Fetches image URL of the post
  static Future<String> getImageUrl(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    return postDoc['imageUrl'] ?? '';
  }

  // Fetches the owner of the post
  static Future<String?> getPostOwner(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    return postDoc['userId'];
  }

  // Fetches the type of the post (lost or found)
  static Future<String> getPostType(String postId) async {
    final postDoc = await _firestore.collection('posts').doc(postId).get();
    return postDoc['type'];
  }

  // Fetches the upvotes count of a post
  static Future<int> getUpvotes(String postId) async {
    final reactionsSnapshot = await _firestore
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .get();
    return reactionsSnapshot.docs
        .where((doc) => doc['reaction'] == 'upvote')
        .length;
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Stream<QuerySnapshot> getPosts() {
    return FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  bool _isValidImageUrl(String? url) {
    return url != null && url.startsWith('http');
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Future.microtask(() {
        Navigator.pushReplacementNamed(context, '/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: const Text("FoundIt Feed"), automaticallyImplyLeading: false),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/profile');
          if (index == 2) Navigator.pushNamed(context, '/chat');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/createPost'),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: getPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No posts yet.'));
            }

            final posts = snapshot.data!.docs;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: posts.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildPostCard(context, data, doc.id);
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPostCard(
      BuildContext context, Map<String, dynamic> post, String postId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final displayName = currentUser?.email ?? 'User';
    final timestamp = (post['timestamp'] as Timestamp).toDate();
    final imageUrl = post['imageUrl'] as String?;
    final postType = post['type']; // 'lost' or 'found'
    final postOwner = post['userId']; // Post owner's user ID

    final showQuestionnaireButton =
        postType == 'lost' && postOwner != currentUserId;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .snapshots(),
      builder: (context, snapshot) {
        final reactions = snapshot.data?.docs ?? [];
        final hasReacted = reactions.any((doc) => doc.id == currentUserId);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isValidImageUrl(imageUrl))
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
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
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(post['title'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        if (post['userId'] == currentUserId)
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditPostScreen(
                                          postId: postId, postData: post),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection('posts')
                                      .doc(postId)
                                      .delete();
                                },
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(post['description'] ?? ''),
                    const SizedBox(height: 4),
                    Text(
                        "📍 ${post['location']}   •   🕒 ${_formatTimeAgo(timestamp)}",
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.thumb_up_alt_outlined),
                      label: const Text("Upvote"),
                      onPressed: () async {
                        await _toggleUpvote(postId);
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.thumb_down_alt_outlined),
                      label: const Text("Downvote"),
                      onPressed: () async {
                        await _toggleDownvote(postId);
                      },
                    ),
                    if (showQuestionnaireButton)
                      TextButton.icon(
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text("Fill Questionnaire"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestionnaireScreen(
                                  questionnaireId: postId, postId: postId),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleUpvote(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    if (userId != null) {
      final reactionRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .doc(userId);
      final doc = await reactionRef.get();

      if (doc.exists) {
        await reactionRef.update({'reaction': 'upvote'});
      } else {
        await reactionRef.set({'reaction': 'upvote', 'userId': userId});
      }
    }
  }

  Future<void> _toggleDownvote(String postId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid;

    if (userId != null) {
      final reactionRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .doc(userId);
      final doc = await reactionRef.get();

      if (doc.exists) {
        await reactionRef.update({'reaction': 'downvote'});
      } else {
        await reactionRef.set({'reaction': 'downvote', 'userId': userId});
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }
}
