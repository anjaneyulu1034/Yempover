// lib/services/notification_service.dart
import 'dart:convert';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:YemPover_app/services/token_service.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  String? _authToken;
  final TokenService _tokenService = TokenService();

  // Initialize with auth token
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Set auth token
  void setAuthToken(String token) {
    _authToken = token;
  }

  // Get headers with auth token
  Future<Map<String, String>> _getHeaders() async {
    // Prefer TokenService so token refresh/expiry logic is reused.
    _authToken = await _tokenService.getToken();

    if (_authToken == null || _authToken!.isEmpty) {
      if (_authToken == null) {
        await init();
      }
    }

    return {...ApiConstants.headers, 'Authorization': 'Bearer $_authToken'};
  }

  // Get notifications with pagination
  Future<NotificationResponse> getNotifications({
    int page = 1,
    int limit = 20,
    bool? isRead,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (isRead != null) {
        queryParams['isRead'] = isRead.toString();
      }

      final uri = Uri.parse(
        ApiConstants.notifications,
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return NotificationResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  // Get unread count
  Future<int> getUnreadCount() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/notifications/unread-count'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['unreadCount'] ?? 0;
      } else {
        throw Exception('Failed to get unread count');
      }
    } catch (e) {
      throw Exception('Error getting unread count: $e');
    }
  }

  // Mark notification as read
  Future<AppNotification> markAsRead(String notificationId) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .patch(
            Uri.parse(
              '${ApiConstants.baseUrl}/notifications/$notificationId/read',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AppNotification.fromJson(data['data']);
      } else {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .patch(
            Uri.parse('${ApiConstants.baseUrl}/notifications/read-all'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['success'] ?? false;
      } else {
        throw Exception('Failed to mark all as read');
      }
    } catch (e) {
      throw Exception('Error marking all as read: $e');
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/notifications/$notificationId'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['success'] ?? false;
      } else {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      throw Exception('Error deleting notification: $e');
    }
  }

  // Delete all notifications (clear all)
  Future<bool> deleteAllNotifications() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/notifications/all'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['success'] ?? false;
      } else {
        throw Exception('Failed to delete all notifications');
      }
    } catch (e) {
      throw Exception('Error deleting all notifications: $e');
    }
  }

  // Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/notifications/preferences'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NotificationPreferences.fromJson(data['data']);
      } else {
        throw Exception('Failed to get notification preferences');
      }
    } catch (e) {
      throw Exception('Error getting preferences: $e');
    }
  }

  // Update notification preferences
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .put(
            Uri.parse('${ApiConstants.baseUrl}/notifications/preferences'),
            headers: headers,
            body: json.encode(preferences.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return NotificationPreferences.fromJson(data['data']);
      } else {
        throw Exception('Failed to update notification preferences');
      }
    } catch (e) {
      throw Exception('Error updating preferences: $e');
    }
  }

  // Batch delete notifications
  Future<bool> batchDeleteNotifications(List<String> notificationIds) async {
    try {
      final headers = await _getHeaders();

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/notifications/batch-delete'),
            headers: headers,
            body: json.encode({'ids': notificationIds}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data']['success'] ?? false;
      } else {
        throw Exception('Failed to batch delete notifications');
      }
    } catch (e) {
      throw Exception('Error batch deleting notifications: $e');
    }
  }
}
