import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'chat_screen.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login first')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFeff3ff),
      appBar: AppBar(
        title: const Text('Search Users'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3182bd),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name or email...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allUsers = snapshot.data!.docs
                    .where((doc) => doc.id != currentUser.uid)
                    .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.toLowerCase();
                      final email = data['email']?.toLowerCase() ?? '';
                      return name.contains(_searchQuery) || email.contains(_searchQuery);
                    })
                    .toList();

                if (allUsers.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final doc = allUsers[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final fullName = '${data['firstName'] ?? ''} ${data['lastName'] ?? ''}'.trim();
                    final imageUrl = data['imageUrl'];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                          child: imageUrl == null ? const Icon(Icons.person) : null,
                          backgroundColor: const Color(0xFF6baed6),
                        ),
                        title: Text(fullName.isNotEmpty ? fullName : 'Unknown'),
                        subtitle: Text(data['email'] ?? ''),
                        onTap: () async {
                          final chatRef = FirebaseFirestore.instance.collection('chats');
                          final otherUserId = doc.id;
                          final currentUserTyped = types.User(id: currentUser.uid);

                          final existingChats = await chatRef
                              .where('userIds', arrayContains: currentUser.uid)
                              .get();

                          final matchingChats = existingChats.docs.where((chatDoc) {
                            final userIds = List<String>.from(chatDoc['userIds']);
                            return userIds.contains(otherUserId) && userIds.length == 2;
                          }).toList();

                          final existingChat = matchingChats.isNotEmpty ? matchingChats.first : null;

                          String chatId;
                          if (existingChat != null) {
                            chatId = existingChat.id;
                          } else {
                            final newChatDoc = await chatRef.add({
                              'userIds': [currentUser.uid, otherUserId],
                              'createdAt': FieldValue.serverTimestamp(),
                              'lastMessage': '',
                            });
                            chatId = newChatDoc.id;
                          }

                          if (!mounted) return;

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
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}