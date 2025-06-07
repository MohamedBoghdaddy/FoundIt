import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'chat_screen.dart';
import 'UserSearchScreen.dart';

class ChannelListScreen extends StatefulWidget {
  const ChannelListScreen({super.key});

  @override
  State<ChannelListScreen> createState() => _ChannelListScreenState();
}

class _ChannelListScreenState extends State<ChannelListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final fb_auth.User? firebaseUser = fb_auth.FirebaseAuth.instance.currentUser;

  Stream<QuerySnapshot> _getUserChats() {
    if (firebaseUser == null) return const Stream.empty();
    return _firestore
        .collection('chats')
        .where('userIds', arrayContains: firebaseUser!.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (firebaseUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    final currentUser = types.User(id: firebaseUser!.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFeff3ff),
      appBar: AppBar(
        title: const Text('My Chats'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3182bd),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No chats found. Tap + to start a new conversation!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;
              final List<dynamic> userIds = chatData['userIds'] ?? [];
              final otherUserId = userIds.firstWhere(
                (id) => id != currentUser.id,
                orElse: () => 'Unknown',
              );

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading..."));
                  }

                  final userData = userSnapshot.data!.data() as Map<String, dynamic>?;

                  final displayName = userData?['displayName'] ??
                      '${userData?['firstName'] ?? ''} ${userData?['lastName'] ?? ''}'.trim();

                  final imageUrl = userData?['imageUrl'];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                        backgroundColor: const Color(0xFF6baed6),
                        child: imageUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(displayName.isNotEmpty ? displayName : 'Unknown'),
                      subtitle: Text(chatData['lastMessage'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              chatId: chatDoc.id,
                              currentUser: currentUser,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
     floatingActionButton: FloatingActionButton(
  backgroundColor: const Color(0xFF3182bd),
  child: const Icon(Icons.add),
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserSearchScreen()),
    );
  },
),

    );
  }

  void _showUserSelection() {
    Navigator.pushNamed(context, '/userSearch');
  }
}
