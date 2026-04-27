// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:io';

import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/models/ProductPostmain.dart';
import 'package:YemPover_app/screens/PostDetailScreen.dart';
import 'package:YemPover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:YemPover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:YemPover_app/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:http/http.dart' as http;
import 'package:YemPover_app/main.dart' as app;
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/services/trade_chat_service/trade_chat_service.dart';

class NotificationService1 {
  static final fln.FlutterLocalNotificationsPlugin
  _flutterLocalNotificationsPlugin = app.flutterLocalNotificationsPlugin;

  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static bool _isInitialized = false;
  static int _registerRetryCount = 0;
  static const int _maxRegisterRetries = 6;
  static Map<String, dynamic>? _pendingNavigationData;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint('FCM permission request failed: $e');
    }

    try {
      final token = await _firebaseMessaging.getToken().timeout(
        const Duration(seconds: 8),
      );
      debugPrint('🔥 FCM TOKEN: $token');
      if (token != null && token.isNotEmpty) {
        await _registerTokenWithBackend(token);
      }
    } catch (e) {
      debugPrint('Failed to fetch FCM token during init: $e');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        debugPrint('FCM token refreshed');
        await _registerTokenWithBackend(newToken);
      },
      onError: (e) {
        debugPrint('FCM token refresh stream error: $e');
      },
    );

    const fln.AndroidInitializationSettings androidSettings =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    const fln.DarwinInitializationSettings iosSettings =
        fln.DarwinInitializationSettings();

    const fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (fln.NotificationResponse response) async {
            debugPrint('🔔 Notification tapped: ${response.payload}');
            final payloadData = _decodeLocalPayload(response.payload);
            if (payloadData != null) {
              await _handleNotificationNavigation(payloadData);
            }
          },
    );

    // Android 13+ permission
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
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
      if (message.data.isNotEmpty) {
        debugPrint('📦 Notification data: ${message.data}');
        _handleNotificationNavigation(message.data);
      }
    });

    // Get initial message if app was opened from a terminated state
    try {
      final initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          '📩 App opened from terminated state: ${initialMessage.messageId}',
        );
        if (initialMessage.data.isNotEmpty) {
          _pendingNavigationData = Map<String, dynamic>.from(
            initialMessage.data,
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to read initial FCM message: $e');
    }

    _isInitialized = true;
  }

  Future<void> _showLocalNotification(
    String title,
    String body, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      const fln.AndroidNotificationDetails androidDetails =
          fln.AndroidNotificationDetails(
            'signup_channel',
            'Signup Notifications',
            channelDescription: 'Notifications for signup events',
            importance: fln.Importance.high,
            priority: fln.Priority.high,
            ticker: 'ticker',
            showWhen: true,
            enableVibration: true,
            playSound: true,
          );

      const fln.DarwinNotificationDetails iosDetails =
          fln.DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const fln.NotificationDetails notificationDetails =
          fln.NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecond, // Unique ID
        title,
        body,
        notificationDetails,
        payload: data != null ? jsonEncode(data) : null,
      );

      debugPrint('✅ Local notification shown: $title');
    } catch (e) {
      debugPrint('❌ Notification Error: $e');
    }
  }

  // Add these methods to your NotificationService1 class in notification1_service.dart

  static Future<void> _registerTokenWithBackend(String fcmToken) async {
    try {
      final authToken = await TokenService().getToken();
      if (authToken == null || authToken.isEmpty) {
        debugPrint('Skipping push token registration: user auth token missing');
        _scheduleTokenSyncRetry();
        return;
      }

      final response = await http.post(
        Uri.parse(ApiConstants.mePushToken),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'token': fcmToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _registerRetryCount = 0;
        debugPrint('Push token registered with backend');
      } else {
        debugPrint(
          'Push token register failed: ${response.statusCode} ${response.body}',
        );
        _scheduleTokenSyncRetry();
      }
    } catch (e) {
      debugPrint('Push token registration error: $e');
      _scheduleTokenSyncRetry();
    }
  }

  static void _scheduleTokenSyncRetry() {
    if (_registerRetryCount >= _maxRegisterRetries) {
      return;
    }

    _registerRetryCount += 1;
    final waitSeconds = _registerRetryCount * 5;

    Future.delayed(Duration(seconds: waitSeconds), () async {
      await syncTokenWithBackend();
    });
  }

  static Future<void> syncTokenWithBackend() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('No FCM token available to sync with backend');
        return;
      }
      await _registerTokenWithBackend(token);
    } catch (e) {
      debugPrint('Failed to sync FCM token with backend: $e');
    }
  }

  static Future<void> flushPendingNavigation() async {
    final data = _pendingNavigationData;
    if (data == null) return;

    _pendingNavigationData = null;
    await _handleNotificationNavigation(data);
  }

  static Map<String, dynamic>? _decodeLocalPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  static String? _readDataValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static String? _extractIdFromRoute(String? route, List<String> prefixes) {
    if (route == null || route.trim().isEmpty) return null;

    final trimmedRoute = route.trim();
    Uri? uri;
    try {
      uri = Uri.parse(trimmedRoute);
    } catch (_) {
      uri = null;
    }

    final path = (uri?.path.isNotEmpty == true) ? uri!.path : trimmedRoute;
    for (final prefix in prefixes) {
      if (!path.startsWith(prefix)) continue;

      final remaining = path.substring(prefix.length);
      final segments = remaining
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        return segments.first;
      }
    }

    return null;
  }

  static String? _resolveTradeChatId(Map<String, dynamic> data) {
    final route = _readDataValue(data, ['deepLinkPath', 'deep_link_path']);

    final direct = _readDataValue(data, [
      'tradeChatId',
      'trade_chat_id',
      'chatId',
      'chat_id',
    ]);

    if (direct != null) return direct;

    return _extractIdFromRoute(route, [
      '/trade-chat/',
      '/trade-chats/',
      '/chat/',
      '/chats/',
    ]);
  }

  static String? _resolvePostId(Map<String, dynamic> data) {
    final route = _readDataValue(data, ['deepLinkPath', 'deep_link_path']);

    final productId = _readDataValue(data, ['productId', 'product_id']);
    if (productId != null) return productId;

    final serviceId = _readDataValue(data, ['serviceId', 'service_id']);
    if (serviceId != null) return serviceId;

    return _extractIdFromRoute(route, [
      '/product/',
      '/products/',
      '/service/',
      '/services/',
      '/post/',
      '/posts/',
    ]);
  }

  static bool _isServiceNotification(Map<String, dynamic> data) {
    final serviceId = _readDataValue(data, ['serviceId', 'service_id']);
    if (serviceId != null) return true;

    final productId = _readDataValue(data, ['productId', 'product_id']);
    if (productId != null) return false;

    final route =
        _readDataValue(data, ['deepLinkPath', 'deep_link_path']) ?? '';
    return route.contains('/service/') || route.contains('/services/');
  }

  static bool _isTradeType(Map<String, dynamic> data) {
    final typeText = (_readDataValue(data, ['type', 'notificationType']) ?? '')
        .toUpperCase();

    const tradeTypes = {
      'OFFER_RECEIVED',
      'OFFER_ACCEPTED',
      'OFFER_REJECTED',
      'OFFER_COUNTERED',
      'OFFER_WITHDRAWN',
      'MESSAGE_RECEIVED',
      'DEAL_COMPLETED',
      'DEAL_CANCELLED',
      'TRADE_COMPLETED',
    };

    return tradeTypes.contains(typeText);
  }

  static Future<void> _handleNotificationNavigation(
    Map<String, dynamic> rawData,
  ) async {
    final navigator = app.rootNavigatorKey.currentState;
    final context = app.rootNavigatorKey.currentContext;

    if (navigator == null || context == null) {
      _pendingNavigationData = Map<String, dynamic>.from(rawData);
      return;
    }

    final data = Map<String, dynamic>.from(rawData);

    try {
      final chatId = _resolveTradeChatId(data);
      if (chatId != null) {
        final tradeChatService = TradeChatService();
        try {
          final chat = await tradeChatService.getChatById(chatId);
          final currentUserId = await TokenService().getUserId();

          if (currentUserId != null && currentUserId.isNotEmpty) {
            await navigator.push(
              MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                  chat: chat,
                  currentUserId: currentUserId,
                  onChatUpdated: (_) {},
                ),
              ),
            );
            return;
          }
        } finally {
          tradeChatService.dispose();
        }
      }

      final postId = _resolvePostId(data);
      if (postId != null) {
        final apiService = ApiService();
        try {
          final response = await apiService.getPostDetail(
            postId: postId,
            type: _isServiceNotification(data)
                ? PostType.service
                : PostType.product,
          );

          await navigator.push(
            MaterialPageRoute(
              builder: (_) =>
                  PostDetailScreen(post: response.post, userItems: const []),
            ),
          );
          return;
        } finally {
          apiService.dispose();
        }
      }

      if (_isTradeType(data)) {
        await navigator.push(
          MaterialPageRoute(builder: (_) => const TradeChatScreen()),
        );
      }
    } catch (e) {
      debugPrint('❌ Notification deep-link navigation error: $e');
    }
  }

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
      'Welcome back to YemPover! You have successfully logged in.',
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

  // Request notification permission again from in-app settings/profile screens.
  Future<bool> requestNotificationPermissionAgain() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
