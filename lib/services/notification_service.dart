import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);

    // Initialize Firebase Messaging for iOS
    if (Platform.isIOS) {
      await _initializeFirebaseMessaging();
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Request permission
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');

        // Get FCM token
        final token = await messaging.getToken();
        debugPrint('FCM Token: $token');

        // TODO: Send token to your backend server

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Messaging: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.notification?.title}');

    if (message.data['phoneNumber'] != null) {
      final phoneNumber = message.data['phoneNumber'] as String;
      final contactName = message.data['contactName'] as String? ?? 'Unknown';
      final notes = message.data['notes'] as String? ?? '';

      await showIncomingCallNotification(
        contactName: contactName,
        notes: notes,
        phoneNumber: phoneNumber,
      );
    }
  }

  Future<void> showIncomingCallNotification({
    required String contactName,
    required String notes,
    required String phoneNumber,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'incoming_calls',
      'Incoming Calls',
      channelDescription: 'Notifications for incoming calls with contact notes',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.call,
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      phoneNumber.hashCode,
      '📞 $contactName',
      notes,
      details,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}
