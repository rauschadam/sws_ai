import 'package:flutter/material.dart';
import 'package:sws_ai/gemini_api_service.dart';
import 'package:sws_ai/model/message.dart';

class ChatProvider with ChangeNotifier {
  /// Gemini API Key
  final _apiService = GeminiApiService(
    apiKey: "AIzaSyBkXuiuhDuooN5Wy60MgLAKwDICC7tgXBs",
  );

  // Messages & Loading..
  final List<Message> _messages = [];
  bool _isLoading = false;

  // Getters
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;

  // Send message
  Future<void> sendMessage(String content) async {
    // prevent empty sends
    if (content.trim().isEmpty) return;

    // user message
    final userMessage = Message(
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // add user message to chat
    _messages.add(userMessage);

    // update UI
    notifyListeners();

    // start loading..
    _isLoading = true;

    // update UI
    notifyListeners();

    // send message & receive response
    try {
      final response = await _apiService.sendMessage(content);

      // response message from AI
      final responseMessage = Message(
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      // add to chat
      _messages.add(responseMessage);
    }
    // error..
    catch (e) {
      // error message
      final errorMessage = Message(
        content: 'Error occured while receiving response from AI $e',
        isUser: false,
        timestamp: DateTime.now(),
      );

      // add message to chat
      _messages.add(errorMessage);
    }

    // finished loading..
    _isLoading = false;

    // update UI
    notifyListeners();
  }
}
