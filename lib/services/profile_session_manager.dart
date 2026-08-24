// lib/services/profile_session_manager.dart
import 'package:yempover_app/models/get_my_profile_response.dart';

class ProfileSessionManager {
  ProfileSessionManager._();
  static final ProfileSessionManager instance = ProfileSessionManager._();

  ProfileData? _profile;

  /// Getter
  ProfileData? get profile => _profile;

  bool get isLoggedIn => _profile != null;

  /// Get full name
  String get fullName {
    if (_profile == null) return '';
    return '${_profile?.firstName ?? ''} ${_profile?.lastName ?? ''}'.trim();
  }

  /// Get initials for avatar
  String get initials {
    if (_profile == null) return '';
    final first = _profile?.firstName?.isNotEmpty == true
        ? _profile!.firstName![0]
        : '';
    final last = _profile?.lastName?.isNotEmpty == true
        ? _profile!.lastName![0]
        : '';
    return '$first$last'.toUpperCase();
  }

  /// Set profile after login
  void setProfile(ProfileData? profileData) {
    _profile = profileData;
  }

  /// Update profile with partial data
  /// Update profile with partial data
  void updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? homeAddress,
    bool? shareEmail,
    bool? sharePhone,
    bool? notificationEnabled,
    String? profileImage,
  }) {
    if (_profile == null) return;

    // Create a new map with the updated values
    final updatedData = {
      'id': _profile!.id,
      'firstName': firstName ?? _profile!.firstName,
      'lastName': lastName ?? _profile!.lastName,
      'email': email ?? _profile!.email,
      'mobileNumber': _profile!.mobileNumber,
      'profileImage': profileImage ?? _profile!.profileImage,
      'homeAddress':
          homeAddress, // This can be String? which matches your Null? type
      'latitude': _profile!.latitude,
      'longitude': _profile!.longitude,
      'registrationDate': _profile!.registrationDate,
      'totalTradesCompleted': _profile!.totalTradesCompleted,
      'subscriptionPlan': _profile!.subscriptionPlan,
      'shareEmail': shareEmail ?? _profile!.shareEmail,
      'sharePhone': sharePhone ?? _profile!.sharePhone,
      'notificationEnabled':
          notificationEnabled ?? _profile!.notificationEnabled,
    };

    _profile = ProfileData.fromJson(updatedData);
  }

  /// Update profile from API response
  void updateFromResponse(ProfileData updatedProfile) {
    _profile = updatedProfile;
  }

  /// Clear on logout
  void clearSession() {
    _profile = null;
  }
}
