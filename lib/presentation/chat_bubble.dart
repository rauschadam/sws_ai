import 'package:flutter/material.dart';
import 'package:sws_ai/model/message.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // Decides whose message it is (AI/User)
    final _isUser = message.isUser;

    // PrimaryColor from the main theme
    final _primaryColor = Theme.of(context).colorScheme.primary;

    // The AI-s text background color
    final _aiColor = Colors.grey.shade200;

    final _borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      // User bubble (right aligned): sharp corner on the right bottom side.
      bottomLeft: _isUser
          ? const Radius.circular(16)
          : const Radius.circular(4),
      // AI bubble (left aligned): sharp corner on the left bottom side.
      bottomRight: _isUser
          ? const Radius.circular(4)
          : const Radius.circular(16),
    );

    return Padding(
      // Add horizontal padding for spacing and vertical padding between bubbles.
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      child: Align(
        // Align the bubble to the right for the user, left for the AI.
        alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          // Constrain the width so bubbles don't stretch across the entire screen.
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          // Inner padding for the text content.
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: _isUser ? _primaryColor : _aiColor,
            borderRadius: _borderRadius,
            // Add a subtle shadow for elevation and a soft professional look.
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),

          child: Text(
            message.content,
            style: TextStyle(
              // Set text color for contrast based on the background color.
              color: _isUser ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
