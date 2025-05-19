import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/chat_messages_provider.dart';

class ChatScreen extends StatelessWidget {
  final types.User currentUser;
  final String chatId;

  const ChatScreen({super.key, required this.currentUser, required this.chatId});

  void _handleSendPressed(types.PartialText message, ChatMessagesProvider provider) async {
    final newMessage = {
      'authorId': provider.currentUser.id,
      'text': message.text,
      'createdAt': Timestamp.now(),
    };

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(provider.chatId)
        .collection('messages')
        .add(newMessage);

    // تحديث آخر رسالة في مستند المحادثة
    await FirebaseFirestore.instance.collection('chats').doc(provider.chatId).update({
      'lastMessage': message.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatMessagesProvider(chatId, currentUser),
      child: Consumer<ChatMessagesProvider>(
        builder: (context, messagesProvider, _) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: Chat(
              messages: messagesProvider.messages,
              onSendPressed: (types.PartialText message) {
                _handleSendPressed(message, messagesProvider);
              },
              user: currentUser,
            ),
          );
        },
      ),
    );
  }
}
