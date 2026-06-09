import 'dart:async';
import 'dart:convert';
import 'package:yempover_app/services/token_refresh_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/get_my_profile_response.dart';
import 'package:yempover_app/services/token_service.dart';

class MyProfileService {
  static final MyProfileService _instance = MyProfileService._internal();
  factory MyProfileService() => _instance;
  MyProfileService._internal();

  // FIXED: Create new client for each request instead of reusing
  final TokenService _tokenService = TokenService();
  final TokenRefreshService _tokenRefreshService = TokenRefreshService();

  static const int _maxRetries = 1;

  Future<String?> _getToken() async {
    final token = await _tokenService.getToken();
    debugPrint(
      '🔑 MyProfileService: Token retrieved: ${token != null ? 'Yes (${token.substring(0, token.length > 20 ? 20 : token.length)}...)' : 'No'}',
    );
    return token;
  }

  /// Helper method to make authenticated requests with automatic token refresh
  Future<http.Response> _makeAuthenticatedRequest(
    Future<http.Response> Function(String token) requestFunction, {
    int retryCount = 0,
  }) async {
    // FIXED: Create a new client for each request to avoid "Client is already closed" error
    final client = http.Client();

    try {
      // Get current token
      String? token = await _tokenService.getToken();

      if (token == null) {
        debugPrint('🔴 MyProfileService: No token available');
        throw Exception('No authentication token found');
      }

      // Make the request
      var response = await requestFunction(token);

      // If unauthorized, try to refresh token and retry
      if (response.statusCode == 401 && retryCount < _maxRetries) {
        debugPrint(
          '🔄 MyProfileService: Received 401, attempting token refresh...',
        );

        // Attempt to refresh token
        final newToken = await _tokenRefreshService.refreshToken();

        if (newToken != null) {
          debugPrint(
            '✅ MyProfileService: Token refreshed, retrying request...',
          );
          // Close current client
          client.close();
          // Retry the request with new token
          return await _makeAuthenticatedRequest(
            requestFunction,
            retryCount: retryCount + 1,
          );
        } else {
          debugPrint('🔴 MyProfileService: Token refresh failed');
          // Clear tokens and throw session expired
          await _tokenService.clearTokens();
          throw Exception('Session expired. Please login again.');
        }
      }

      return response;
    } catch (e) {
      debugPrint('🔴 MyProfileService: Error in authenticated request: $e');
      rethrow;
    } finally {
      // FIXED: Always close the client
      client.close();
    }
  }

  Future<GetMyProfileResponse> getMyProfile({
    int page = 1,
    int limit = 20,
  }) async {
    // FIXED: Create new client for each request
    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint('🔴 MyProfileService: No authentication token found');
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '${ApiConstants.baseUrl}/me';
      debugPrint('🌐 MyProfileService: Fetching my profile $url');

      final response = await _makeAuthenticatedRequest((token) async {
        return await client
            .get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 30));
      });

      debugPrint(
        '📨 MyProfileService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint('✅ MyProfileService: Profile fetched successfully');
        return GetMyProfileResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        debugPrint(
          '🔴 MyProfileService: Unauthorized - Token expired or invalid',
        );
        // Clear invalid token
        await _tokenService.clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Failed to load profile: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('🔴 MyProfileService: Error fetching my profile: $e');
      rethrow;
    } finally {
      // FIXED: Always close the client
      client.close();
    }
  }

  // Update profile
  Future<GetMyProfileResponse> updateProfile(
    Map<String, dynamic> profileData,
  ) async {
    final client = http.Client();

    try {
      final url = '${ApiConstants.baseUrl}/me';
      debugPrint('🌐 MyProfileService: Updating profile');

      final response = await _makeAuthenticatedRequest((token) async {
        return await client
            .put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode(profileData),
            )
            .timeout(const Duration(seconds: 30));
      });

      debugPrint(
        '📨 MyProfileService: Update response: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return GetMyProfileResponse.fromJson(jsonResponse);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Failed to update profile: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('🔴 MyProfileService: Error updating profile: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // Upload profile image
  Future<GetMyProfileResponse> uploadProfileImage(String base64Image) async {
    final client = http.Client();

    try {
      final url = '${ApiConstants.baseUrl}/me/avatar/base64';
      debugPrint('🌐 MyProfileService: Uploading profile image');

      final response = await _makeAuthenticatedRequest((token) async {
        return await client
            .post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: jsonEncode({'avatar': base64Image}),
            )
            .timeout(const Duration(seconds: 30));
      });

      debugPrint(
        '📨 MyProfileService: Upload image response: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return GetMyProfileResponse.fromJson(jsonResponse);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Failed to upload image: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('🔴 MyProfileService: Error uploading image: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // FIXED: Remove dispose method as we're not keeping persistent client
}

// Helper function
int min(int a, int b) => a < b ? a : b;
