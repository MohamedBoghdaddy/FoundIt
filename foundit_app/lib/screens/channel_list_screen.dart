import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:collection/collection.dart';
import 'chat_screen.dart';

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
        .orderBy('createdAt', descending: true)
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
      appBar: AppBar(title: const Text('My Chats')),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No chats found.'));
          }

          final chats = snapshot.data!.docs;

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chatDoc = chats[index];
              final chatData = chatDoc.data() as Map<String, dynamic>;

              final List<dynamic> userIds = chatData['userIds'] ?? [];
              final otherUserId = userIds.firstWhere(
                (id) => id != currentUser.id,
                orElse: () => 'Unknown',
              );

              return ListTile(
                title: Text('Chat with: $otherUserId'),
                subtitle: Text(chatData['lastMessage'] ?? ''),
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showUserSelection(),
      ),
    );
  }

  void _showUserSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UserSelectionScreen()),
    );
  }
}

class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = fb_auth.FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Select User')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs
              .where((u) => u.id != currentUser.uid)
              .toList();

          return ListView(
            children: users.map((doc) {
              final userData = doc.data() as Map<String, dynamic>;
              final displayName = userData['displayName'] ??
                  '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(displayName.isNotEmpty ? displayName : 'Unknown'),
                subtitle: Text(userData['email'] ?? ''),
                onTap: () async {
                  final chatRef = FirebaseFirestore.instance.collection('chats');
                  final selectedUserId = doc.id;
                  final selectedUser = types.User(id: selectedUserId);
                  final currentUserTyped = types.User(id: currentUser.uid);

                  // Check for existing chat
                  final possibleChats = await chatRef
                      .where('userIds', arrayContains: currentUser.uid)
                      .get();

                  final existingChat = possibleChats.docs.firstWhereOrNull((chatDoc) {
                    final userIds = List<String>.from(chatDoc['userIds']);
                    return userIds.contains(selectedUserId) && userIds.length == 2;
                  });

                  String chatId;

                  if (existingChat != null) {
                    chatId = existingChat.id;
                  } else {
                    final newChatDoc = await chatRef.add({
                      'userIds': [currentUser.uid, selectedUserId],
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastMessage': '',
                    });
                    chatId = newChatDoc.id;
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        chatId: chatId,
                        currentUser: currentUserTyped,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
