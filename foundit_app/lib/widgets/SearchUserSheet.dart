import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:collection/collection.dart';
import '../screens/chat_screen.dart';

class SearchUserSheet extends StatefulWidget {
  const SearchUserSheet({super.key});

  @override
  State<SearchUserSheet> createState() => _SearchUserSheetState();
}

class _SearchUserSheetState extends State<SearchUserSheet> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final currentUser = fb_auth.FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search users...",
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final users = snapshot.data!.docs
                    .where((doc) =>
                        doc.id != currentUser?.uid &&
                        (doc['firstName']
                                ?.toLowerCase()
                                .contains(searchQuery) ??
                            false))
                    .toList();

                if (users.isEmpty) {
                  return const Center(child: Text("No matching users found"));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data() as Map<String, dynamic>;

                    final fullName =
                        "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}"
                            .trim();
                    final imageUrl = userData['imageUrl'];
                    final email = userData['email'] ?? '';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              imageUrl != null ? NetworkImage(imageUrl) : null,
                          child: imageUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(fullName.isNotEmpty ? fullName : 'No Name'),
                        subtitle: Text(email),
                        onTap: () async {
                          if (currentUser == null) return;

                          final selectedUserId = userDoc.id;
                          final chatRef =
                              FirebaseFirestore.instance.collection('chats');
                          final possibleChats = await chatRef
                              .where('userIds', arrayContains: currentUser.uid)
                              .get();

                          final existingChat =
                              possibleChats.docs.firstWhereOrNull((chatDoc) {
                            final userIds =
                                List<String>.from(chatDoc['userIds']);
                            return userIds.contains(selectedUserId) &&
                                userIds.length == 2;
                          });

                          String chatId;
                          if (existingChat != null) {
                            chatId = existingChat.id;
                          } else {
                            final newChatDoc = await chatRef.add({
                              'userIds': [currentUser.uid, selectedUserId],
                              'createdAt': FieldValue.serverTimestamp(),
                              'lastMessage': '',
                              'lastMessageTime': FieldValue.serverTimestamp(),
                            });
                            chatId = newChatDoc.id;
                          }

                          if (!mounted) return;

                          Navigator.pop(context);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                itemId: chatId,
                                currentUserId: currentUser.uid,
                                currentUserName:
                                    currentUser.displayName ?? fullName,
                                currentUserAvatar:
                                    currentUser.photoURL ?? imageUrl,
                                receiverId: selectedUserId,
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
          ),
        ],
      ),
    );
  }
}
