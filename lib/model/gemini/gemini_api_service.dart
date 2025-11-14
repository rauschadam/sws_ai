import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiApiService {
  // 'gemini-2.5-flash' fast model for chatting
  static const String _model = 'gemini-2.5-flash';

  // Tool for the AI to get the weather
  static final _getWeatherTool = Tool(
    functionDeclarations: [
      FunctionDeclaration(
        'getWeather', // the name of the function, which it will call
        'Lekérdezi az aktuális időjárást egy adott helyszínen.', // the description so the AI knows what the function does
        Schema(
          SchemaType.object,
          // what parameters are required to call the function
          properties: {
            'location': Schema(
              SchemaType.string,
              description: 'A város neve, pl. "Budapest"',
            ),
          },
          requiredProperties: ['location'],
        ),
      ),
    ],
  );

  static final _searchKnowledgeBaseTool = Tool(
    functionDeclarations: [
      FunctionDeclaration(
        'searchKnowledgeBase',
        'OAP applikációval kapcsolatos információk',
        Schema(
          SchemaType.object,
          properties: {
            'query': Schema(
              SchemaType.string,
              description:
                  'A keresési kifejezés, pl. "Foglalás rögzítése", "OAP"',
            ),
          },
          requiredProperties: ['query'],
        ),
      ),
    ],
  );

  final GenerativeModel _modelInstance;

  // ChatSession manages chat history automatically
  late final ChatSession _chat;

  GeminiApiService({required String apiKey})
    // We initalize the GeneraticeModel
    : _modelInstance = GenerativeModel(
        model: _model,
        apiKey: apiKey,
        tools: [_getWeatherTool, _searchKnowledgeBaseTool],
      ) {
    // Then start the workflow
    _chat = _modelInstance.startChat();
  }

  Future<GenerateContentResponse> sendMessage(Content content) async {
    try {
      // send message with the chat object
      final response = await _chat.sendMessage(content);
      return response;
    }
    // error..
    catch (e) {
      throw Exception('Gemini API hiba: $e');
    }
  }
}
