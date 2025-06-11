import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'edit_post_screen.dart';
import 'questionnaire_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final int _limitIncrement = 5;
  int _limit = 5;
  String _filter = 'all';
  String _sortBy = 'newest';
  late AnimationController _animationController;

  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      setState(() => _limit += _limitIncrement);
    }
  }

  Stream<QuerySnapshot> getFilteredPosts() {
    Query baseQuery = FirebaseFirestore.instance.collection('posts');

    if (_filter == 'lost' || _filter == 'found') {
      baseQuery = baseQuery.where('type', isEqualTo: _filter);
    }

    if (_sortBy == 'upvotes') {
      baseQuery = baseQuery.orderBy('score', descending: true);
    } else if (_sortBy == 'oldest') {
      baseQuery = baseQuery.orderBy('timestamp', descending: false);
    } else {
      baseQuery = baseQuery.orderBy('timestamp', descending: true);
    }

    return baseQuery.limit(_limit).snapshots();
  }

  Future<String?> _getUserReaction(String postId) async {
    final uid = currentUser?.uid;
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(uid)
        .get();
    return doc.exists ? doc['reaction'] : null;
  }

  Future<void> _handleVote(String postId, String reaction) async {
    final uid = currentUser?.uid;
    if (uid == null) return;

    final ref = FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .doc(uid);

    final doc = await ref.get();
    if (doc.exists && doc['reaction'] == reaction) {
      await ref.delete();
    } else {
      await ref.set({'reaction': reaction, 'userId': uid});
    }

    _updatePostScore(postId);
    _animationController.forward(from: 0.0);
  }

  Future<void> _updatePostScore(String postId) async {
    final reactions = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('reactions')
        .get();

    final total = reactions.docs.fold<int>(0, (acc, doc) {
      return acc + (doc['reaction'] == 'upvote' ? 1 : -1);
    });

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .update({'score': total});
  }

  Widget _buildVoteButton(String postId, String type, String? userReaction,
      IconData icon, Color color) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('reactions')
          .where('reaction', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length ?? 0;
        final isActive = userReaction == type;

        return ScaleTransition(
          scale: CurvedAnimation(
              parent: _animationController, curve: Curves.easeOutBack),
          child: TextButton.icon(
            onPressed: () => _handleVote(postId, type),
            style: TextButton.styleFrom(
              foregroundColor: isActive ? color : Colors.grey,
            ),
            icon: Icon(icon),
            label: Text('$count'),
          ),
        );
      },
    );
  }

  Widget _buildPostCard(
      Map<String, dynamic> data, String postId, String? userReaction) {
    final title = data['title'] ?? '';
    final type = data['type'] ?? '';
    final location = data['location'] ?? '';
    final timestamp = (data['timestamp'] as Timestamp).toDate();
    final imageUrl = data['imageUrl'] ?? '';
    final ownerId = data['userId'];
    final showQuestionnaire = type == 'lost' && ownerId != currentUser?.uid;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(imageUrl,
                  height: 180, width: double.infinity, fit: BoxFit.cover),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Chip(
                      label: Text(type.toUpperCase(),
                          style: const TextStyle(color: Colors.white)),
                      backgroundColor:
                          type == 'lost' ? Colors.red : Colors.green,
                    ),
                    const Spacer(),
                    if (ownerId == currentUser?.uid) ...[
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditPostScreen(
                                    postId: postId, postData: data),
                              ));
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
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                Text(location),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(_formatTimeAgo(timestamp),
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12)),
                    const Spacer(),
                    _buildVoteButton(postId, 'upvote', userReaction,
                        Icons.thumb_up, Colors.blue),
                    _buildVoteButton(postId, 'downvote', userReaction,
                        Icons.thumb_down, Colors.red),
                    if (showQuestionnaire)
                      TextButton.icon(
                        icon: const Icon(Icons.assignment_outlined),
                        label: const Text("Fill Questionnaire"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => QuestionnaireScreen(
                                questionnaireId: data['item_id'],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostList() {
    return StreamBuilder<QuerySnapshot>(
      stream: getFilteredPosts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollController,
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final data = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;
            return FutureBuilder<String?>(
              future: _getUserReaction(postId),
              builder: (context, snap) {
                return _buildPostCard(data, postId, snap.data);
              },
            );
          },
        );
      },
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.sort),
      initialValue: _sortBy,
      onSelected: (val) => setState(() => _sortBy = val),
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: 'newest', child: Text('Newest First')),
        PopupMenuItem(value: 'oldest', child: Text('Oldest First')),
        PopupMenuItem(value: 'upvotes', child: Text('Most Popular')),
      ],
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list),
      initialValue: _filter,
      onSelected: (val) => setState(() => _filter = val),
      itemBuilder: (ctx) => const [
        PopupMenuItem(value: 'all', child: Text('All')),
        PopupMenuItem(value: 'lost', child: Text('Lost')),
        PopupMenuItem(value: 'found', child: Text('Found')),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("FoundIt Feed"),
        automaticallyImplyLeading: false,
        actions: [_buildSortMenu(), _buildFilterMenu()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/profile');
          if (index == 2) Navigator.pushNamed(context, '/channels');
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
      body: _buildPostList(),
    );
  }
}
