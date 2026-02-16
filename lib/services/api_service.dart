import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/models/ProductPostmain.dart';
import '../constants/api_constants.dart';
import '../models/auth_models.dart';
import '../models/post_model.dart' hide PostsResponse;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();

  // Generic GET request method
  Future<dynamic> _makeGetRequest(
    String url, {
    Map<String, String>? additionalHeaders,
    Map<String, dynamic>? queryParams,
  }) async {
    debugPrint('🌐 ApiService: Making GET request to: $url');

    // Add query parameters if provided
    String fullUrl = url;
    if (queryParams != null && queryParams.isNotEmpty) {
      final uri = Uri.parse(url);
      final updatedUri = uri.replace(
        queryParameters: {
          ...uri.queryParameters,
          ...queryParams.map((key, value) => MapEntry(key, value.toString())),
        },
      );
      fullUrl = updatedUri.toString();
      debugPrint('🌐 ApiService: Full URL with params: $fullUrl');
    }

    debugPrint('📋 ApiService: Headers: ${ApiConstants.headers}');

    try {
      final headers = {...ApiConstants.headers};
      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      final response = await _client
          .get(Uri.parse(fullUrl), headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 ApiService: Response status code: ${response.statusCode}');
      debugPrint('📄 ApiService: Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if response has success status
      final bool isSuccess =
          responseData['status'] == 'success' ||
          responseData['success'] == true ||
          responseData.containsKey('data');

      debugPrint('✅ ApiService: Is success from API: $isSuccess');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isSuccess) {
          debugPrint('🟢 ApiService: Returning success response');
          return responseData;
        } else {
          final errorMessage =
              responseData['message'] ?? ErrorMessages.serverError;
          debugPrint('🔴 ApiService: API returned failure: $errorMessage');
          throw ApiException(errorMessage, statusCode: response.statusCode);
        }
      } else if (response.statusCode == 500) {
        debugPrint('🔴 ApiService: Server error 500');
        throw ApiException(
          ErrorMessages.serverError,
          statusCode: response.statusCode,
        );
      } else {
        final errorMessage =
            responseData['message'] ?? ErrorMessages.unknownError;
        debugPrint(
          '🔴 ApiService: Unexpected status ${response.statusCode}: $errorMessage',
        );
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      debugPrint('🔴 ApiService: ClientException: ${e.message}');
      throw ApiException('${ErrorMessages.networkError}: ${e.message}');
    } on FormatException catch (e) {
      debugPrint('🔴 ApiService: FormatException: $e');
      throw ApiException('Invalid response format from server');
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('🔴 ApiService: Unknown error: $e');
      throw ApiException(ErrorMessages.unknownError);
    }
  }

  // Generic POST request method
  Future<dynamic> _makePostRequest<T>(
    String url,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    debugPrint('🌐 ApiService: Making POST request to: $url');
    debugPrint('📦 ApiService: Request body: ${json.encode(body)}');
    debugPrint('📋 ApiService: Headers: ${ApiConstants.headers}');

    try {
      final response = await _client
          .post(
            Uri.parse(url),
            headers: ApiConstants.headers,
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 ApiService: Response status code: ${response.statusCode}');
      debugPrint('📄 ApiService: Response body: ${response.body}');

      final Map<String, dynamic> responseData = json.decode(response.body);

      // Check if response has success status
      final bool isSuccess =
          responseData['status'] == true ||
          responseData['success'] == true ||
          responseData['isSuccess'] == true ||
          responseData.containsKey('data');

      debugPrint('✅ ApiService: Is success from API: $isSuccess');

      // Return success response for 200 or 201
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (isSuccess) {
          debugPrint('🟢 ApiService: Returning success response');
          return AuthResponse.fromJson(responseData, fromJson);
        } else {
          final errorMessage =
              responseData['message'] ?? ErrorMessages.serverError;
          debugPrint('🔴 ApiService: API returned failure: $errorMessage');
          throw ApiException(errorMessage, statusCode: response.statusCode);
        }
      }
      // Handle 400 specifically - might be success with verification required
      else if (response.statusCode == 400) {
        final message = responseData['message'] ?? ErrorMessages.serverError;
        debugPrint('🟡 ApiService: 400 status code with message: $message');

        // Check if this is a "successful registration, verify OTP" scenario
        if (message.toLowerCase().contains('success') ||
            message.toLowerCase().contains('verify') ||
            message.toLowerCase().contains('otp')) {
          debugPrint(
            '🟡 ApiService: This appears to be a successful registration requiring OTP verification',
          );
          // Create a success response even with 400 status
          return AuthResponse(
            isSuccess: true,
            message: message,
            data: fromJson != null ? fromJson(responseData) : null,
            status: '',
          );
        }

        throw ApiException(message, statusCode: response.statusCode);
      } else if (response.statusCode == 500) {
        debugPrint('🔴 ApiService: Server error 500');
        throw ApiException(
          ErrorMessages.serverError,
          statusCode: response.statusCode,
        );
      } else {
        final errorMessage =
            responseData['message'] ?? ErrorMessages.unknownError;
        debugPrint(
          '🔴 ApiService: Unexpected status ${response.statusCode}: $errorMessage',
        );
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } on http.ClientException catch (e) {
      debugPrint('🔴 ApiService: ClientException: ${e.message}');
      throw ApiException('${ErrorMessages.networkError}: ${e.message}');
    } on FormatException catch (e) {
      debugPrint('🔴 ApiService: FormatException: $e');
      throw ApiException('Invalid response format from server');
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint('🔴 ApiService: Unknown error: $e');
      throw ApiException(ErrorMessages.unknownError);
    }
  }

  // ============= AUTH ENDPOINTS =============
  Future<AuthResponse<RegisterResponseData>> register(
    RegisterRequest request,
  ) async {
    final body = request.toJson();

    // ✅ Ensure acceptedTerms always included
    body['acceptedTerms'] = request.acceptedTerms;

    debugPrint('📝 ApiService: Register called with: $body');

    return await _makePostRequest<RegisterResponseData>(
      ApiConstants.register,
      body,
      RegisterResponseData.fromJson,
    );
  }

  Future<AuthResponse<SendOtpResponseData>> sendOtp(
    SendOtpRequest request,
  ) async {
    debugPrint('📱 ApiService: SendOtp called for: ${request.mobileNumber}');
    return await _makePostRequest<SendOtpResponseData>(
      ApiConstants.sendOtp,
      request.toJson(),
      SendOtpResponseData.fromJson,
    );
  }

  Future<AuthResponse<VerifyOtpResponseData>> verifyOtp(
    VerifyOtpRequest request,
  ) async {
    debugPrint('✅ ApiService: VerifyOtp called for: ${request.mobileNumber}');
    return await _makePostRequest<VerifyOtpResponseData>(
      ApiConstants.verifyOtp,
      request.toJson(),
      VerifyOtpResponseData.fromJson,
    );
  }

  // ============= POST ENDPOINTS =============
  Future<PostsResponse> getPosts({
    int page = 1,
    int limit = 20,
    String? category,
    String? search,
    double? lat,
    double? lng,
    double? radius,
    String? status,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (category != null && category.isNotEmpty) {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (lat != null && lng != null) {
        queryParams['lat'] = lat.toString();
        queryParams['lng'] = lng.toString();
        if (radius != null) {
          queryParams['radius'] = radius.toString();
        }
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }

      final response = await _makeGetRequest(
        ApiConstants.posts,
        queryParams: queryParams,
      );

      return PostsResponse.fromJson(response);
    } catch (e) {
      debugPrint('🔴 ApiService: Error fetching posts: $e');
      rethrow;
    }
  }

  Future<PostDetailResponse> getPostDetail({
    required String postId,
    required PostType type,
  }) async {
    try {
      final response = await _makeGetRequest(
        '${ApiConstants.posts}/$postId?type=${type == PostType.service ? 'service' : 'product'}',
      );

      return PostDetailResponse.fromJson(response);
    } catch (e) {
      debugPrint('🔴 ApiService: Error fetching post detail: $e');
      rethrow;
    }
  }

  // ============= CLEANUP =============
  void dispose() {
    _client.close();
    debugPrint('♻️ ApiService: Disposed HTTP client');
  }
}
