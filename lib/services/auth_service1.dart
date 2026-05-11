// lib/services/auth_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';
import '../models/user_profile.dart';
import '../models/api_response.dart';

class AuthService extends ChangeNotifier {
  UserProfile? _currentUser;
  String? _token;
  bool _isLoading = false;
  String? _error;

  // ✅ All getters properly defined
  UserProfile? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  AuthService() {
    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_profile');

      if (token != null) {
        _token = token;
        if (userJson != null) {
          _currentUser = UserProfile.fromJson(json.decode(userJson));
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading stored user: $e');
    }
  }

  Future<void> saveAuthData(String token, UserProfile user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      await prefs.setString('user_profile', json.encode(user.toJson()));

      _token = token;
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving auth data: $e');
    }
  }

  Future<ApiResponse<UserProfile>> getProfile() async {
    _setLoading(true);
    _clearError();

    try {
      if (_token == null) {
        throw Exception('No authentication token');
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/me'),
        headers: {...ApiConstants.headers, 'Authorization': 'Bearer $_token'},
      );

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        final apiResponse = ApiResponse<UserProfile>.fromJson(
          jsonResponse,
          (data) => UserProfile.fromJson(data),
        );

        if (apiResponse.isSuccess && apiResponse.data != null) {
          _currentUser = apiResponse.data;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'user_profile',
            json.encode(_currentUser!.toJson()),
          );

          notifyListeners();
          return apiResponse;
        } else {
          throw Exception(apiResponse.message);
        }
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      _setError(e.toString());
      return ApiResponse<UserProfile>(
        status: 'error',
        message: e.toString(),
        data: null,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_profile');

      _token = null;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
