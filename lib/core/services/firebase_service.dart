import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to handle Firebase initialization, push notifications, and Firestore cache settings.
class FirebaseService {
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  FirebaseService({FirebaseFirestore? firestore, FirebaseMessaging? messaging})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  /// Initialize Firebase Core and setup Offline persistence.
  static Future<void> initialize() async {
    // If testing or already initialized, bypass double initialization
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    // Configure Cloud Firestore Offline Cache Persistence
    final firestore = FirebaseFirestore.instance;
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    if (kDebugMode) {
      print('Firebase initialized with Offline persistence enabled.');
    }
  }

  /// Request permissions for FCM and retrieve the push token.
  Future<String?> setupPushNotifications() async {
    try {
      // 1. Request Notification Permissions
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print(
          'User notification permission status: ${settings.authorizationStatus}',
        );
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 2. Fetch the FCM token for this device
        String? token;
        if (kIsWeb) {
          // Add your web push credentials key (VAPID key) if available
          token = await _messaging.getToken();
        } else {
          token = await _messaging.getToken();
        }

        if (kDebugMode) {
          print('FCM Token: $token');
        }

        // 3. Setup Foreground Message Handlers
        _setupForegroundMessaging();

        return token;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting up push notifications: $e');
      }
    }
    return null;
  }

  /// Listening to notifications while the app is in the foreground.
  void _setupForegroundMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
          'Received a foreground notification message: ${message.notification?.title}',
        );
        print('Message data payload: ${message.data}');
      }
      // Trigger local notification visual or stream controller
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print(
          'A user clicked on the FCM notification to open the app: ${message.data}',
        );
      }
      // Navigate to respective dashboard/notification module if needed
    });
  }

  /// Get Firestore Instance
  FirebaseFirestore get firestore => _firestore;

  /// Get Firebase Messaging Instance
  FirebaseMessaging get messaging => _messaging;
}

/// Provider for FirebaseService.
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});
