import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:collection/collection.dart';
import 'chat_screen.dart'; // Make sure to import your ChatScreen

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
              final displayName = userData['displayName'] ?? 'Unknown';
              final email = userData['email'] ?? '';

              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(displayName),
                subtitle: Text(email),
                onTap: () => _startChatWithUser(context, doc.id),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  void _startChatWithUser(BuildContext context, String otherUserId) async {
    final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserId = currentUser.uid;
    final users = [currentUserId, otherUserId]
      ..sort(); // Ensure consistent order

    // Search for existing chat with the exact userIds array
    final query = await FirebaseFirestore.instance
        .collection('chats')
        .where('userIds', isEqualTo: users)
        .limit(1)
        .get();

    String chatId;
    if (query.docs.isNotEmpty) {
      chatId = query.docs.first.id;
    } else {
      // Create new chat
      final doc = await FirebaseFirestore.instance.collection('chats').add({
        'userIds': users,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      chatId = doc.id;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          currentUser: types.User(id: currentUserId),
        ),
      ),
    );
  }
}
