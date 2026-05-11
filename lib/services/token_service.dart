import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:YemPover_app/constants/api_constants.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _userIdKey = 'user_id';
  static const String _isGuestKey = 'is_guest_user';

  // Token refresh related fields
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshCompleters = [];

  // Save token after successful login
  Future<void> saveTokens({
    required String token,
    String? refreshToken,
    String? userId,
    Map<String, dynamic>? userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Any authenticated login should turn guest mode off.
    await prefs.setBool(_isGuestKey, false);

    await prefs.setString(_tokenKey, token);
    debugPrint('🔐 TokenService: Token saved');

    if (userId != null && userId.isNotEmpty) {
      await prefs.setString(_userIdKey, userId);
      debugPrint('🔐 TokenService: User ID saved: $userId');
    }

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await prefs.setString(_refreshTokenKey, refreshToken);
      debugPrint('🔐 TokenService: Refresh token saved');
    }

    if (userData != null) {
      await prefs.setString(_userDataKey, jsonEncode(userData));
      debugPrint('🔐 TokenService: User data saved');
    }

    debugPrint('🔐 TokenService: All tokens saved successfully');
  }

  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, isGuest);
    debugPrint('🔐 TokenService: Guest mode set to $isGuest');
  }

  Future<void> enableGuestMode() async {
    final prefs = await SharedPreferences.getInstance();

    // Ensure guest mode starts with a clean auth state.
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_userIdKey);
    await prefs.setBool(_isGuestKey, true);

    debugPrint('🔐 TokenService: Guest mode enabled');
  }

  Future<bool> isGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }

  // Get token for API calls
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    if (token == null || token.isEmpty) {
      return null;
    }

    // Auto-refresh when token is expired/near expiry so callers don't need
    // to manually handle session renewal.
    if (isTokenExpired(token)) {
      debugPrint('🔄 TokenService: Stored token is expired, refreshing...');
      return await refreshToken();
    }

    return token;
  }

  // Get refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Get userId
  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Get userData
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userDataKey);

    if (data == null || data.isEmpty) return null;

    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint("❌ TokenService: Failed to decode userData: $e");
      return null;
    }
  }

  // Clear tokens on logout - FIXED: Ensure all data is cleared properly
  Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_tokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userDataKey);
      await prefs.remove(_userIdKey);

      // Also clear any other potential user-related data
      await prefs.remove('user_profile');
      await prefs.remove('is_logged_in');
      await prefs.remove(_isGuestKey);

      debugPrint('🔐 TokenService: All tokens cleared successfully');
    } catch (e) {
      debugPrint('🔐 TokenService: Error clearing tokens: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isGuest = prefs.getBool(_isGuestKey) ?? false;
      String? token = prefs.getString(_tokenKey);
      final userId = prefs.getString(_userIdKey);

      if (token != null && token.isNotEmpty && isTokenExpired(token)) {
        debugPrint(
          '🔄 TokenService: isLoggedIn detected expired token, refreshing...',
        );
        token = await refreshToken();
      }

      final isLoggedIn =
          !isGuest &&
          token != null &&
          token.isNotEmpty &&
          userId != null &&
          userId.isNotEmpty;

      debugPrint('🔐 TokenService: isLoggedIn check - Result: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      debugPrint('🔐 TokenService: Error checking login status: $e');
      return false;
    }
  }

  // ========== TOKEN REFRESH METHODS ==========

  /// Attempts to refresh the token using the refresh token
  Future<String?> refreshToken() async {
    // If already refreshing, add to queue
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    debugPrint('🔄 TokenService: Attempting to refresh token');

    try {
      final refreshToken = await getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('🔴 TokenService: No refresh token available');
        await _handleRefreshFailure(clearStoredTokens: true);
        return null;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('🔴 TokenService: Refresh request timeout');
              throw Exception('Request timeout');
            },
          );

      debugPrint(
        '📨 TokenService: Refresh response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          final newToken = data['data']['token'];

          // Save the new token (keep the same refresh token)
          await saveTokens(
            token: newToken,
            refreshToken: refreshToken,
            userId: await getUserId(),
          );

          debugPrint('✅ TokenService: Token refreshed successfully');

          // Resolve all queued completers with new token
          _resolveAllCompleters(newToken);

          return newToken;
        } else {
          debugPrint('🔴 TokenService: Invalid response format');
          await _handleRefreshFailure(clearStoredTokens: false);
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('🔴 TokenService: Refresh token expired or invalid');
        await _handleRefreshFailure(clearStoredTokens: true);
        return null;
      } else {
        debugPrint(
          '🔴 TokenService: Refresh failed with status ${response.statusCode}',
        );
        await _handleRefreshFailure(clearStoredTokens: false);
        return null;
      }
    } catch (e) {
      debugPrint('🔴 TokenService: Error refreshing token: $e');
      await _handleRefreshFailure(clearStoredTokens: false);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Handle refresh failure - clear tokens and notify all waiting requests
  Future<void> _handleRefreshFailure({required bool clearStoredTokens}) async {
    if (clearStoredTokens) {
      await clearTokens();
    }
    _resolveAllCompleters(null);
  }

  /// Resolve all waiting completers with the new token or null on failure
  void _resolveAllCompleters(String? token) {
    for (final completer in _refreshCompleters) {
      if (!completer.isCompleted) {
        completer.complete(token);
      }
    }
    _refreshCompleters.clear();
  }

  /// Check if token needs refresh based on expiration
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];

      if (exp == null) return true;

      // Check if token expires in next 5 minutes
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final fiveMinutesFromNow = now.add(const Duration(minutes: 5));

      return expiryTime.isBefore(fiveMinutesFromNow);
    } catch (e) {
      debugPrint('🔴 TokenService: Error checking token expiry: $e');
      return true;
    }
  }

  /// Helper method to get a valid token (refreshes if expired)
  Future<String?> getValidToken() async {
    // getToken() already auto-refreshes when needed.
    return await getToken();
  }
}
