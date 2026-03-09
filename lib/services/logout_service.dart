import 'dart:convert';
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/logout_response.dart';
import '../models/logout_request.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  // Get authentication token from storage
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Get refresh token from storage
  Future<String?> _getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('refresh_token');
    } catch (e) {
      print('Error getting refresh token: $e');
      return null;
    }
  }

  // Logout API call
  Future<LogoutResponse> logout() async {
    final token = await _getToken();
    final refreshToken = await _getRefreshToken();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    try {
      final requestBody = LogoutRequest(refreshToken: refreshToken);

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/logout'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestBody.toJson()),
          )
          .timeout(const Duration(seconds: 30));

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return LogoutResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to logout');
      }
    } catch (e) {
      print('Error during logout: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  // Clear all local data after logout
  Future<void> clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all shared preferences
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
