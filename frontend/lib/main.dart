import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/app.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: 'assets/.env');
  } catch (e) {
    debugPrint('WARNING: Failed to load .env file. Using default values. Error: $e');
  }

  // Phase 3: Firebase initialization
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('FATAL: Firebase initialization failed: $e');
    rethrow;
  }

  runApp(const ProviderScope(child: GridpoolApp()));
}
