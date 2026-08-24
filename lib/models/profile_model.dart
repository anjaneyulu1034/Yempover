// lib/models/profile_model.dart
class ProfileModel {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? mobileNumber;
  final String? homeAddress;
  final double? latitude;
  final double? longitude;
  final String status;
  final String role;
  final DateTime registrationDate;
  final DateTime? lastLoginDate;
  final DateTime? deletedAt;
  final DateTime? termsAcceptedAt;
  final bool shareEmail;
  final bool sharePhone;
  final bool notificationEnabled;
  final String? subscriptionPlanId;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final dynamic subscriptionPlan;
  final int? totalTradesCompleted;

  ProfileModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.mobileNumber,
    this.homeAddress,
    this.latitude,
    this.longitude,
    required this.status,
    required this.role,
    required this.registrationDate,
    this.lastLoginDate,
    this.deletedAt,
    this.termsAcceptedAt,
    required this.shareEmail,
    required this.sharePhone,
    required this.notificationEnabled,
    this.subscriptionPlanId,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    required this.createdAt,
    required this.updatedAt,
    this.subscriptionPlan,
    this.totalTradesCompleted,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      mobileNumber: json['mobileNumber'],
      homeAddress: json['homeAddress'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: json['status'] ?? 'ACTIVE',
      role: json['role'] ?? 'USER',
      registrationDate: _parseDate(json['registrationDate']) ?? DateTime.now(),
      lastLoginDate: _parseDate(json['lastLoginDate']),
      deletedAt: _parseDate(json['deletedAt']),
      termsAcceptedAt: _parseDate(json['termsAcceptedAt']),
      shareEmail: json['shareEmail'] ?? true,
      sharePhone: json['sharePhone'] ?? true,
      notificationEnabled: json['notificationEnabled'] ?? true,
      subscriptionPlanId: json['subscriptionPlanId'],
      subscriptionStartDate: _parseDate(json['subscriptionStartDate']),
      subscriptionEndDate: _parseDate(json['subscriptionEndDate']),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      subscriptionPlan: json['subscriptionPlan'],
      totalTradesCompleted: json['totalTradesCompleted'] ?? 0,
    );
  }

  static DateTime? _parseDate(dynamic date) {
    if (date == null) return null;
    try {
      return DateTime.parse(date.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
      'mobileNumber': mobileNumber,
      'homeAddress': homeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'role': role,
      'registrationDate': registrationDate.toIso8601String(),
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
      'shareEmail': shareEmail,
      'sharePhone': sharePhone,
      'notificationEnabled': notificationEnabled,
      'subscriptionPlanId': subscriptionPlanId,
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'subscriptionPlan': subscriptionPlan,
      'totalTradesCompleted': totalTradesCompleted,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? profileImage,
    String? mobileNumber,
    String? homeAddress,
    double? latitude,
    double? longitude,
    String? status,
    String? role,
    DateTime? registrationDate,
    DateTime? lastLoginDate,
    DateTime? deletedAt,
    DateTime? termsAcceptedAt,
    bool? shareEmail,
    bool? sharePhone,
    bool? notificationEnabled,
    String? subscriptionPlanId,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    dynamic subscriptionPlan,
    int? totalTradesCompleted,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileImage: profileImage ?? this.profileImage,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      homeAddress: homeAddress ?? this.homeAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      role: role ?? this.role,
      registrationDate: registrationDate ?? this.registrationDate,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      deletedAt: deletedAt ?? this.deletedAt,
      termsAcceptedAt: termsAcceptedAt ?? this.termsAcceptedAt,
      shareEmail: shareEmail ?? this.shareEmail,
      sharePhone: sharePhone ?? this.sharePhone,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      subscriptionStartDate:
          subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      totalTradesCompleted: totalTradesCompleted ?? this.totalTradesCompleted,
    );
  }
}
