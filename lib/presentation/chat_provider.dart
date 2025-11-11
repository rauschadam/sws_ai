import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sws_ai/model/gemini/gemini_api_service.dart';
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
      // 1. Send Message
      var response = await _apiService.sendMessage(Content.text(content));

      // 2. Check for function calls
      final functionCalls = response.functionCalls;

      // AI wants to call functions
      if (functionCalls.isNotEmpty) {
        // 3. Safe call
        final call = functionCalls.first;

        // 4. Run the required function
        final functionResult = await _handleFunctionCall(call);

        // 5. Send back the results to the model
        response = await _apiService.sendMessage(
          Content.functionResponse(call.name, functionResult),
        );

        // 6. process final answer
        if (response.text != null) {
          _addMessage(response.text!, false);
        } else {
          _addErrorMessage(
            "A modell funkcióhívás után nem adott szöveges választ.",
          );
        }
      }
      // AI returned with an answer
      else if (response.text != null) {
        _addMessage(response.text!, false);
      }
      // AI returned with an error
      else {
        _addErrorMessage(
          "A modell sem szöveges, sem funkció választ nem adott.",
        );
      }
    }
    // error..
    catch (e) {
      // add error message
      _addErrorMessage('Hiba történt: $e');
    }

    // finished loading..
    _isLoading = false;

    // update UI
    notifyListeners();
  }

  // This function handles calls requested by Gemini
  Future<Map<String, Object?>> _handleFunctionCall(FunctionCall call) async {
    // We identify which functions were called

    if (call.name == 'getWeather') {
      // read the arguments
      final location = call.args['location'] as String?;

      // run the ""dummy" function
      return _getDummyWeather(location);
    }

    // If it called an unknown function
    return {'error': 'Ismeretlen funkció'};
  }

  // A "dummy" function that pretends to call an API
  Future<Map<String, Object?>> _getDummyWeather(String? location) async {
    // Delay to simulate network call
    await Future.delayed(const Duration(seconds: 1));

    if (location == null || location.isEmpty) {
      return {'error': 'Helyszín megadása kötelező'};
    }

    // Hard-coded answers for the test
    if (location.toLowerCase().contains('budapest')) {
      return {
        'location': 'Budapest',
        'temperature': 25,
        'forecast': 'Napos, enyhe szél',
      };
    }
    // If its not about budapest
    else {
      return {
        'location': location,
        'temperature': 20,
        'forecast': 'Változóan felhős',
      };
    }
  }

  /// Adds the message to the list
  void _addMessage(String content, bool isUser) {
    _messages.add(
      Message(content: content, isUser: isUser, timestamp: DateTime.now()),
    );
    notifyListeners();
  }

  /// Adds the error to the list
  void _addErrorMessage(String error) {
    _messages.add(
      Message(
        content: 'Hiba: $error',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }
}
