import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempower_app/models/ProductPostmain.dart';
import 'package:yempower_app/screens/Home_screen.dart' hide AppNotification;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required List<AppNotification> notifications,
    required void Function(AppNotification notification) onNotificationTap,
  });

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      type: 'message',
      title: 'New Message',
      message: 'Andrew Danny sent you a new message regarding Television',
      date: DateTime.now().subtract(const Duration(minutes: 30)),
      read: false,
      action: 'view_chat',
    ),
    NotificationItem(
      id: '2',
      type: 'subscription',
      title: 'Subscription Reminder',
      message:
          'Your subscription will expire in 3 days. Renew now to continue enjoying premium features.',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      read: false,
      action: 'subscribe',
    ),
    NotificationItem(
      id: '3',
      type: 'like',
      title: 'Post Liked',
      message: 'Sarah Johnson liked your post "iPhone 13 Pro"',
      date: DateTime.now().subtract(const Duration(hours: 5)),
      read: true,
      action: 'view_post',
    ),
    NotificationItem(
      id: '4',
      type: 'wishlist',
      title: 'Wishlist Match',
      message: 'New product matching your wishlist: Gaming Laptop',
      date: DateTime.now().subtract(const Duration(days: 1)),
      read: true,
      action: 'view_product',
    ),
    NotificationItem(
      id: '5',
      type: 'deal_completed',
      title: 'Deal Completed',
      message: 'Your trade for "Books" has been successfully completed',
      date: DateTime.now().subtract(const Duration(days: 2)),
      read: true,
      action: 'view_trade',
    ),
    NotificationItem(
      id: '6',
      type: 'offer_accepted',
      title: 'Offer Accepted',
      message: 'Your offer for "Sofa" has been accepted by Melia K',
      date: DateTime.now().subtract(const Duration(days: 3)),
      read: true,
      action: 'view_chat',
    ),
    NotificationItem(
      id: '7',
      type: 'subscription_expired',
      title: 'Subscription Expired',
      message:
          'Your subscription has expired. Subscribe now to regain access to all features.',
      date: DateTime.now().subtract(const Duration(days: 5)),
      read: true,
      action: 'subscribe',
    ),
    NotificationItem(
      id: '8',
      type: 'post_deleted',
      title: 'Post Removed',
      message: 'Your reported post has been reviewed and removed by our team',
      date: DateTime.now().subtract(const Duration(days: 7)),
      read: true,
      action: null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.checklist),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Notification Statistics
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_notifications.where((n) => !n.read).length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Unread',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_notifications.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Clear All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No notifications',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'You\'re all caught up!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(0),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return _buildNotificationItem(notification);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    return Container(
      decoration: BoxDecoration(
        color: notification.read ? Colors.white : Colors.blue.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        onTap: () => _handleNotificationTap(notification),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            size: 20,
            color: Colors.white,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: notification.read ? Colors.black87 : Colors.blue,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              notification.message,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            _formatNotificationDate(notification.date),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!notification.read)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            if (notification.action != null)
              Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'subscription':
        return Icons.payment;
      case 'like':
        return Icons.favorite;
      case 'wishlist':
        return Icons.card_giftcard;
      case 'deal_completed':
        return Icons.check_circle;
      case 'offer_accepted':
        return Icons.thumb_up;
      case 'subscription_expired':
        return Icons.warning;
      case 'post_deleted':
        return Icons.delete;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'subscription':
        return Colors.orange;
      case 'like':
        return Colors.red;
      case 'wishlist':
        return Colors.green;
      case 'deal_completed':
        return Colors.purple;
      case 'offer_accepted':
        return Colors.teal;
      case 'subscription_expired':
        return Colors.amber;
      case 'post_deleted':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  void _handleNotificationTap(NotificationItem notification) {
    // Mark as read
    setState(() {
      notification.read = true;
    });

    // Handle action
    switch (notification.action) {
      case 'view_chat':
        // Navigate to chat
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to chat: ${notification.message}'),
            backgroundColor: Colors.blue,
          ),
        );
        break;
      case 'subscribe':
        // Navigate to subscription screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Redirecting to subscription...'),
            backgroundColor: Colors.orange,
          ),
        );
        break;
      case 'view_post':
        // Navigate to post
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening post: ${notification.message}'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'view_product':
        // Navigate to product
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening product: ${notification.message}'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'view_trade':
        // Navigate to trade
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening trade: ${notification.message}'),
            backgroundColor: Colors.purple,
          ),
        );
        break;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _notifications) {
        notification.read = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _notifications.clear();
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  String id;
  String type;
  String title;
  String message;
  DateTime date;
  bool read;
  String? action;

  NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    required this.read,
    this.action,
  });
}
