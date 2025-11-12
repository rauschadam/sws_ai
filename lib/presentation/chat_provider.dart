import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:sws_ai/model/gemini/gemini_api_service.dart';
import 'package:sws_ai/model/message.dart';

class ChatProvider with ChangeNotifier {
  /// Weather API key
  final String _weatherApiKey = dotenv.env['WEATHER_API_KEY']!;

  /// Gemini API service
  final _apiService;
  ChatProvider()
    : _apiService = GeminiApiService(apiKey: dotenv.env['GEMINI_API_KEY']!);

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

      // The loop runs until the model requests a function call
      while (response.functionCalls.isNotEmpty) {
        // 2. Check for function calls
        final functionCalls = response.functionCalls;

        // List of answers for each function call
        final List<Part> functionResponseParts = [];

        // 3. Iterate through the function calls
        for (final call in functionCalls) {
          // 4. Run the functions
          final functionResult = await _handleFunctionCall(call);

          // 5. Add the result to the list
          functionResponseParts.add(
            FunctionResponse(call.name, functionResult),
          );
        }

        // 6. Return the results to the AI
        response = await _apiService.sendMessage(
          Content(null, functionResponseParts),
        );
      }
      // 7. Process the final answer
      if (response.text != null) {
        _addMessage(response.text!, false);
      } else {
        _addErrorMessage(
          "A modell funkcióhívás után nem adott szöveges választ.",
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

    // Weather call
    if (call.name == 'getWeather') {
      // read the arguments
      final location = call.args['location'] as String?;

      // run the function
      return _getRealWeather(location);
    }
    // Search the base knowledge
    else if (call.name == 'searchKnowledgeBase') {
      // read the arguments
      final query = call.args['query'] as String?;
      // run the "DUMMY" function
      return _getDummyKnowledgeBaseSearch(query);
    }

    // If it called an unknown function
    return {'error': 'Ismeretlen funkció'};
  }

  /// Search for answers in the knowledge base
  Future<Map<String, Object?>> _getDummyKnowledgeBaseSearch(
    String? query,
  ) async {
    // Simulate the waiting
    await Future.delayed(const Duration(milliseconds: 1500));

    // prevent empty sends
    if (query == null || query.isEmpty) {
      return {'error': 'Keresési kifejezés megadása kötelező'};
    }

    // Hard-coded answers
    if (query.toLowerCase().contains('kovács') &&
        query.toLowerCase().contains('bónusz')) {
      return {
        'source_document': 'bonuszok_2023.xlsx',
        'content_snippet':
            'Kovács János (IT Osztály) 2023-as bónusza: 500,000 Ft. Kifizetve: 2024.01.10.',
        'confidence': 0.95,
      };
    } else {
      return {
        'source_document': 'nincs_találat',
        'content_snippet':
            'A keresett információ nem található a dokumentumokban.',
        'confidence': 0.0,
      };
    }
  }

  // Get the weather from real API
  Future<Map<String, Object?>> _getRealWeather(String? location) async {
    // prevent empty sends
    if (location == null || location.isEmpty) {
      return {'error': 'Helyszín megadása kötelező'};
    }

    try {
      // 1. Build up the URL
      final queryParameters = {
        'key': _weatherApiKey,
        'q': location,
        'aqi': 'no',
      };
      final uri = Uri.https(
        'api.weatherapi.com',
        '/v1/current.json',
        queryParameters,
      );

      // 2. Start the call
      final apiResponse = await http.get(uri);

      // 3. Check the response
      if (apiResponse.statusCode == 200) {
        // 4. Process the Json
        final data = jsonDecode(apiResponse.body);

        // 5. We return a map for Gemini (in the defined format)
        return {
          'location': data['location']['name'],
          'temperature': data['current']['temp_c'],
          'forecast': data['current']['condition']['text'],
        };
      }
      // Api error..
      else {
        final errorData = jsonDecode(apiResponse.body);
        return {'error': 'API Hiba: ${errorData['error']['message']}'};
      }
    }
    // Network error..
    catch (e) {
      return {'error': 'Hálózati hiba: $e'};
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
