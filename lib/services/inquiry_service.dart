import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/services/api_service.dart';
import 'package:YemPover_app/utils/error_message_utils.dart';

class InquiryService {
  static const String sourcePlatformMobile = 'MOBILE_APP';

  static final InquiryService _instance = InquiryService._internal();
  factory InquiryService() => _instance;
  InquiryService._internal();

  final ApiService _apiService = ApiService();

  Future<void> submitInquiry({
    required String message,
    String? name,
    String? email,
    String? phoneNumber,
  }) async {
    final trimmedMessage = message.trim();
    if (trimmedMessage.isEmpty) {
      throw Exception('Message is required');
    }

    final body = <String, dynamic>{
      'message': trimmedMessage,
      'sourcePlatform': sourcePlatformMobile,
    };

    final trimmedName = name?.trim();
    final trimmedEmail = email?.trim();
    final trimmedPhone = phoneNumber?.trim();

    if (trimmedName != null && trimmedName.isNotEmpty) {
      body['name'] = trimmedName;
    }
    if (trimmedEmail != null && trimmedEmail.isNotEmpty) {
      body['email'] = trimmedEmail;
    }
    if (trimmedPhone != null && trimmedPhone.isNotEmpty) {
      body['phoneNumber'] = trimmedPhone;
    }

    debugPrint('📨 InquiryService: Submitting inquiry');

    final response = await _apiService.post(
      ApiConstants.inquiries,
      body: body,
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      debugPrint('✅ InquiryService: Inquiry submitted successfully');
      return;
    }

    String errorMessage = 'Failed to submit inquiry';
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded['message'] != null) {
        errorMessage = decoded['message'].toString();
      }
    } catch (_) {}

    throw ApiException(
      ErrorMessageUtils.sanitize(errorMessage),
      statusCode: response.statusCode,
    );
  }
}
