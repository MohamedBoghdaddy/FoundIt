import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:collection/collection.dart';

import 'package:foundit_app/screens/chat_screen.dart';
import 'UserSearchScreen.dart'; // Corrected import

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

  void _showUserSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserSearchScreen()),
    );
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

              final otherUserId =
                  userIds.firstWhereOrNull((id) => id != currentUser.id);

              if (otherUserId == null) return const SizedBox();

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text("Loading..."),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const ListTile(
                      title: Text("User not found"),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  String displayName = '';
                  final firstName = userData['firstName'] ?? '';
                  final lastName = userData['lastName'] ?? '';
                  displayName = '$firstName $lastName'.trim();
                  if (displayName.isEmpty) {
                    final email = userData['email'] as String?;
                    displayName = (email != null && email.isNotEmpty)
                        ? email.split('@').first
                        : 'Unknown';
                  }

                  final imageUrl = userData['imageUrl'];
                  final isOnline = userData['isOnline'] == true;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage:
                            imageUrl != null ? NetworkImage(imageUrl) : null,
                        backgroundColor: const Color(0xFF6baed6),
                        child: imageUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(displayName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chatData['lastMessage'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          StreamBuilder<DocumentSnapshot>(
                            stream: _firestore
                                .collection('chats')
                                .doc(chatDoc.id)
                                .collection('typingStatus')
                                .doc(otherUserId)
                                .snapshots(),
                            builder: (context, typingSnapshot) {
                              if (typingSnapshot.hasData &&
                                  typingSnapshot.data!.exists &&
                                  (typingSnapshot.data!['isTyping'] == true)) {
                                return const Text(
                                  'Typing...',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle,
                              color: isOnline ? Colors.green : Colors.grey,
                              size: 12),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              itemId: chatDoc.id,
                              currentUserId: currentUser.id,
                              currentUserName:
                                  firebaseUser!.displayName ?? displayName,
                              currentUserAvatar: firebaseUser!.photoURL,
                              receiverId: otherUserId, // ✅ Pass receiverId here
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
        onPressed: _showUserSelection,
        child: const Icon(Icons.add),
      ),
    );
  }
}
