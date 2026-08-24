import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/content_response.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  factory ContentService() => _instance;
  ContentService._internal();

  // Don't keep a persistent client - create new ones for each request
  // or manage properly

  Future<ContentResponse> getTermsAndConditions() async {
    http.Client? client;
    try {
      client = http.Client();
      final url = ApiConstants.termsAndConditions;

      debugPrint('📡 Fetching terms and conditions from: $url');

      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Terms response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return ContentResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Failed to load terms and conditions (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching terms and conditions: $e');
      rethrow;
    } finally {
      // Always close the client
      client?.close();
    }
  }

  Future<ContentResponse> getPrivacyPolicy() async {
    http.Client? client;
    try {
      client = http.Client();
      final url = ApiConstants.privacyPolicy;

      debugPrint('📡 Fetching privacy policy from: $url');

      final response = await client
          .get(Uri.parse(url), headers: ApiConstants.headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('📡 Privacy response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return ContentResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          'Failed to load privacy policy (${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('❌ Error fetching privacy policy: $e');
      rethrow;
    } finally {
      // Always close the client
      client?.close();
    }
  }

  // Remove dispose method since we're not keeping a persistent client
  // void dispose() {
  //   _client.close();
  // }
}
