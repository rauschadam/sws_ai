import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiApiService {
  // 'gemini-2.5-flash' fast model for chatting
  static const String _model = 'gemini-2.5-flash';

  // ChatSession manages chat history automatically
  final ChatSession _chat;

  GeminiApiService({required String apiKey})
    // We initalize the GeneraticeModel and start a chat workflow
    : _chat = GenerativeModel(model: _model, apiKey: apiKey).startChat();

  Future<String> sendMessage(String content) async {
    try {
      // send message with the chat object
      final response = await _chat.sendMessage(Content.text(content));

      // successful return
      if (response.text != null) {
        return response.text!;
      }
      // unsuccessfull return
      else {
        throw Exception('A Gemini üres választ adott.');
      }
    }
    // error..
    catch (e) {
      throw Exception('API Error $e');
    }
  }
}
