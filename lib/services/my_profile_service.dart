import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/models/get_my_profile_response.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/constants/api_constants.dart';

class MyProfileService {
  static final MyProfileService _instance = MyProfileService._internal();
  factory MyProfileService() => _instance;
  MyProfileService._internal();

  final http.Client _client = http.Client();

  Future<String?> _getToken() async {
    final token = await TokenService().getToken();
    debugPrint(
      '🔑 MyProfileService: Token retrieved: ${token != null ? 'Yes (${token.substring(0, min(20, token.length))}...)' : 'No'}',
    );
    return token;
  }

  Future<GetMyProfileResponse> getMyProfile({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint('🔴 MyProfileService: No authentication token found');
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '${ApiConstants.baseUrl}/me';
      debugPrint('🌐 MyProfileService: Fetching my profile $url');

      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📨 MyProfileService: Response status: ${response.statusCode}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint(
          '✅ MyProfileService: profile fetched successfully ${jsonEncode(jsonResponse)}',
        );
        return GetMyProfileResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        debugPrint(
          '🔴 MyProfileService: Unauthorized - Token expired or invalid',
        );
        // Clear invalid token
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 MyProfileService: Error fetching my profile: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

int min(int a, int b) => a < b ? a : b;
