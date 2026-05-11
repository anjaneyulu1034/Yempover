import 'dart:convert';

import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/utils/error_message_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ServiceBookingService {
  static final ServiceBookingService _instance =
      ServiceBookingService._internal();
  factory ServiceBookingService() => _instance;
  ServiceBookingService._internal();

  final TokenService _tokenService = TokenService();

  String get _apiRoot {
    if (ApiConstants.baseUrl.endsWith('/mobile')) {
      return ApiConstants.baseUrl.substring(0, ApiConstants.baseUrl.length - 7);
    }
    return ApiConstants.baseUrl;
  }

  String get _servicesRoot => '$_apiRoot/services';

  Future<Map<String, String>> _headers({bool authRequired = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authRequired) {
      final token = await _tokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Please login to continue');
      }
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Invalid server response');
    }

    final status = body['status']?.toString().toLowerCase();
    final isSuccess =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        (status == null || status == 'success' || body['success'] == true);

    if (!isSuccess) {
      debugPrint(
        '🔴 ServiceBookingService: API failed ${response.statusCode} ${response.request?.url} body=${response.body}',
      );
    }

    if (!isSuccess) {
      final message =
          body['message']?.toString() ??
          (response.statusCode == 401 || response.statusCode == 403
              ? 'Please login to continue'
              : response.statusCode == 404
              ? 'Requested resource not found'
              : response.statusCode == 410
              ? 'Service is no longer available'
              : 'Request failed');
      throw Exception(message);
    }

    return body;
  }

  Future<Map<String, dynamic>> createService({
    required String title,
    required String description,
    required String categoryId,
    required double price,
    required String location,
    List<String> images = const [],
    String? barterStatus,
    String? status,
    String? validFrom,
    String? validUntil,
  }) async {
    final response = await http
        .post(
          Uri.parse(_servicesRoot),
          headers: await _headers(authRequired: true),
          body: jsonEncode({
            'title': title,
            'description': description,
            'categoryId': categoryId,
            // Backward compatibility for older backend parsing.
            'category': categoryId,
            'price': price,
            'location': location,
            'images': images,
            if (barterStatus != null && barterStatus.isNotEmpty)
              'barterStatus': barterStatus,
            if (status != null && status.isNotEmpty) 'status': status,
            if (validFrom != null && validFrom.isNotEmpty)
              'validFrom': validFrom,
            if (validUntil != null && validUntil.isNotEmpty)
              'validUntil': validUntil,
          }),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> setAvailability({
    required String serviceId,
    required List<Map<String, dynamic>> availabilitySlots,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_servicesRoot/$serviceId/availability'),
          headers: await _headers(authRequired: true),
          body: jsonEncode({'availabilitySlots': availabilitySlots}),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> setSpecialDate({
    required String serviceId,
    required String date,
    required bool isAvailable,
    String? reason,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_servicesRoot/$serviceId/special-date'),
          headers: await _headers(authRequired: true),
          body: jsonEncode({
            'date': date,
            'isAvailable': isAvailable,
            if (reason != null && reason.isNotEmpty) 'reason': reason,
          }),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> getServiceDetail(String serviceId) async {
    final response = await http
        .get(
          Uri.parse('$_servicesRoot/$serviceId'),
          headers: await _headers(authRequired: false),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> getAvailableSlots({
    required String serviceId,
    required String date,
  }) async {
    final response = await http
        .get(
          Uri.parse('$_servicesRoot/$serviceId/available-slots?date=$date'),
          headers: await _headers(authRequired: false),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> createAppointment({
    required String serviceId,
    required String appointmentDate,
    required int duration,
    required String location,
    double? proposedPrice,
    String? notes,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_servicesRoot/$serviceId/appointments'),
          headers: await _headers(authRequired: true),
          body: jsonEncode({
            'appointmentDate': appointmentDate,
            'duration': duration,
            'location': location,
            if (proposedPrice != null) 'proposedPrice': proposedPrice,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          }),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> getProviderAppointments() async {
    final response = await http
        .get(
          Uri.parse('$_servicesRoot/appointments/provider/list'),
          headers: await _headers(authRequired: true),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> getClientAppointments() async {
    final response = await http
        .get(
          Uri.parse('$_servicesRoot/appointments/client/list'),
          headers: await _headers(authRequired: true),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> confirmAppointment(String appointmentId) async {
    return _patch('$_servicesRoot/appointments/$appointmentId/confirm');
  }

  Future<Map<String, dynamic>> cancelAppointment(String appointmentId) async {
    return _patch('$_servicesRoot/appointments/$appointmentId/cancel');
  }

  Future<Map<String, dynamic>> completeAppointment(String appointmentId) async {
    return _patch('$_servicesRoot/appointments/$appointmentId/complete');
  }

  Future<Map<String, dynamic>> noShowAppointment(String appointmentId) async {
    return _patch('$_servicesRoot/appointments/$appointmentId/no-show');
  }

  Future<Map<String, dynamic>> _patch(String url) async {
    final response = await http
        .patch(Uri.parse(url), headers: await _headers(authRequired: true))
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  List<Map<String, dynamic>> normalizeList(dynamic source) {
    if (source is List) {
      return source
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (source is Map<String, dynamic>) {
      final data = source['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const [];
  }

  String dateOnly(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String isoWithOffset(DateTime dateTime) {
    final dt = dateTime;
    final offset = dt.timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final abs = offset.abs();
    final hours = abs.inHours.toString().padLeft(2, '0');
    final minutes = (abs.inMinutes % 60).toString().padLeft(2, '0');

    final date =
        '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

    return '${date}T$time$sign$hours:$minutes';
  }

  DateTime? parseTimeOfDay(DateTime date, String? time) {
    if (time == null || time.isEmpty) return null;
    final parts = time.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String extractMessage(Object error) {
    return ErrorMessageUtils.sanitize(error);
  }

  void log(String message) {
    debugPrint('📘 ServiceBookingService: $message');
  }
}
