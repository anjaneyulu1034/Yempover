// lib/utils/chat_provider.dart
import 'package:flutter/material.dart';
import '../services/trade_chat_service/trade_chat_service.dart';

/// Aggregate unread trade-chat message count, for a persistent badge (nav
/// bar, profile icon) that stays accurate without loading every chat list
/// page — mirrors NotificationProvider's pattern for the same reason.
class ChatProvider extends ChangeNotifier {
  final TradeChatService _service = TradeChatService();

  int _unreadCount = 0;
  bool _isLoading = false;

  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  Future<void> loadUnreadCount() async {
    _isLoading = true;
    try {
      _unreadCount = await _service.getUnreadMessageCount();
    } catch (e) {
      debugPrint('🔴 Error loading trade-chat unread count: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _unreadCount = 0;
    _isLoading = false;
    notifyListeners();
  }
}
