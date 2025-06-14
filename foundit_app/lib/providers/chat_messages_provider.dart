import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class ChatMessagesProvider extends ChangeNotifier {
  final String chatId;
  final types.User currentUser;
  List<types.Message> messages = [];

  ChatMessagesProvider(this.chatId, this.currentUser) {
    _listenToMessages();
  }

  void _listenToMessages() {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      messages = snapshot.docs.map((doc) {
        final data = doc.data();

        if (data['type'] == 'file' && data['file'] != null) {
          return types.FileMessage(
            author: types.User(id: data['authorId']),
            createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
            id: doc.id,
            name: data['file']['name'],
            size: data['file']['size'],
            uri: data['file']['uri'],
          );
        }

        return types.TextMessage(
          author: types.User(id: data['authorId']),
          createdAt: (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
          id: doc.id,
          text: data['text'] ?? '',
        );
      }).toList();

      notifyListeners();
    }, onError: (e) => debugPrint("Error fetching messages: $e"));
  }
}
