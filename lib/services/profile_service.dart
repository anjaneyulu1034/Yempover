// lib/services/profile_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:Yempover_app/models/get_my_profile_response.dart';
import 'package:Yempover_app/models/profile_update_request.dart';
import 'package:Yempover_app/services/profile_session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  // Method to get token - you can modify this based on where you store tokens
  Future<String?> _getToken() async {
    // Option 1: Using SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token'); // Adjust key as needed
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }

    // Option 2: If you're using a different storage method, implement here
    // Option 3: If token is stored in memory, you might have a AuthService class
  }

  Future<ProfileData> updateProfile(ProfileUpdateRequest request) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      debugPrint(
        'Updating profile with data: ${request.toJson()}',
      ); // For debugging

      final response = await http.put(
        Uri.parse(ApiConstants.me),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(request.toJson()),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}'); // For debugging

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          final userData = jsonResponse['data']['user'];
          final updatedProfile = ProfileData.fromJson(userData);

          // Update the session with new profile data
          ProfileSessionManager.instance.updateFromResponse(updatedProfile);

          return updatedProfile;
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Failed to update profile',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error updating profile: $e'); // For debugging
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  Future<ProfileData> fetchProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await http.get(
        Uri.parse(ApiConstants.me),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          final userData = jsonResponse['data']['user'];
          final profile = ProfileData.fromJson(userData);

          // Update session with fetched profile
          ProfileSessionManager.instance.updateFromResponse(profile);

          return profile;
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to fetch profile');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      throw Exception('Failed to fetch profile: ${e.toString()}');
    }
  }

  // Optional: Method to save token after login
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Optional: Method to clear token on logout
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }
}
