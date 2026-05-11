// lib/services/profile_service.dart
import 'dart:convert';
import 'package:YemPover_app/services/api_service.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/models/get_my_profile_response.dart';
import 'package:YemPover_app/models/profile_update_request.dart';
import 'package:YemPover_app/services/profile_session_manager.dart';
import 'package:YemPover_app/utils/error_message_utils.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();

  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  Map<String, dynamic> _extractUserData(Map<String, dynamic> jsonResponse) {
    final data = jsonResponse['data'];
    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      final user = dataMap['user'];

      if (user is Map) {
        return Map<String, dynamic>.from(user);
      }

      return dataMap;
    }

    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map<dynamic, dynamic>);
    }

    throw Exception('Unable to read profile details right now.');
  }

  Future<String?> _getToken() => _tokenService.getToken();

  Future<ProfileData> updateProfile(ProfileUpdateRequest request) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      debugPrint(
        'Updating profile with data: ${request.toJson()}',
      ); // For debugging

      final response = await _apiService.put(
        ApiConstants.me,
        body: request.toJson(),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}'); // For debugging

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          final userData = _extractUserData(jsonResponse);
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
      throw Exception(
        ErrorMessageUtils.sanitize(
          e,
          fallback: 'Unable to update profile right now. Please try again.',
        ),
      );
    }
  }

  Future<ProfileData> fetchProfile() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final response = await _apiService.get(ApiConstants.me);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          final userData = _extractUserData(jsonResponse);
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
      throw Exception(
        ErrorMessageUtils.sanitize(
          e,
          fallback: 'Unable to load profile right now. Please try again.',
        ),
      );
    }
  }

  Future<void> updatePrivacySettings({
    bool? shareEmail,
    bool? sharePhone,
    bool? notificationEnabled,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      final Map<String, dynamic> payload = {};
      if (shareEmail != null) payload['shareEmail'] = shareEmail;
      if (sharePhone != null) payload['sharePhone'] = sharePhone;
      if (notificationEnabled != null) {
        payload['notificationEnabled'] = notificationEnabled;
      }

      if (payload.isEmpty) {
        return;
      }

      final response = await _apiService.patch(
        ApiConstants.mePrivacy,
        body: payload,
      );

      if (response.statusCode == 200) {
        ProfileSessionManager.instance.updateProfile(
          shareEmail: shareEmail,
          sharePhone: sharePhone,
          notificationEnabled: notificationEnabled,
        );
        return;
      }

      if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      }

      throw Exception(
        'Failed to update privacy settings: ${response.statusCode}',
      );
    } catch (e) {
      debugPrint('Error updating privacy settings: $e');
      throw Exception(
        ErrorMessageUtils.sanitize(
          e,
          fallback:
              'Unable to update privacy settings right now. Please try again.',
        ),
      );
    }
  }

  // Optional: Method to save token after login
  Future<void> saveToken(String token) async {
    await _tokenService.saveTokens(token: token);
  }

  // Optional: Method to clear token on logout
  Future<void> clearToken() async {
    await _tokenService.clearTokens();
  }
}
