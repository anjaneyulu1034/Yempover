// lib/models/user_profile.dart
class UserProfile {
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

  UserProfile({
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

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      profileImage: json['profileImage'],
      homeAddress: json['homeAddress'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      registrationDate: json['registrationDate'] != null
          ? DateTime.parse(json['registrationDate'])
          : DateTime.now(),
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

  String get fullName => '$firstName $lastName';

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}'.toUpperCase();
    } else if (firstName.isNotEmpty) {
      return firstName[0].toUpperCase();
    } else if (lastName.isNotEmpty) {
      return lastName[0].toUpperCase();
    }
    return 'U';
  }

  String get formattedRegistrationDate {
    final now = DateTime.now();
    final difference = now.difference(registrationDate);

    if (difference.inDays < 1) {
      return 'Today';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
