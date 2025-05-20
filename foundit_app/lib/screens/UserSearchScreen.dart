import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:collection/collection.dart';

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
                onTap: () async {
                  final selectedUserId = doc.id;
                  final chatRef = FirebaseFirestore.instance.collection('chats');

                  // Check if chat already exists between current and selected user
                  final existingChats = await chatRef
                      .where('userIds', arrayContains: currentUser.uid)
                      .get();

                  final existingChat = existingChats.docs.firstWhereOrNull((chatDoc) {
                    final List<dynamic> userIds = chatDoc['userIds'] ?? [];
                    return userIds.contains(selectedUserId);
                  });

                  if (existingChat == null) {
                    await chatRef.add({
                      'userIds': [currentUser.uid, selectedUserId],
                      'createdAt': FieldValue.serverTimestamp(),
                      'lastMessage': '',
                    });
                  }

                  Navigator.pop(context);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
