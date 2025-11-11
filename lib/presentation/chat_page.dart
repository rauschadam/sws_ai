import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sws_ai/presentation/chat_bubble.dart';
import 'package:sws_ai/presentation/chat_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // empty..
                if (chatProvider.messages.isEmpty) {
                  return const Center(child: Text("Start a convo.."));
                }

                // chat messages
                return ListView.builder(
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    // get each message
                    final message = chatProvider.messages[index];

                    // return message
                    return ChatBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Loading Indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              // loading ..
              if (chatProvider.isLoading) {
                return const CircularProgressIndicator();
              }
              // finished
              return const SizedBox();
            },
          ),

          // User Input Box
          SafeArea(
            child: Row(
              children: [
                // Left: Text Field
                Expanded(child: TextField(controller: _controller)),

                // Right: Send Button
                IconButton(
                  onPressed: () {
                    // prevent empty sends
                    if (_controller.text.isEmpty) return;

                    final chatProvider = context.read<ChatProvider>();
                    chatProvider.sendMessage(_controller.text);
                    _controller.clear();
                  },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
