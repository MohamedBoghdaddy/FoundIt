import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_post_screen.dart';

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
        title: const Text("FoundIt Feed"),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/profile');
          if (index == 2) Navigator.pushNamed(context, '/chat');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
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

  Widget _buildPostCard(BuildContext context, Map<String, dynamic> post, String postId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser?.uid ?? '';
    final displayName = currentUser?.email ?? 'User';
    final timestamp = (post['timestamp'] as Timestamp).toDate();
    final imageUrl = post['imageUrl'] as String?;

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isValidImageUrl(imageUrl))
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 200,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text("⚠️ Image failed to load", style: TextStyle(color: Colors.red)),
                      ),
                    ),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                                        postId: postId,
                                        postData: post,
                                      ),
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
                              )
                            ],
                          )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(post['description'] ?? ''),
                    const SizedBox(height: 4),
                    Text("📍 ${post['location']}   •   🕒 ${_formatTimeAgo(timestamp)}",
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
                      icon: Icon(
                        hasReacted ? Icons.favorite : Icons.favorite_border,
                        color: hasReacted ? Colors.red : null,
                      ),
                      label: Text("React (${reactions.length})"),
                      onPressed: () async {
                        final reactionRef = FirebaseFirestore.instance
                            .collection('posts')
                            .doc(postId)
                            .collection('reactions')
                            .doc(currentUserId);

                        final doc = await reactionRef.get();
                        if (doc.exists) {
                          await reactionRef.delete();
                        } else {
                          await reactionRef.set({
                            'userId': currentUserId,
                            'displayName': displayName,
                            'timestamp': Timestamp.now(),
                          });
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.comment_outlined),
                      label: const Text("Comment"),
                      onPressed: () => _openComments(context, postId),
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

  void _openComments(BuildContext context, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final userId = user?.uid ?? '';
    final displayName = user?.email ?? 'User';
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Comments", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final comments = snapshot.data!.docs;

                return SizedBox(
                  height: 300,
                  child: ListView(
                    children: comments.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(data['displayName'] ?? 'User'),
                        subtitle: Text(data['content'] ?? ''),
                        trailing: data['userId'] == userId
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      controller.text = data['content'];
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Edit Comment"),
                                          content: TextField(controller: controller),
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                await FirebaseFirestore.instance
                                                    .collection('posts')
                                                    .doc(postId)
                                                    .collection('comments')
                                                    .doc(doc.id)
                                                    .update({
                                                  'content': controller.text.trim(),
                                                });
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Save"),
                                            )
                                          ],
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
                                          .collection('comments')
                                          .doc(doc.id)
                                          .delete();
                                    },
                                  ),
                                ],
                              )
                            : null,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: "Write a comment..."),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () async {
                      final text = controller.text.trim();
                      if (text.isEmpty) return;
                      await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(postId)
                          .collection('comments')
                          .add({
                        'userId': userId,
                        'displayName': displayName,
                        'content': text,
                        'timestamp': Timestamp.now(),
                      });
                      controller.clear();
                    },
                  )
                ],
              ),
            )
          ]),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }
}
