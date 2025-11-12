import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sws_ai/firebase_options.dart';
import 'package:sws_ai/presentation/chat_page.dart';
import 'package:sws_ai/presentation/chat_provider.dart';

Future<void> main() async {
  /// 1. Get API Keys
  await dotenv.load(fileName: ".env");

  // 2. Initalize FireBase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. Run App
  runApp(
    ChangeNotifierProvider(
      create: (context) => ChatProvider(),
      child: const MainApp(),
    ),
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade700),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}
