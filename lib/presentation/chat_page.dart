import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sws_ai/presentation/chat_bubble.dart';
import 'package:sws_ai/presentation/chat_provider.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  // Scroll to the bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Set the Built-in Bottom Nav Bars color, to match the UI
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
      ),
    );

    // Watch the provider to refresh UI when messages change
    final chatProvider = context.watch<ChatProvider>();

    // Scroll to the bottom whenever the messages list is updated
    if (chatProvider.messages.isNotEmpty) {
      _scrollToBottom();
    }

    return Scaffold(
      backgroundColor: Colors
          .white, // Ensures the entire background, including SafeArea, is white
      appBar: AppBar(
        title: const Text(
          'SWS AI Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // empty..
                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.auto_awesome_outlined,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Kezdj el beszélgetni az SWS AI-al...",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // chat messages
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Gemini gondolkodik...',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  );
                }
                return const SizedBox();
              },
            ),
          ),

          // User Input Box
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left: Text Field
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: TextField(
                        controller: _textController,
                        minLines: 1,
                        maxLines: 5, // multiple lines in input
                        textInputAction: TextInputAction.send,
                        onSubmitted: (value) {
                          if (_textController.text.isNotEmpty &&
                              !chatProvider.isLoading) {
                            context.read<ChatProvider>().sendMessage(
                              _textController.text,
                            );
                            _textController.clear();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Írj egy üzenetet...',
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey.shade100,
                          filled: true,
                        ),
                      ),
                    ),
                  ),

                  // Right: Send Button
                  Container(
                    margin: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(12),
                      ),
                      onPressed: chatProvider.isLoading
                          ? null
                          : () {
                              // block the button
                              if (_textController.text.trim().isEmpty) return;

                              context.read<ChatProvider>().sendMessage(
                                _textController.text,
                              );
                              _textController.clear();
                            },
                      icon: const Icon(Icons.send_rounded, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
