// lib/models/notification_preferences_model.dart
class NotificationPreferences {
  final String id;
  final String userId;
  final bool offerNotifications;
  final bool messageNotifications;
  final bool dealNotifications;
  final bool blockNotifications;
  final bool promotionalNotifications;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.id,
    required this.userId,
    required this.offerNotifications,
    required this.messageNotifications,
    required this.dealNotifications,
    required this.blockNotifications,
    required this.promotionalNotifications,
    required this.pushEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      offerNotifications: json['offerNotifications'] ?? true,
      messageNotifications: json['messageNotifications'] ?? true,
      dealNotifications: json['dealNotifications'] ?? true,
      blockNotifications: json['blockNotifications'] ?? true,
      promotionalNotifications: json['promotionalNotifications'] ?? false,
      pushEnabled: json['pushEnabled'] ?? true,
      emailEnabled: json['emailEnabled'] ?? false,
      smsEnabled: json['smsEnabled'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offerNotifications': offerNotifications,
      'messageNotifications': messageNotifications,
      'dealNotifications': dealNotifications,
      'blockNotifications': blockNotifications,
      'promotionalNotifications': promotionalNotifications,
      'pushEnabled': pushEnabled,
      'emailEnabled': emailEnabled,
      'smsEnabled': smsEnabled,
    };
  }

  NotificationPreferences copyWith({
    bool? offerNotifications,
    bool? messageNotifications,
    bool? dealNotifications,
    bool? blockNotifications,
    bool? promotionalNotifications,
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
  }) {
    return NotificationPreferences(
      id: id,
      userId: userId,
      offerNotifications: offerNotifications ?? this.offerNotifications,
      messageNotifications: messageNotifications ?? this.messageNotifications,
      dealNotifications: dealNotifications ?? this.dealNotifications,
      blockNotifications: blockNotifications ?? this.blockNotifications,
      promotionalNotifications:
          promotionalNotifications ?? this.promotionalNotifications,
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class NotificationPreferencesResponse {
  final String status;
  final String message;
  final NotificationPreferences data;

  NotificationPreferencesResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory NotificationPreferencesResponse.fromJson(Map<String, dynamic> json) {
    return NotificationPreferencesResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: NotificationPreferences.fromJson(json['data'] ?? {}),
    );
  }
}
