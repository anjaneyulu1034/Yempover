import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/models/get_current_subscription_plan_response.dart';
import 'package:yempover_app/models/get_subscription_plans_response.dart';
import 'package:yempover_app/models/get_my_profile_response.dart';
import 'package:yempover_app/services/my_profile_service.dart';
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

      // Source subscription from profile payload to avoid an extra network call.
      final profileResponse = await MyProfileService().getMyProfile();
      final profile = profileResponse.data;

      if (profile == null) {
        return GetCurrentSubscriptionPlanResponse(
          status: 'success',
          message: 'No active subscription',
          data: null,
        );
      }

      final hasSubscription =
          (profile.subscriptionPlanId?.trim().isNotEmpty ?? false) ||
          profile.subscriptionPlan != null ||
          (profile.subscriptionEndDate?.trim().isNotEmpty ?? false);

      if (!hasSubscription) {
        return GetCurrentSubscriptionPlanResponse(
          status: 'success',
          message: 'No active subscription',
          data: null,
        );
      }

      final planDetails = _extractPlanDetailsFromProfile(profile);
      final hasPlanDetails =
          planDetails.id?.isNotEmpty == true ||
          planDetails.name?.isNotEmpty == true;
      final startDate = _extractSubscriptionDate(profile, isStart: true);
      final endDate = _extractSubscriptionDate(profile, isStart: false);

      debugPrint(
        '📅 Subscription dates resolved from profile - start: $startDate, end: $endDate',
      );

      return GetCurrentSubscriptionPlanResponse(
        status: 'success',
        message: 'Current subscription fetched from profile',
        data: CurrentPlan(
          plan: hasPlanDetails ? planDetails : null,
          startDate: startDate,
          endDate: endDate,
          isValid: _isSubscriptionActive(endDate),
          isFirstTimeFree: false,
        ),
      );
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

  PlanDetails _extractPlanDetailsFromProfile(ProfileData profile) {
    final rawPlan = profile.subscriptionPlan;

    if (rawPlan is Map<String, dynamic>) {
      return PlanDetails.fromJson(rawPlan);
    }

    return PlanDetails(
      id: profile.subscriptionPlanId,
      name: _extractPlanName(rawPlan),
    );
  }

  String? _extractPlanName(dynamic rawPlan) {
    if (rawPlan is String && rawPlan.trim().isNotEmpty) {
      return rawPlan.trim();
    }
    return null;
  }

  String? _extractSubscriptionDate(
    ProfileData profile, {
    required bool isStart,
  }) {
    final topLevel = isStart
        ? profile.subscriptionStartDate
        : profile.subscriptionEndDate;
    if (topLevel != null && topLevel.trim().isNotEmpty) {
      return topLevel;
    }

    final rawPlan = profile.subscriptionPlan;
    if (rawPlan is! Map<String, dynamic>) {
      return null;
    }

    final keys = isStart
        ? const ['startDate', 'subscriptionStartDate', 'startsAt', 'validFrom']
        : const ['endDate', 'subscriptionEndDate', 'expiresAt', 'validUntil'];

    for (final key in keys) {
      final value = rawPlan[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    final nestedCandidates = [
      rawPlan['subscription'],
      rawPlan['currentSubscription'],
      rawPlan['activeSubscription'],
      rawPlan['plan'],
    ];

    for (final nested in nestedCandidates) {
      if (nested is! Map<String, dynamic>) continue;
      for (final key in keys) {
        final value = nested[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  bool _isSubscriptionActive(String? endDate) {
    if (endDate == null || endDate.trim().isEmpty) {
      return false;
    }

    try {
      return DateTime.parse(endDate).isAfter(DateTime.now());
    } catch (_) {
      return true;
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
