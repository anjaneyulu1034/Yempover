import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Yempover_app/models/get_current_subscription_plan_response.dart';
import 'package:Yempover_app/models/get_subscription_plans_response.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/constants/api_constants.dart';

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

      final url =
          ApiConstants.currentSubscription; // Now points to /me/subscription

      debugPrint('📡 Fetching current subscription from: $url');

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

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Handle the response format from your API
        if (jsonResponse['status'] == 'success') {
          // Check if data exists and has plan information
          if (jsonResponse['data'] != null &&
              jsonResponse['data']['plan'] != null) {
            return GetCurrentSubscriptionPlanResponse.fromJson(jsonResponse);
          } else {
            // No active subscription
            return GetCurrentSubscriptionPlanResponse(
              status: 'success',
              message: 'No active subscription',
              data: null,
            );
          }
        } else {
          throw Exception(
            jsonResponse['message'] ?? 'Failed to fetch subscription',
          );
        }
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        // No subscription found
        return GetCurrentSubscriptionPlanResponse(
          status: 'success',
          message: 'No active subscription',
          data: null,
        );
      } else {
        throw Exception('Failed to load subscription (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Error fetching current subscription: $e');
      // Return empty response instead of throwing
      return GetCurrentSubscriptionPlanResponse(
        status: 'error',
        message: e.toString(),
        data: null,
      );
    }
  }

  Future<Map<String, dynamic>> subscribe(String planId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = ApiConstants.subscribe;

      debugPrint('📡 Subscribing to plan: $planId at $url');

      final response = await _client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'planId': planId}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Response status: ${response.statusCode}');
      debugPrint('📡 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to subscribe (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Error subscribing: $e');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
