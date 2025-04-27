import 'package:flutter/material.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'chat_screen.dart';

class ChannelListScreen extends StatelessWidget {
  const ChannelListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = StreamChat.of(context).currentUser!;

    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: StreamChannelListView(
        controller: StreamChannelListController(
          client: StreamChat.of(context).client,
          filter: Filter.in_('members', [currentUser.id]),
          channelStateSort: const [SortOption('last_message_at')],
          limit: 20,
        ),
        onChannelTap: (channel) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(channel: channel)),
        ),
      ),
    );
  }
}
