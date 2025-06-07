import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../providers/chat_messages_provider.dart';

class ChatScreen extends StatelessWidget {
  final types.User currentUser;
  final String chatId;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.chatId,
  });

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

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(provider.chatId)
        .update({'lastMessage': message.text});
  }

  void _openMeetingAttachment(BuildContext context, ChatMessagesProvider provider) {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    TextEditingController locationController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 24,
              left: 24,
              right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "📎 Schedule Claim Meeting",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: const Text("Pick a Date"),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.access_time),
                label: const Text("Pick a Time"),
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (picked != null) {
                    selectedTime = picked;
                  }
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Meeting Location",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Send Meeting Details"),
                onPressed: () {
                  if (selectedDate != null && selectedTime != null && locationController.text.isNotEmpty) {
                    final formattedDate = DateFormat('MMMM d, yyyy').format(selectedDate!);
                    final formattedTime = selectedTime!.format(context);
                    final location = locationController.text.trim();

                    final messageText =
                        "\uD83D\uDCCD Claim Meeting Request\nLet’s meet on **$formattedDate** at **$formattedTime** in front of **$location** to return the item.";

                    _handleSendPressed(types.PartialText(text: messageText), provider);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please select date, time, and location.")),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatMessagesProvider(chatId, currentUser),
      child: Consumer<ChatMessagesProvider>(
        builder: (context, messagesProvider, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFeff3ff),
            appBar: AppBar(
              title: const Text("Chat"),
              centerTitle: true,
              backgroundColor: const Color(0xFF3182bd),
              foregroundColor: Colors.white,
              elevation: 3,
            ),
            body: Chat(
              messages: messagesProvider.messages,
              onSendPressed: (types.PartialText message) {
                _handleSendPressed(message, messagesProvider);
              },
              user: currentUser,
              theme: const DefaultChatTheme(
                primaryColor: Color(0xFF3182bd),
                secondaryColor: Colors.white,
                backgroundColor: Color(0xFFeff3ff),
                inputBackgroundColor: Colors.white,
                inputBorderRadius: BorderRadius.all(Radius.circular(24)),
                inputTextColor: Colors.black,
                inputTextCursorColor: Color(0xFF3182bd),
                sendButtonIcon: Icon(Icons.send, color: Color(0xFF3182bd)),
                messageBorderRadius: 18,
                messageInsetsVertical: 8,
                messageInsetsHorizontal: 14,
                sentMessageBodyTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                receivedMessageBodyTextStyle: TextStyle(color: Colors.black87, fontSize: 16),
                inputTextStyle: TextStyle(fontSize: 16),
              ),
              customBottomWidget: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () => _openMeetingAttachment(context, messagesProvider),
                  ),
                  Expanded(child: ChatInput(onSendPressed: (msg) => _handleSendPressed(msg, messagesProvider))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  final void Function(types.PartialText) onSendPressed;

  const ChatInput({super.key, required this.onSendPressed});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Message",
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
              ),
              onSubmitted: (text) {
                if (text.trim().isNotEmpty) {
                  onSendPressed(types.PartialText(text: text.trim()));
                  controller.clear();
                }
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFF3182bd)),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onSendPressed(types.PartialText(text: controller.text.trim()));
                controller.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
