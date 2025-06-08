import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatScreen extends StatefulWidget {
  final String itemId;
  final String currentUserId;
  final String currentUserName;
  final String? currentUserAvatar;

  const ChatScreen({
    super.key,
    required this.itemId,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _pollingTimer;
  List<Map<String, dynamic>> messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool showEmojiPicker = false;
  bool _isTyping = false;
  Timer? _typingDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchMessages();
    // Set up polling every 3 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchMessages();
    });
    _controller.addListener(_handleTyping);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollingTimer?.cancel();
    _typingDebounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleTyping() {
    if (_controller.text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
      _resetTypingDebounce();
    } else if (_controller.text.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
    }
  }

  void _resetTypingDebounce() {
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isTyping = false);
      }
    });
  }

  Future<void> _fetchMessages() async {
    try {
      final newMessages = await getChatHistory(widget.itemId);
      if (mounted) {
        setState(() {
          messages = newMessages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      _showError('Failed to load messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _isTyping = false;
    });
    
    try {
      await sendMessage(widget.itemId, widget.currentUserId, text);
      _controller.clear();
      await _fetchMessages(); // Refresh messages after sending
    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _handleImageAttachment() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      // In a real app, you would upload the image to your server
      // and then send the URL as a message
      final message = "📷 [Image attachment] ${image.name}";
      _controller.text = message;
      _sendMessage();
    } catch (e) {
      _showError('Failed to attach image: $e');
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

                    _controller.text = messageText;
                    _sendMessage();
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Please select date, time, and location."),
                        duration: Duration(seconds: 2),
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

  void _handleAttachmentPressed() {
    setState(() => showEmojiPicker = false);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Send Image'),
              onTap: () {
                Navigator.pop(context);
                _handleImageAttachment();
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Schedule Meeting'),
              onTap: () {
                Navigator.pop(context);
                _openMeetingAttachment();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe && widget.currentUserAvatar != null)
            CircleAvatar(
              backgroundImage: NetworkImage(widget.currentUserAvatar!),
              radius: 16,
            ),
          Flexible(
            child: Container(
              margin: EdgeInsets.only(
                left: isMe ? 60 : 8,
                right: isMe ? 8 : 60,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue[100] : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      msg['sender_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    msg['message'],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(msg['timestamp']),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe && widget.currentUserAvatar != null)
            CircleAvatar(
              backgroundImage: NetworkImage(widget.currentUserAvatar!),
              radius: 16,
            ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final date = DateTime.parse(timestamp.toString());
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chat'),
            if (_isTyping)
              const Text(
                'Typing...',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? const Center(child: Text('No messages yet'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['sender_id'] == widget.currentUserId;
                          return _buildMessageBubble(msg, isMe);
                        },
                      ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (showEmojiPicker)
                  SizedBox(
                    height: 250,
                    child: GridView.count(
                      crossAxisCount: 7,
                      children: ['😀', '😂', '😍', '👍', '❤️', '🎉', '🙏']
                          .map((emoji) => IconButton(
                                icon: Text(emoji),
                                onPressed: () {
                                  final newText =
                                      _controller.text + emoji;
                                  _controller.text = newText;
                                  _controller.selection =
                                      TextSelection.fromPosition(
                                          TextPosition(offset: newText.length));
                                },
                              ))
                          .toList(),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      onPressed: _handleAttachmentPressed,
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions),
                      onPressed: () {
                        setState(() => showEmojiPicker = !showEmojiPicker);
                        FocusScope.of(context).unfocus();
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSending
                        ? const CircularProgressIndicator()
                        : IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: _sendMessage,
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // API Functions
  Future<void> sendMessage(
      String itemId, String senderId, String message) async {
    final uri = Uri.parse("http://127.0.0.1:8000/chat/send");
    final response = await http.post(
      uri.replace(queryParameters: {"item_id": itemId}),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "sender_id": senderId,
        "sender_name": widget.currentUserName,
        "message": message,
        "timestamp": DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to send message: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String itemId) async {
    final uri = Uri.parse("http://127.0.0.1:8000/chat/$itemId");
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to load messages: ${response.body}");
    }
    
    final List<dynamic> data = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(data);
  }
}