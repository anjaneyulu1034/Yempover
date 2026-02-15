import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempower_app/models/get_current_subscription_plan_response.dart';
import 'package:yempower_app/models/get_my_profile_response.dart';
import 'package:yempower_app/models/get_subscription_plans_response.dart';
import 'package:yempower_app/services/token_service.dart';
import 'package:yempower_app/constants/api_constants.dart';

class SubscriptionPlanService {
  static final SubscriptionPlanService _instance =
      SubscriptionPlanService._internal();
  factory SubscriptionPlanService() => _instance;
  SubscriptionPlanService._internal();

  final http.Client _client = http.Client();

  Future<GetSubscriptionPlansResponse> getSubscriptionPlans() async {
    try {
      final url = '${ApiConstants.baseUrl}/subscription-plans';

      final response = await _client
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));
      debugPrint(" subscription url ${url}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return GetSubscriptionPlansResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load subscription plans');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _getToken() async {
    final token = await TokenService().getToken();
    debugPrint(
      '🔑 MyProfileService: Token retrieved: ${token != null ? 'Yes (${token.substring(0, min(20, token.length))}...)' : 'No'}',
    );
    return token;
  }

  Future<GetCurrentSubscriptionPlanResponse> getCurrentSubscriptionPlan() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint(
          '🔴 current subscription service: No authentication token found',
        );
        throw Exception('No authentication token found. Please login again.');
      }
      final url = '${ApiConstants.baseUrl}/subscription';

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
      debugPrint("current subscription url ${url}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        return GetCurrentSubscriptionPlanResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load subscription plans');
      }
    } catch (e) {
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}

int min(int a, int b) => a < b ? a : b;
