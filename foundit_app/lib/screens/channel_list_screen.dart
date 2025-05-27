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
              final userIds = chatData['userIds'] as List<dynamic>? ?? [];

              final otherUserId = userIds.firstWhereOrNull(
                (id) => id != currentUser.id,
              );

              if (otherUserId == null) return const SizedBox();

              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const ListTile(title: Text("Loading user..."));
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final firstName =
                      userData['firstName']?.toString() ?? 'No Name';
                  final avatarUrl = userData['imageUrl'];
                  final isOnline = userData['isOnline'] == true;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child:
                            avatarUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(firstName),
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
                                  (typingSnapshot.data!['isTyping'] ?? false)) {
                                return const Text(
                                  'Typing...',
                                  style: TextStyle(color: Colors.grey),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.circle,
                        color: isOnline ? Colors.green : Colors.grey,
                        size: 10,
                      ),
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
        onPressed: _showUserSelection,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showUserSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const SearchUserSheet(),
    );
  }
}

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
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                          final currentUserTyped =
                              types.User(id: currentUser.uid);

                          final chatRef =
                              FirebaseFirestore.instance.collection('chats');
                          final possibleChats = await chatRef
                              .where('userIds', arrayContains: currentUser.uid)
                              .get();

                          final existingChat =
                              possibleChats.docs.firstWhereOrNull(
                            (chatDoc) {
                              final userIds =
                                  List<String>.from(chatDoc['userIds']);
                              return userIds.contains(selectedUserId) &&
                                  userIds.length == 2;
                            },
                          );

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

                          if (!mounted) return;
                          Navigator.pop(context);
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
          ),
        ],
      ),
    );
  }
}
