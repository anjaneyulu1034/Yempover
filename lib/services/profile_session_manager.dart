import 'package:yempower_app/models/get_my_profile_response.dart';

class ProfileSessionManager {
  ProfileSessionManager._();
  static final ProfileSessionManager instance = ProfileSessionManager._();

  ProfileData? _profile;

  /// Getter
  ProfileData? get profile => _profile;

  bool get isLoggedIn => _profile != null;

  /// Set profile after login
  void setProfile(ProfileData? profileData) {
    _profile = profileData;
  }

  /// Clear on logout
  void clearSession() {
    _profile = null;
  }
}
