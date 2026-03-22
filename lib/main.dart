import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'editor_page.dart';
import 'core/navigator_key.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Debug print: app start
  print("App starting...");
  if (kIsWeb) {
    print("Running on Web platform");
  } else {
    print("Running on Mobile/Desktop platform");
  }

  // ✅ Firebase initialize WITH options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 Debug print: MaterialApp build
    print("Building MyApp Widget");

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const EditorPage(),
    );
  }
}