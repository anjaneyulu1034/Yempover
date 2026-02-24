// lib/models/notification_model.dart
import 'package:intl/intl.dart';

enum NotificationType {
  OFFER_RECEIVED,
  OFFER_ACCEPTED,
  OFFER_REJECTED,
  OFFER_COUNTERED,
  OFFER_WITHDRAWN,
  MESSAGE_RECEIVED,
  DEAL_COMPLETED,
  DEAL_CANCELLED,
  TRADE_COMPLETED,
  POST_LIKED,
  POST_COMMENTED,
  POST_DELETED,
  SUBSCRIPTION_REMINDER,
  SUBSCRIPTION_EXPIRED,
  SUBSCRIPTION_ACTIVATED,
  PROMOTIONAL,
  SYSTEM_ALERT,
  BLOCK_NOTIFICATION,
  WISHLIST_MATCH,
  REVIEW_RECEIVED,
  PAYMENT_RECEIVED,
  REFUND_PROCESSED;

  static NotificationType fromString(String type) {
    switch (type) {
      case 'OFFER_RECEIVED':
        return NotificationType.OFFER_RECEIVED;
      case 'OFFER_ACCEPTED':
        return NotificationType.OFFER_ACCEPTED;
      case 'OFFER_REJECTED':
        return NotificationType.OFFER_REJECTED;
      case 'OFFER_COUNTERED':
        return NotificationType.OFFER_COUNTERED;
      case 'OFFER_WITHDRAWN':
        return NotificationType.OFFER_WITHDRAWN;
      case 'MESSAGE_RECEIVED':
        return NotificationType.MESSAGE_RECEIVED;
      case 'DEAL_COMPLETED':
        return NotificationType.DEAL_COMPLETED;
      case 'DEAL_CANCELLED':
        return NotificationType.DEAL_CANCELLED;
      case 'TRADE_COMPLETED':
        return NotificationType.TRADE_COMPLETED;
      case 'POST_LIKED':
        return NotificationType.POST_LIKED;
      case 'POST_COMMENTED':
        return NotificationType.POST_COMMENTED;
      case 'POST_DELETED':
        return NotificationType.POST_DELETED;
      case 'SUBSCRIPTION_REMINDER':
        return NotificationType.SUBSCRIPTION_REMINDER;
      case 'SUBSCRIPTION_EXPIRED':
        return NotificationType.SUBSCRIPTION_EXPIRED;
      case 'SUBSCRIPTION_ACTIVATED':
        return NotificationType.SUBSCRIPTION_ACTIVATED;
      case 'PROMOTIONAL':
        return NotificationType.PROMOTIONAL;
      case 'SYSTEM_ALERT':
        return NotificationType.SYSTEM_ALERT;
      case 'BLOCK_NOTIFICATION':
        return NotificationType.BLOCK_NOTIFICATION;
      case 'WISHLIST_MATCH':
        return NotificationType.WISHLIST_MATCH;
      case 'REVIEW_RECEIVED':
        return NotificationType.REVIEW_RECEIVED;
      case 'PAYMENT_RECEIVED':
        return NotificationType.PAYMENT_RECEIVED;
      case 'REFUND_PROCESSED':
        return NotificationType.REFUND_PROCESSED;
      default:
        return NotificationType.SYSTEM_ALERT;
    }
  }
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final String? tradeChatId;
  final String? offerId;
  final String? productId;
  final String? serviceId;
  final String? actorId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? deepLinkPath;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.tradeChatId,
    this.offerId,
    this.productId,
    this.serviceId,
    this.actorId,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.deepLinkPath,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      type: NotificationType.fromString(json['type'] ?? 'SYSTEM_ALERT'),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      tradeChatId: json['tradeChatId'],
      offerId: json['offerId'],
      productId: json['productId'],
      serviceId: json['serviceId'],
      actorId: json['actorId'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      deepLinkPath: json['deepLinkPath'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'message': message,
      'tradeChatId': tradeChatId,
      'offerId': offerId,
      'productId': productId,
      'serviceId': serviceId,
      'actorId': actorId,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'deepLinkPath': deepLinkPath,
    };
  }

  // Helper method to get formatted date
  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd').format(createdAt);
    }
  }

  // Helper method to check if notification is actionable
  bool get isActionable {
    return tradeChatId != null ||
        offerId != null ||
        productId != null ||
        serviceId != null;
  }

  // Helper method to get navigation route based on deepLinkPath
  String? get navigationRoute {
    if (deepLinkPath != null && deepLinkPath!.isNotEmpty) {
      return deepLinkPath;
    }

    // Fallback based on notification type
    switch (type) {
      case NotificationType.OFFER_RECEIVED:
      case NotificationType.OFFER_ACCEPTED:
      case NotificationType.OFFER_REJECTED:
      case NotificationType.OFFER_COUNTERED:
      case NotificationType.OFFER_WITHDRAWN:
      case NotificationType.MESSAGE_RECEIVED:
      case NotificationType.DEAL_COMPLETED:
      case NotificationType.DEAL_CANCELLED:
      case NotificationType.TRADE_COMPLETED:
        if (tradeChatId != null) {
          return '/trade-chat/$tradeChatId';
        }
        break;
      case NotificationType.POST_LIKED:
      case NotificationType.POST_COMMENTED:
      case NotificationType.POST_DELETED:
        if (productId != null) {
          return '/product/$productId';
        } else if (serviceId != null) {
          return '/service/$serviceId';
        }
        break;
      case NotificationType.SUBSCRIPTION_REMINDER:
      case NotificationType.SUBSCRIPTION_EXPIRED:
      case NotificationType.SUBSCRIPTION_ACTIVATED:
        return '/subscription';
      case NotificationType.PROMOTIONAL:
        return '/promotions';
      case NotificationType.WISHLIST_MATCH:
        return '/wishlist';
      case NotificationType.REVIEW_RECEIVED:
        return '/reviews';
      case NotificationType.PAYMENT_RECEIVED:
      case NotificationType.REFUND_PROCESSED:
        return '/wallet';
      default:
        return null;
    }
    return null;
  }
}

class NotificationResponse {
  final String status;
  final String message;
  final NotificationData data;

  NotificationResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: NotificationData.fromJson(json['data'] ?? {}),
    );
  }
}

class NotificationData {
  final List<AppNotification> notifications;
  final Pagination pagination;
  final int unreadCount;

  NotificationData({
    required this.notifications,
    required this.pagination,
    required this.unreadCount,
  });

  factory NotificationData.fromJson(Map<String, dynamic> json) {
    var notificationList = <AppNotification>[];
    if (json['notifications'] != null) {
      notificationList = (json['notifications'] as List)
          .map((item) => AppNotification.fromJson(item))
          .toList();
    }

    return NotificationData(
      notifications: notificationList,
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
      unreadCount: json['unreadCount'] ?? 0,
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }

  bool get hasNextPage => page < pages;
  bool get hasPreviousPage => page > 1;
}
