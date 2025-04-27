import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ChatService {
  final StreamChatClient client;

  ChatService(this.client);

  Future<Channel> createOrGetChannel(
      String channelId, List<String> memberIds) async {
    final channel = client.channel(
      'messaging',
      id: channelId,
      extraData: {'members': memberIds},
    );
    await channel.watch();
    return channel;
  }

  void dispose() {
    client.dispose();
  }
}
