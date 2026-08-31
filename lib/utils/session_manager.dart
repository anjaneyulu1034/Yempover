import 'package:flutter/material.dart';
import 'package:yempover_app/main.dart' as app;
import 'package:yempover_app/screens/LoginScreen.dart';
import 'package:yempover_app/services/profile_session_manager.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/utils/blocked_users_cache.dart';

/// Central "the session is genuinely gone, log out now" action — clears
/// local auth state and drops the user back at LoginScreen from anywhere in
/// the app via the root navigator (no BuildContext required). Used when a
/// 401's error code says the token/account is actually invalid (as opposed
/// to just expired, which the API layer silently refreshes instead).
class SessionManager {
  SessionManager._();

  static bool _loggingOut = false;

  static Future<void> forceLogout() async {
    if (_loggingOut) return;
    _loggingOut = true;
    try {
      await TokenService().clearTokens();
      ProfileSessionManager.instance.clearSession();
      BlockedUsersCache.instance.reset();
      app.rootNavigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } finally {
      _loggingOut = false;
    }
  }
}
