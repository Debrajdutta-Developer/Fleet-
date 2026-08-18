import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/services/firebase_service.dart';
import 'core/services/local_storage_service.dart';

void main() async {
  // 1. Ensure widget binding is initialized before service bootstraps
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Shared Preferences and Secure Storage
  final sharedPrefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();

  final localStorageService = LocalStorageService(
    prefs: sharedPrefs,
    secureStorage: secureStorage,
  );

  // 3. Initialize Firebase Services & Offline Persistence Settings
  try {
    await FirebaseService.initialize();

    // Setup background push notification listeners and get token
    final firebaseService = FirebaseService();
    await firebaseService.setupPushNotifications();
  } catch (e) {
    // If Firebase initialization fails (e.g. missing google-services.json in mock/CI environments),
    // we log it and proceed so that local offline database fallback continues running.
    debugPrint('Firebase Core bootstrap skipped/failed: $e');
    debugPrint('Continuing in offline-first cached execution mode.');
  }

  // 4. Run application wrapped in Riverpod ProviderScope
  runApp(
    ProviderScope(
      overrides: [
        // Override local storage service provider with the pre-initialized instance
        localStorageServiceProvider.overrideWithValue(localStorageService),
      ],
      child: const FleetOSApp(),
    ),
  );
}
