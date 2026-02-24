// lib/providers/notification_provider.dart
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<AppNotification> _notifications = [];
  NotificationPreferences? _preferences;
  Pagination? _pagination;
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AppNotification> get notifications => _notifications;
  NotificationPreferences? get preferences => _preferences;
  int get unreadCount => _unreadCount;
  int get totalCount => _pagination?.total ?? 0;
  int get currentPage => _pagination?.page ?? 1;
  bool get hasMorePages => _pagination?.hasNextPage ?? false;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load notifications
  Future<void> loadNotifications({bool? isRead}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.getNotifications(
        page: 1,
        limit: 20,
        isRead: isRead,
      );

      _notifications = response.data.notifications;
      _pagination = response.data.pagination;
      _unreadCount = response.data.unreadCount;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (!hasMorePages || _isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _service.getNotifications(
        page: currentPage + 1,
        limit: 20,
      );

      _notifications.addAll(response.data.notifications);
      _pagination = response.data.pagination;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh notifications
  Future<void> refreshNotifications() async {
    await loadNotifications();
  }

  // Load unread count
  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _service.getUnreadCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Mark notification as read
  Future<AppNotification?> markAsRead(String notificationId) async {
    try {
      final updatedNotification = await _service.markAsRead(notificationId);

      // Update in list
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = updatedNotification;
      }

      // Update unread count
      await loadUnreadCount();

      notifyListeners();
      return updatedNotification;
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  // Mark all as read
  Future<bool> markAllAsRead() async {
    try {
      final success = await _service.markAllAsRead();
      if (success) {
        // Update all notifications to read
        for (var i = 0; i < _notifications.length; i++) {
          _notifications[i] = AppNotification(
            id: _notifications[i].id,
            userId: _notifications[i].userId,
            type: _notifications[i].type,
            title: _notifications[i].title,
            message: _notifications[i].message,
            tradeChatId: _notifications[i].tradeChatId,
            offerId: _notifications[i].offerId,
            productId: _notifications[i].productId,
            serviceId: _notifications[i].serviceId,
            actorId: _notifications[i].actorId,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: _notifications[i].createdAt,
            deepLinkPath: _notifications[i].deepLinkPath,
          );
        }
        _unreadCount = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Delete notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final success = await _service.deleteNotification(notificationId);
      if (success) {
        _notifications.removeWhere((n) => n.id == notificationId);
        await loadUnreadCount();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Clear all notifications
  Future<bool> clearAllNotifications() async {
    try {
      final success = await _service.deleteAllNotifications();
      if (success) {
        _notifications.clear();
        _unreadCount = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Load preferences
  Future<void> loadPreferences() async {
    _isLoading = true;
    notifyListeners();

    try {
      _preferences = await _service.getPreferences();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update preference locally
  void updatePreference(NotificationPreferences updatedPrefs) {
    _preferences = updatedPrefs;
    notifyListeners();
  }

  // Save preferences to server
  Future<bool> updatePreferences() async {
    if (_preferences == null) return false;

    try {
      _preferences = await _service.updatePreferences(_preferences!);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Batch delete notifications
  Future<bool> batchDeleteNotifications(List<String> ids) async {
    try {
      final success = await _service.batchDeleteNotifications(ids);
      if (success) {
        _notifications.removeWhere((n) => ids.contains(n.id));
        await loadUnreadCount();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
