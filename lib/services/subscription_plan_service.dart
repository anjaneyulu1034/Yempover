import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/models/get_current_subscription_plan_response.dart';
import 'package:yempover_app/models/get_subscription_plans_response.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/constants/api_constants.dart';

class SubscriptionPlanService {
  static final SubscriptionPlanService _instance =
      SubscriptionPlanService._internal();
  factory SubscriptionPlanService() => _instance;
  SubscriptionPlanService._internal();

  final http.Client _client = http.Client();

  Future<String?> _getToken() async {
    final token = await TokenService().getToken();
    debugPrint(
      '🔑 Token retrieved: ${token != null ? 'Yes (${token.substring(0, token.length > 20 ? 20 : token.length)}...)' : 'No'}',
    );
    return token;
  }

  Future<GetSubscriptionPlansResponse> getSubscriptionPlans() async {
    try {
      final token = await _getToken();
      final url = ApiConstants.subscriptionPlans;

      debugPrint('📡 Fetching subscription plans from: $url');

      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      // Add token if available
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final response = await _client
          .get(Uri.parse(url), headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return GetSubscriptionPlansResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Failed to load subscription plans (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching subscription plans: $e');
      rethrow;
    }
  }

  Future<GetCurrentSubscriptionPlanResponse>
  getCurrentSubscriptionPlan() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint('🔴 No authentication token found');
        throw Exception('No authentication token found. Please login again.');
      }

      // Try different possible endpoints
      final endpoints = [
        ApiConstants.currentSubscription, // /subscription/current
        '${ApiConstants.baseUrl}/subscription', // /subscription
        '${ApiConstants.baseUrl}/me/subscription', // /me/subscription
      ];

      for (final url in endpoints) {
        try {
          debugPrint('📡 Trying current subscription endpoint: $url');

          final response = await _client
              .get(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(const Duration(seconds: 10));

          debugPrint('📡 Endpoint $url - Status: ${response.statusCode}');

          if (response.statusCode == 200) {
            final Map<String, dynamic> jsonResponse = json.decode(
              response.body,
            );
            return GetCurrentSubscriptionPlanResponse.fromJson(jsonResponse);
          } else if (response.statusCode == 404) {
            // Try next endpoint
            continue;
          } else if (response.statusCode == 401) {
            await TokenService().clearTokens();
            throw Exception('Session expired. Please login again.');
          }
        } catch (e) {
          debugPrint('❌ Error with endpoint $url: $e');
          // Continue to next endpoint
          continue;
        }
      }

      // If all endpoints fail, return empty response (no active subscription)
      return GetCurrentSubscriptionPlanResponse(
        status: 'success',
        message: 'No active subscription',
        data: null,
      );
    } catch (e) {
      debugPrint('❌ Error fetching current subscription: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

int min(int a, int b) => a < b ? a : b;
