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

  String? otherUserId;
  String? otherUserName;
  String? otherUserAvatarUrl;

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    WidgetsBinding.instance.addObserver(this);
    _setUserOnline(true);
    _fetchOtherUserInfo();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setUserOnline(false);
    _setTyping(false);
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _setUserOnline(bool online) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUser.id)
        .update({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  void _setTyping(bool typing) {
    FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('typingStatus')
        .doc(widget.currentUser.id)
        .set({'isTyping': typing});
  }

  Future<void> _fetchOtherUserInfo() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .get();
    final userIds = List<String>.from(chatDoc['userIds']);
    otherUserId = userIds.firstWhere((id) => id != widget.currentUser.id);

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(otherUserId)
        .get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        otherUserName = data['firstName'] ?? 'User';
        otherUserAvatarUrl = data['imageUrl'];
      });
    }
  }

  Future<void> _markMessagesAsRead() async {
    final messagesRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages');

    final snapshot = await messagesRef
        .where('authorId', isNotEqualTo: widget.currentUser.id)
        .where('isRead', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  Future<void> _handleSendPressed(types.PartialText message) async {
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
        .update({'lastMessage': message.text});
  }

  Future<void> _handleAttachment() async {
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
        .update({'lastMessage': '[Attachment]'});
  }

  void _handleReaction(String emoji, String messageId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .doc(messageId)
        .set({
      'reactions.${widget.currentUser.id}': emoji,
    }, SetOptions(merge: true));
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatMessagesProvider(widget.chatId, widget.currentUser),
      child: Consumer<ChatMessagesProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundImage: otherUserAvatarUrl != null
                        ? NetworkImage(otherUserAvatarUrl!)
                        : null,
                    child: otherUserAvatarUrl == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(otherUserName ?? 'Loading...',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData || !snapshot.data!.exists) {
                            return const Text('...');
                          }
                          final isOnline = snapshot.data!.data() is Map &&
                              (snapshot.data!.get('isOnline') ?? false);
                          return Text(
                            isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 12,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.emoji_emotions),
                  onPressed: () =>
                      setState(() => showEmojiPicker = !showEmojiPicker),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _handleAttachment,
                ),
              ],
            ),
            body: Column(
              children: [
                Expanded(
                  child: Chat(
                    messages: provider.messages,
                    user: widget.currentUser,
                    onSendPressed: _handleSendPressed,
                    onMessageTap: (context, message) => _onMessageTap(message),
                    onMessageLongPress: (context, message) async {
                      final emoji = await showModalBottomSheet<String>(
                        context: context,
                        builder: (context) => Wrap(
                          children: ['❤️', '😂', '👍', '🎉'].map((e) {
                            return ListTile(
                              title:
                                  Text(e, style: const TextStyle(fontSize: 24)),
                              onTap: () => Navigator.pop(context, e),
                            );
                          }).toList(),
                        ),
                      );
                      if (emoji != null) _handleReaction(emoji, message.id);
                    },
                    showUserAvatars: true,
                    showUserNames: true,
                    scrollController: _scrollController,
                    theme: const DefaultChatTheme(
                      inputBackgroundColor: Colors.white,
                      primaryColor: Colors.blueAccent,
                      secondaryColor: Color(0xFFECECEC),
                    ),
                  ),
                ),
                if (showEmojiPicker)
                  SizedBox(
                    height: 250,
                    child: EmojiPicker(
                      onEmojiSelected: (category, emoji) {
                        _textController.text += emoji.emoji;
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
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('typingStatus')
                      .doc(otherUserId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final isTyping = snapshot.data?.get('isTyping') ?? false;
                    return isTyping
                        ? const Padding(
                            padding: EdgeInsets.only(left: 16, bottom: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Typing...",
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : const SizedBox.shrink();
                  },
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: 2,
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacementNamed(context, '/home');
                } else if (index == 1) {
                  Navigator.pushReplacementNamed(context, '/profile');
                }
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: 'Profile',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_outline),
                  label: 'Chat',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
