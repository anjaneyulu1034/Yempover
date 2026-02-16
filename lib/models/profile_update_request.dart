// lib/models/profile_update_request.dart
class ProfileUpdateRequest {
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? homeAddress;
  final bool? shareEmail;
  final bool? sharePhone;
  final bool? notificationEnabled;

  ProfileUpdateRequest({
    this.firstName,
    this.lastName,
    this.email,
    this.homeAddress,
    this.shareEmail,
    this.sharePhone,
    this.notificationEnabled,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (firstName != null && firstName!.isNotEmpty) {
      data['firstName'] = firstName;
    }
    if (lastName != null && lastName!.isNotEmpty) {
      data['lastName'] = lastName;
    }
    if (email != null && email!.isNotEmpty) {
      data['email'] = email;
    }
    if (homeAddress != null && homeAddress!.isNotEmpty) {
      data['homeAddress'] = homeAddress;
    }
    if (shareEmail != null) {
      data['shareEmail'] = shareEmail;
    }
    if (sharePhone != null) {
      data['sharePhone'] = sharePhone;
    }
    if (notificationEnabled != null) {
      data['notificationEnabled'] = notificationEnabled;
    }

    return data;
  }
}
