import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _userIdKey = 'user_id';

  // Save token after successful login
  Future<void> saveTokens({
    required String token,
    String? refreshToken,
    String? userId,
    Map<String, dynamic>? userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    debugPrint('🔐 TokenService: Token saved: ${token.substring(0, 20)}...');

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

  // Get token for API calls
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    debugPrint('🔐 TokenService: Getting token - exists: ${token != null}');
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
    final userId = prefs.getString(_userIdKey);
    debugPrint('🔐 TokenService: Getting userId: $userId');
    return userId;
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

  // Clear tokens on logout
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_userIdKey);

    debugPrint('🔐 TokenService: All tokens cleared');
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final userId = await getUserId();
    final isLoggedIn =
        token != null &&
        token.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty;
    debugPrint(
      '🔐 TokenService: isLoggedIn check - Token exists: ${token != null}, UserId exists: ${userId != null}, Result: $isLoggedIn',
    );
    return isLoggedIn;
  }
}
