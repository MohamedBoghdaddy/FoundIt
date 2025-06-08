import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scroll_to_index/scroll_to_index.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../providers/chat_messages_provider.dart';

class ChatScreen extends StatefulWidget {
  final types.User currentUser;
  final String chatId;

  const ChatScreen({
    super.key,
    required this.currentUser,
    required this.chatId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  late AutoScrollController _scrollController;
  final TextEditingController _textController = TextEditingController();
  bool showEmojiPicker = false;
  Timer? _debounce;
  Timer? _typingDebounce;

  String? otherUserId;
  String otherUserName = 'Loading...';
  String? otherUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline(true);
    _fetchOtherUserInfo();
    _markMessagesAsRead();
    _textController.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserOnline(false);
    _setTyping(false);
    _debounce?.cancel();
    _typingDebounce?.cancel();
    _textController.removeListener(_handleTextChanged);
    _textController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (_textController.text.isNotEmpty) {
      _setTyping(true);
    } else {
      _setTyping(false);
    }
  }

  void _setUserOnline(bool online) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.currentUser.id)
          .update({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("⚠️ Error setting online status: $e");
    }
  }

  void _setTyping(bool typing) {
    try {
      if (typing) {
        FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chatId)
            .collection('typingStatus')
            .doc(widget.currentUser.id)
            .set({'isTyping': typing});
      } else {
        _typingDebounce?.cancel();
        _typingDebounce = Timer(const Duration(seconds: 1), () {
          FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .collection('typingStatus')
              .doc(widget.currentUser.id)
              .set({'isTyping': typing});
        });
      }
    } catch (e) {
      debugPrint("⚠️ Error setting typing status: $e");
    }
  }

  Future<void> _fetchOtherUserInfo() async {
    try {
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .get();

      if (chatDoc.exists) {
        final userIds = List<String>.from(chatDoc['userIds']);
        otherUserId = userIds.firstWhere((id) => id != widget.currentUser.id);

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(otherUserId)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data()!;
          final firstName = data['firstName'] ?? '';
          final lastName = data['lastName'] ?? '';
          final fullName = '$firstName $lastName'.trim();

          setState(() {
            otherUserName = fullName.isNotEmpty ? fullName : 'User';
            otherUserAvatarUrl = data['imageUrl'];
          });
        } else {
          setState(() => otherUserName = 'User');
        }
      }
    } catch (e) {
      debugPrint("⚠️ Error fetching user info: $e");
      setState(() => otherUserName = 'User');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages');

      final snapshot = await messagesRef
          .where('authorId', isNotEqualTo: widget.currentUser.id)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint("⚠️ Error marking messages as read: $e");
    }
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
    try {
      if (message.text.trim().isEmpty) return;
      setState(() => showEmojiPicker = false);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'authorId': widget.currentUser.id,
        'text': message.text,
        'createdAt': Timestamp.now(),
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': message.text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      _textController.clear();
      _setTyping(false);
    } catch (e) {
      debugPrint("⚠️ Error sending message: $e");
    }
  }

  Future<void> _handleImageAttachment() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final fileName = const Uuid().v4();
      final filePath = '${(await getTemporaryDirectory()).path}/$fileName.jpg';
      final file = File(filePath)..writeAsBytesSync(bytes);

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
        'authorId': widget.currentUser.id,
        'file': {
          'name': image.name,
          'size': bytes.length,
          'uri': file.path,
        },
        'type': 'file',
        'createdAt': Timestamp.now(),
        'isRead': false,
      });

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .update({
        'lastMessage': '[Attachment]',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("⚠️ Error sending image attachment: $e");
    }
  }

  void _handleReaction(String emoji, String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .set({
        'reactions.${widget.currentUser.id}': emoji,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("⚠️ Error adding reaction: $e");
    }
  }

  void _onMessageTap(types.Message message) {
    if (message is types.FileMessage) {
      final uri = message.uri;
      if (uri.startsWith('/')) {
        OpenFile.open(uri);
      } else {
        launchUrl(Uri.parse(uri));
      }
    }
  }

  void _openMeetingAttachment() async {
    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    TextEditingController locationController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
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
                  if (picked != null) selectedDate = picked;
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
                  if (picked != null) selectedTime = picked;
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: "Meeting Location",
                  border: OutlineInputBorder(),
                  hintText: "Enter meeting location",
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text("Send Meeting Details"),
                onPressed: () {
                  if (selectedDate != null &&
                      selectedTime != null &&
                      locationController.text.isNotEmpty) {
                    final formattedDate =
                        DateFormat('MMMM d, yyyy').format(selectedDate!);
                    final formattedTime = selectedTime!.format(context);
                    final location = locationController.text.trim();

                    final messageText = "📍 Claim Meeting Request\n"
                        "Let's meet on **$formattedDate** at **$formattedTime** "
                        "in front of **$location** to return the item.";

                    _handleSendPressed(types.PartialText(text: messageText));
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please select date, time, and location."),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatMessagesProvider(widget.chatId, widget.currentUser),
      child: Consumer<ChatMessagesProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Chat(
                    messages: provider.messages,
                    user: widget.currentUser,
                    onSendPressed: _handleSendPressed,
                    onAttachmentPressed: _handleAttachmentPressed,
                    inputOptions: InputOptions(textEditingController: _textController),
                    onMessageTap: (context, message) => _onMessageTap(message),
                    onMessageLongPress: (context, message) async {
                      final emoji = await showModalBottomSheet<String>(
                        context: context,
                        builder: (context) => Wrap(
                          children: ['❤️', '😂', '👍', '🎉', '😮', '😢'].map((e) {
                            return ListTile(
                              title: Text(e, style: const TextStyle(fontSize: 24)),
                              onTap: () => Navigator.pop(context, e),
                            );
                          }).toList(),
                        ),
                      );
                      if (emoji != null && message is types.TextMessage) {
                        _handleReaction(emoji, message.id);
                      }
                    },
                    scrollController: _scrollController,
                    showUserAvatars: true,
                    showUserNames: true,
                    theme: const DefaultChatTheme(
                      inputBackgroundColor: Colors.white,
                      primaryColor: Color(0xFF3182bd),
                      secondaryColor: Color(0xFFeff3ff),
                      backgroundColor: Color(0xFFeff3ff),
                      inputTextColor: Colors.black,
                      inputTextCursorColor: Color(0xFF3182bd),
                      sendButtonIcon: Icon(Icons.send, color: Color(0xFF3182bd)),
                      messageBorderRadius: 18,
                      messageInsetsVertical: 8,
                      messageInsetsHorizontal: 14,
                      sentMessageBodyTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                      receivedMessageBodyTextStyle: TextStyle(color: Colors.black87, fontSize: 16),
                      inputTextStyle: TextStyle(fontSize: 16),
                      inputBorderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                ),
                if (showEmojiPicker)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        final newText = _textController.text + emoji.emoji;
                        _textController.text = newText;
                        _textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: newText.length));
                      },
                      config: const Config(
                        columns: 7,
                        emojiSizeMax: 28,
                        bgColor: Color(0xFFF2F2F2),
                        indicatorColor: Colors.blue,
                        iconColor: Colors.grey,
                        iconColorSelected: Colors.blue,
                        backspaceColor: Colors.red,
                        recentsLimit: 28,
                      ),
                    ),
                  ),
                if (otherUserId != null)
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('chats')
                        .doc(widget.chatId)
                        .collection('typingStatus')
                        .doc(otherUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final isTyping = data?['isTyping'] ?? false;
                      return isTyping
                          ? const Padding(
                              padding: EdgeInsets.only(left: 24, bottom: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  "Typing...",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
