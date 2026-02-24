// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:Yempover_app/main.dart' as app;

class NotificationService1 {
  static final FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = app.flutterLocalNotificationsPlugin;

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    String? token = await _firebaseMessaging.getToken();
    debugPrint("🔥 FCM TOKEN: $token");

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        debugPrint('🔔 Notification tapped: ${response.payload}');
        // Handle notification tap here if needed
      },
    );

    // Android 13+ permission
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground message received: ${message.messageId}');
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? "Notification",
          message.notification!.body ?? "",
          message.data, // Pass data payload
        );
      }
    });

    // Handle when app is in background and opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📩 Message opened app: ${message.messageId}');
      // Handle navigation based on notification data if needed
      if (message.data.isNotEmpty) {
        debugPrint('📦 Notification data: ${message.data}');
        // You can navigate to specific screens based on the data
      }
    });

    // Get initial message if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();
    if (initialMessage != null) {
      debugPrint(
        '📩 App opened from terminated state: ${initialMessage.messageId}',
      );
      // Handle initial message if needed
    }

    _isInitialized = true;
  }

  Future<void> _showLocalNotification(
    String title,
    String body, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'signup_channel',
            'Signup Notifications',
            channelDescription: 'Notifications for signup events',
            importance: Importance.high,
            priority: Priority.high,
            ticker: 'ticker',
            showWhen: true,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond, // Unique ID
        title,
        body,
        notificationDetails,
        payload: data != null ? data.toString() : null,
      );

      debugPrint('✅ Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Notification Error: $e');
    }
  }

  // Add these methods to your NotificationService1 class in notification1_service.dart

  // Public method to show OTP verification success notification (same style as signup)
  Future<void> showOTPVerificationSuccessNotification() async {
    await _showLocalNotification(
      '✅ Phone Verified Successfully!',
      'Your phone number has been verified successfully. You can now continue.',
    );
  }

  // Public method to show login success notification
  Future<void> showLoginSuccessNotification() async {
    await _showLocalNotification(
      '🔐 Login Successful!',
      'Welcome back to Yempover! You have successfully logged in.',
    );
  }

  // Optional: You can also add a channel for OTP notifications
  // Add this in your init() method if you want a separate channel

  // Public method to show signup success notification
  Future<void> showSignupSuccessNotification() async {
    await _showLocalNotification(
      '🎉 Registration Successful!',
      'Your account has been created successfully. Please verify your phone number.',
    );
  }

  // Get FCM token
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Delete token if needed
  static Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
  }

  // Subscribe to a topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    debugPrint('✅ Subscribed to topic: $topic');
  }

  // Unsubscribe from a topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    debugPrint('✅ Unsubscribed from topic: $topic');
  }
}
