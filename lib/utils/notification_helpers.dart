// lib/utils/notification_helpers.dart
import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationHelpers {
  static IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.OFFER_RECEIVED:
      case NotificationType.OFFER_ACCEPTED:
      case NotificationType.OFFER_REJECTED:
      case NotificationType.OFFER_COUNTERED:
      case NotificationType.OFFER_WITHDRAWN:
        return Icons.local_offer;
      case NotificationType.MESSAGE_RECEIVED:
        return Icons.message;
      case NotificationType.DEAL_COMPLETED:
      case NotificationType.TRADE_COMPLETED:
        return Icons.check_circle;
      case NotificationType.DEAL_CANCELLED:
        return Icons.cancel;
      case NotificationType.POST_LIKED:
        return Icons.favorite;
      case NotificationType.POST_COMMENTED:
        return Icons.comment;
      case NotificationType.POST_DELETED:
        return Icons.delete;
      case NotificationType.SUBSCRIPTION_REMINDER:
        return Icons.payment;
      case NotificationType.SUBSCRIPTION_EXPIRED:
        return Icons.warning;
      case NotificationType.SUBSCRIPTION_ACTIVATED:
        return Icons.verified;
      case NotificationType.PROMOTIONAL:
        return Icons.campaign;
      case NotificationType.SYSTEM_ALERT:
        return Icons.notifications;
      case NotificationType.BLOCK_NOTIFICATION:
        return Icons.block;
      case NotificationType.WISHLIST_MATCH:
        return Icons.card_giftcard;
      case NotificationType.REVIEW_RECEIVED:
        return Icons.star;
      case NotificationType.PAYMENT_RECEIVED:
        return Icons.payment;
      case NotificationType.REFUND_PROCESSED:
        return Icons.refresh;
      default:
        return Icons.notifications;
    }
  }

  static Color getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.OFFER_RECEIVED:
      case NotificationType.OFFER_ACCEPTED:
        return Colors.green;
      case NotificationType.OFFER_REJECTED:
      case NotificationType.OFFER_WITHDRAWN:
        return Colors.red;
      case NotificationType.OFFER_COUNTERED:
        return Colors.orange;
      case NotificationType.MESSAGE_RECEIVED:
        return Colors.blue;
      case NotificationType.DEAL_COMPLETED:
      case NotificationType.TRADE_COMPLETED:
        return Colors.purple;
      case NotificationType.DEAL_CANCELLED:
        return Colors.red.shade700;
      case NotificationType.POST_LIKED:
        return Colors.pink;
      case NotificationType.POST_COMMENTED:
        return Colors.teal;
      case NotificationType.POST_DELETED:
        return Colors.grey;
      case NotificationType.SUBSCRIPTION_REMINDER:
      case NotificationType.SUBSCRIPTION_EXPIRED:
        return Colors.amber;
      case NotificationType.SUBSCRIPTION_ACTIVATED:
        return Colors.lightGreen;
      case NotificationType.PROMOTIONAL:
        return Colors.indigo;
      case NotificationType.SYSTEM_ALERT:
        return Colors.blueGrey;
      case NotificationType.BLOCK_NOTIFICATION:
        return Colors.deepOrange;
      case NotificationType.WISHLIST_MATCH:
        return Colors.cyan;
      case NotificationType.REVIEW_RECEIVED:
        return Colors.amber.shade700;
      case NotificationType.PAYMENT_RECEIVED:
        return Colors.green.shade800;
      case NotificationType.REFUND_PROCESSED:
        return Colors.blue.shade800;
      default:
        return Colors.blue;
    }
  }

  static String getNotificationTitle(NotificationType type) {
    switch (type) {
      case NotificationType.OFFER_RECEIVED:
        return 'New Offer Received';
      case NotificationType.OFFER_ACCEPTED:
        return 'Offer Accepted';
      case NotificationType.OFFER_REJECTED:
        return 'Offer Rejected';
      case NotificationType.OFFER_COUNTERED:
        return 'Counter Offer';
      case NotificationType.OFFER_WITHDRAWN:
        return 'Offer Withdrawn';
      case NotificationType.MESSAGE_RECEIVED:
        return 'New Message';
      case NotificationType.DEAL_COMPLETED:
        return 'Deal Completed';
      case NotificationType.TRADE_COMPLETED:
        return 'Trade Completed';
      case NotificationType.DEAL_CANCELLED:
        return 'Deal Cancelled';
      case NotificationType.POST_LIKED:
        return 'Post Liked';
      case NotificationType.POST_COMMENTED:
        return 'New Comment';
      case NotificationType.POST_DELETED:
        return 'Post Removed';
      case NotificationType.SUBSCRIPTION_REMINDER:
        return 'Subscription Reminder';
      case NotificationType.SUBSCRIPTION_EXPIRED:
        return 'Subscription Expired';
      case NotificationType.SUBSCRIPTION_ACTIVATED:
        return 'Subscription Activated';
      case NotificationType.PROMOTIONAL:
        return 'Special Offer';
      case NotificationType.SYSTEM_ALERT:
        return 'System Alert';
      case NotificationType.BLOCK_NOTIFICATION:
        return 'User Blocked';
      case NotificationType.WISHLIST_MATCH:
        return 'Wishlist Match';
      case NotificationType.REVIEW_RECEIVED:
        return 'New Review';
      case NotificationType.PAYMENT_RECEIVED:
        return 'Payment Received';
      case NotificationType.REFUND_PROCESSED:
        return 'Refund Processed';
      default:
        return 'Notification';
    }
  }
}
