// lib/models/user_model.dart

class User1 {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String? profileImage;
  final String? homeAddress;
  final double? latitude;
  final double? longitude;
  final DateTime registrationDate;
  final int totalTradesCompleted;
  final String? subscriptionPlan;
  final bool shareEmail;
  final bool sharePhone;
  final bool notificationEnabled;

  User1({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.profileImage,
    this.homeAddress,
    this.latitude,
    this.longitude,
    required this.registrationDate,
    required this.totalTradesCompleted,
    this.subscriptionPlan,
    required this.shareEmail,
    required this.sharePhone,
    required this.notificationEnabled,
  });

  String get fullName => '$firstName $lastName';
  String get displayName => '$firstName $lastName';
  String get formattedRegistrationDate =>
      '${registrationDate.day}/${registrationDate.month}/${registrationDate.year}';

  factory User1.fromJson(Map<String, dynamic> json) {
    return User1(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      profileImage: json['profileImage'],
      homeAddress: json['homeAddress'],
      latitude: json['latitude'] != null
          ? double.parse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.parse(json['longitude'].toString())
          : null,
      registrationDate: DateTime.parse(
        json['registrationDate'] ?? DateTime.now().toIso8601String(),
      ),
      totalTradesCompleted: json['totalTradesCompleted'] ?? 0,
      subscriptionPlan: json['subscriptionPlan'],
      shareEmail: json['shareEmail'] ?? true,
      sharePhone: json['sharePhone'] ?? true,
      notificationEnabled: json['notificationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'profileImage': profileImage,
      'homeAddress': homeAddress,
      'latitude': latitude,
      'longitude': longitude,
      'registrationDate': registrationDate.toIso8601String(),
      'totalTradesCompleted': totalTradesCompleted,
      'subscriptionPlan': subscriptionPlan,
      'shareEmail': shareEmail,
      'sharePhone': sharePhone,
      'notificationEnabled': notificationEnabled,
    };
  }

  User1 copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? mobileNumber,
    String? profileImage,
    String? homeAddress,
    double? latitude,
    double? longitude,
    DateTime? registrationDate,
    int? totalTradesCompleted,
    String? subscriptionPlan,
    bool? shareEmail,
    bool? sharePhone,
    bool? notificationEnabled,
  }) {
    return User1(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      profileImage: profileImage ?? this.profileImage,
      homeAddress: homeAddress ?? this.homeAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      registrationDate: registrationDate ?? this.registrationDate,
      totalTradesCompleted: totalTradesCompleted ?? this.totalTradesCompleted,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      shareEmail: shareEmail ?? this.shareEmail,
      sharePhone: sharePhone ?? this.sharePhone,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}

class ProfileResponse {
  final String status;
  final String message;
  final User1 data;

  ProfileResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: User1.fromJson(json['data'] ?? {}),
    );
  }
}

class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? mobileNumber;
  final String? profileImage;
  final String? homeAddress;
  final double? latitude;
  final double? longitude;
  final bool? shareEmail;
  final bool? sharePhone;
  final bool? notificationEnabled;

  UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.mobileNumber,
    this.profileImage,
    this.homeAddress,
    this.latitude,
    this.longitude,
    this.shareEmail,
    this.sharePhone,
    this.notificationEnabled,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (firstName != null) map['firstName'] = firstName;
    if (lastName != null) map['lastName'] = lastName;
    if (email != null) map['email'] = email;
    if (mobileNumber != null) map['mobileNumber'] = mobileNumber;
    if (profileImage != null) map['profileImage'] = profileImage;
    if (homeAddress != null) map['homeAddress'] = homeAddress;
    if (latitude != null) map['latitude'] = latitude;
    if (longitude != null) map['longitude'] = longitude;
    if (shareEmail != null) map['shareEmail'] = shareEmail;
    if (sharePhone != null) map['sharePhone'] = sharePhone;
    if (notificationEnabled != null)
      map['notificationEnabled'] = notificationEnabled;
    return map;
  }
}
