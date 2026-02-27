// import 'dart:convert';
// import 'package:Yempover_app/models/update_profile_image_request.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:Yempover_app/models/ProductPostmain.dart';
// import '../constants/api_constants.dart';
// import '../models/auth_models.dart';
// import 'token_service.dart'; // Add this import

// class ApiException implements Exception {
//   final String message;
//   final int? statusCode;

//   ApiException(this.message, {this.statusCode});

//   @override
//   String toString() => message;
// }

// class ApiService {
//   static final ApiService _instance = ApiService._internal();
//   factory ApiService() => _instance;
//   ApiService._internal();

//   final http.Client _client = http.Client();
//   final TokenService _tokenService =
//       TokenService(); // Add token service instance

//   // Generic GET request method with authentication
//   Future<dynamic> _makeGetRequest(
//     String url, {
//     Map<String, String>? additionalHeaders,
//     Map<String, dynamic>? queryParams,
//   }) async {
//     debugPrint('🌐 ApiService: Making GET request to: $url');

//     // Add query parameters if provided
//     String fullUrl = url;
//     if (queryParams != null && queryParams.isNotEmpty) {
//       final uri = Uri.parse(url);
//       final updatedUri = uri.replace(
//         queryParameters: {
//           ...uri.queryParameters,
//           ...queryParams.map((key, value) => MapEntry(key, value.toString())),
//         },
//       );
//       fullUrl = updatedUri.toString();
//       debugPrint('🌐 ApiService: Full URL with params: $fullUrl');
//     }

//     try {
//       // Get auth token from TokenService
//       final token = await _tokenService.getToken();
//       debugPrint('🔑 ApiService: Auth token present: ${token != null}');

//       // Prepare headers with authorization
//       final headers = {
//         ...ApiConstants.headers,
//         if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
//       };

//       if (additionalHeaders != null) {
//         headers.addAll(additionalHeaders);
//       }

//       debugPrint('📋 ApiService: Headers: $headers');

//       final response = await _client
//           .get(Uri.parse(fullUrl), headers: headers)
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📨 ApiService: Response status code: ${response.statusCode}');
//       debugPrint('📄 ApiService: Response body: ${response.body}');

//       // Handle 401 Unauthorized - token expired or invalid
//       if (response.statusCode == 401) {
//         debugPrint('🔴 ApiService: Unauthorized - token may be expired');
//         // Clear invalid token
//         await _tokenService.clearTokens();
//         throw ApiException(
//           'Session expired. Please login again.',
//           statusCode: 401,
//         );
//       }

//       final Map<String, dynamic> responseData = json.decode(response.body);

//       // Check if response has success status
//       final bool isSuccess =
//           responseData['status'] == 'success' ||
//           responseData['success'] == true ||
//           responseData.containsKey('data');

//       debugPrint('✅ ApiService: Is success from API: $isSuccess');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         if (isSuccess) {
//           debugPrint('🟢 ApiService: Returning success response');
//           return responseData;
//         } else {
//           final errorMessage =
//               responseData['message'] ?? ErrorMessages.serverError;
//           debugPrint('🔴 ApiService: API returned failure: $errorMessage');
//           throw ApiException(errorMessage, statusCode: response.statusCode);
//         }
//       } else if (response.statusCode == 500) {
//         debugPrint('🔴 ApiService: Server error 500');
//         throw ApiException(
//           ErrorMessages.serverError,
//           statusCode: response.statusCode,
//         );
//       } else {
//         final errorMessage =
//             responseData['message'] ?? ErrorMessages.unknownError;
//         debugPrint(
//           '🔴 ApiService: Unexpected status ${response.statusCode}: $errorMessage',
//         );
//         throw ApiException(errorMessage, statusCode: response.statusCode);
//       }
//     } on http.ClientException catch (e) {
//       debugPrint('🔴 ApiService: ClientException: ${e.message}');
//       throw ApiException('${ErrorMessages.networkError}: ${e.message}');
//     } on FormatException catch (e) {
//       debugPrint('🔴 ApiService: FormatException: $e');
//       throw ApiException('Invalid response format from server');
//     } on ApiException {
//       rethrow;
//     } catch (e) {
//       debugPrint('🔴 ApiService: Unknown error: $e');
//       throw ApiException(ErrorMessages.unknownError);
//     }
//   }

//   // Generic POST request method with authentication
//   Future<dynamic> _makePostRequest<T>(
//     String url,
//     Map<String, dynamic> body,
//     T Function(Map<String, dynamic>)? fromJson,
//   ) async {
//     debugPrint('🌐 ApiService: Making POST request to: $url');
//     debugPrint('📦 ApiService: Request body: ${json.encode(body)}');

//     try {
//       // Get auth token from TokenService
//       final token = await _tokenService.getToken();
//       debugPrint('🔑 ApiService: Auth token present: ${token != null}');

//       // Prepare headers with authorization
//       final headers = {
//         ...ApiConstants.headers,
//         if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
//       };

//       debugPrint('📋 ApiService: Headers: $headers');

//       final response = await _client
//           .post(Uri.parse(url), headers: headers, body: json.encode(body))
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📨 ApiService: Response status code: ${response.statusCode}');
//       debugPrint('📄 ApiService: Response body: ${response.body}');

//       // Handle 401 Unauthorized
//       if (response.statusCode == 401) {
//         debugPrint('🔴 ApiService: Unauthorized - token may be expired');
//         // Clear invalid token
//         await _tokenService.clearTokens();
//         throw ApiException(
//           'Session expired. Please login again.',
//           statusCode: 401,
//         );
//       }

//       final Map<String, dynamic> responseData = json.decode(response.body);

//       // Check if response has success status
//       final bool isSuccess =
//           responseData['status'] == true ||
//           responseData['success'] == true ||
//           responseData['isSuccess'] == true ||
//           responseData.containsKey('data');

//       debugPrint('✅ ApiService: Is success from API: $isSuccess');

//       // Return success response for 200 or 201
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         if (isSuccess) {
//           debugPrint('🟢 ApiService: Returning success response');
//           return AuthResponse.fromJson(responseData, fromJson);
//         } else {
//           final errorMessage =
//               responseData['message'] ?? ErrorMessages.serverError;
//           debugPrint('🔴 ApiService: API returned failure: $errorMessage');
//           throw ApiException(errorMessage, statusCode: response.statusCode);
//         }
//       }
//       // Handle 400 specifically - might be success with verification required
//       else if (response.statusCode == 400) {
//         final message = responseData['message'] ?? ErrorMessages.serverError;
//         debugPrint('🟡 ApiService: 400 status code with message: $message');

//         // Check if this is a "successful registration, verify OTP" scenario
//         if (message.toLowerCase().contains('success') ||
//             message.toLowerCase().contains('verify') ||
//             message.toLowerCase().contains('otp')) {
//           debugPrint(
//             '🟡 ApiService: This appears to be a successful registration requiring OTP verification',
//           );
//           // Create a success response even with 400 status
//           return AuthResponse(
//             isSuccess: true,
//             message: message,
//             data: fromJson != null ? fromJson(responseData) : null,
//             status: '',
//           );
//         }

//         throw ApiException(message, statusCode: response.statusCode);
//       } else if (response.statusCode == 500) {
//         debugPrint('🔴 ApiService: Server error 500');
//         throw ApiException(
//           ErrorMessages.serverError,
//           statusCode: response.statusCode,
//         );
//       } else {
//         final errorMessage =
//             responseData['message'] ?? ErrorMessages.unknownError;
//         debugPrint(
//           '🔴 ApiService: Unexpected status ${response.statusCode}: $errorMessage',
//         );
//         throw ApiException(errorMessage, statusCode: response.statusCode);
//       }
//     } on http.ClientException catch (e) {
//       debugPrint('🔴 ApiService: ClientException: ${e.message}');
//       throw ApiException('${ErrorMessages.networkError}: ${e.message}');
//     } on FormatException catch (e) {
//       debugPrint('🔴 ApiService: FormatException: $e');
//       throw ApiException('Invalid response format from server');
//     } on ApiException {
//       rethrow;
//     } catch (e) {
//       debugPrint('🔴 ApiService: Unknown error: $e');
//       throw ApiException(ErrorMessages.unknownError);
//     }
//   }

//   // ============= AUTH ENDPOINTS =============
//   Future<AuthResponse<RegisterResponseData>> register(
//     RegisterRequest request,
//   ) async {
//     final body = request.toJson();

//     // ✅ Ensure acceptedTerms always included
//     body['acceptedTerms'] = request.acceptedTerms;

//     debugPrint('📝 ApiService: Register called with: $body');

//     return await _makePostRequest<RegisterResponseData>(
//       ApiConstants.register,
//       body,
//       RegisterResponseData.fromJson,
//     );
//   }

//   Future<AuthResponse<SendOtpResponseData>> sendOtp(
//     SendOtpRequest request,
//   ) async {
//     debugPrint('📱 ApiService: SendOtp called for: ${request.mobileNumber}');
//     return await _makePostRequest<SendOtpResponseData>(
//       ApiConstants.sendOtp,
//       request.toJson(),
//       SendOtpResponseData.fromJson,
//     );
//   }

//   Future<AuthResponse<VerifyOtpResponseData>> verifyOtp(
//     VerifyOtpRequest request,
//   ) async {
//     debugPrint('✅ ApiService: VerifyOtp called for: ${request.mobileNumber}');
//     return await _makePostRequest<VerifyOtpResponseData>(
//       ApiConstants.verifyOtp,
//       request.toJson(),
//       VerifyOtpResponseData.fromJson,
//     );
//   }

//   // ============= POST ENDPOINTS =============
//   Future<PostsResponse> getPosts({
//     int page = 1,
//     int limit = 20,
//     String? category,
//     String? search,
//     double? lat,
//     double? lng,
//     double? radius,
//     String? status,
//     double? latitude,
//     double? longitude,
//   }) async {
//     try {
//       // Check if user is logged in first
//       final isLoggedIn = await _tokenService.isLoggedIn();
//       if (!isLoggedIn) {
//         debugPrint('🔴 ApiService: User not logged in, cannot fetch posts');
//         throw ApiException('Please login to view posts');
//       }

//       final Map<String, dynamic> queryParams = {
//         'page': page.toString(),
//         'limit': limit.toString(),
//       };

//       if (category != null && category.isNotEmpty) {
//         queryParams['category'] = category;
//       }
//       if (search != null && search.isNotEmpty) {
//         queryParams['search'] = search;
//       }

//       // Use latitude/longitude parameters if provided
//       final useLat = latitude ?? lat;
//       final useLng = longitude ?? lng;

//       if (useLat != null && useLng != null) {
//         queryParams['latitude'] = useLat.toString();
//         queryParams['longitude'] = useLng.toString();
//         if (radius != null) {
//           queryParams['radius'] = radius.toString();
//         }
//       }

//       if (status != null && status.isNotEmpty) {
//         queryParams['status'] = status;
//       }

//       final response = await _makeGetRequest(
//         ApiConstants.posts,
//         queryParams: queryParams,
//       );

//       return PostsResponse.fromJson(response);
//     } catch (e) {
//       debugPrint('🔴 ApiService: Error fetching posts: $e');
//       rethrow;
//     }
//   }

//   // ============= PROFILE IMAGE ENDPOINT =============
//   /// Upload profile image using base64 string
//   Future<UpdateProfileImageResponse> uploadProfileImageBase64({
//     required String base64Image,
//     required String mimeType, // e.g., 'image/jpeg', 'image/png'
//   }) async {
//     debugPrint('🖼️ ApiService: Uploading profile image');

//     try {
//       // Create data URL with proper mime type
//       final dataUrl = 'data:$mimeType;base64,$base64Image';

//       final body = {'image': dataUrl};

//       debugPrint(
//         '📦 ApiService: Image data URL created (length: ${dataUrl.length})',
//       );

//       final response = await _makePostRequest<dynamic>(
//         ApiConstants
//             .uploadAvatarBase64, // Make sure this constant exists in ApiConstants
//         body,
//         null, // No fromJson needed as we'll parse directly
//       );

//       // Since _makePostRequest returns AuthResponse, we need to extract the data
//       if (response is AuthResponse) {
//         if (response.isSuccess && response.data != null) {
//           // The data should be a Map containing the response
//           return UpdateProfileImageResponse.fromJson(
//             response.data as Map<String, dynamic>,
//           );
//         } else {
//           throw ApiException(response.message);
//         }
//       } else {
//         // Fallback: try to parse response directly
//         return UpdateProfileImageResponse.fromJson(response);
//       }
//     } catch (e) {
//       debugPrint('🔴 ApiService: Error uploading profile image: $e');
//       rethrow;
//     }
//   }

//   /// Upload profile image with automatic mime type detection
//   Future<UpdateProfileImageResponse> uploadProfileImage(
//     String base64Image,
//   ) async {
//     // Default to JPEG if mime type not specified
//     return await uploadProfileImageBase64(
//       base64Image: base64Image,
//       mimeType: 'image/jpeg',
//     );
//   }

//   Future<PostDetailResponse> getPostDetail({
//     required String postId,
//     required PostType type,
//   }) async {
//     try {
//       final response = await _makeGetRequest(
//         '${ApiConstants.posts}/$postId?type=${type == PostType.service ? 'service' : 'product'}',
//       );

//       return PostDetailResponse.fromJson(response);
//     } catch (e) {
//       debugPrint('🔴 ApiService: Error fetching post detail: $e');
//       rethrow;
//     }
//   }

//   // ============= CLEANUP =============
//   void dispose() {
//     _client.close();
//     debugPrint('♻️ ApiService: Disposed HTTP client');
//   }
// }

import 'dart:convert';
import 'package:Yempover_app/models/update_profile_image_request.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Yempover_app/models/ProductPostmain.dart';
import '../constants/api_constants.dart';
import '../models/auth_models.dart';
import 'token_service.dart';

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
  final TokenService _tokenService = TokenService();

  // ============= PUBLIC HTTP METHODS =============

  /// Public GET request method
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    debugPrint('🌐 ApiService: Public GET request to: $url');

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

    try {
      // Get auth token from TokenService
      final token = await _tokenService.getToken();

      // Prepare headers with authorization
      final Map<String, String> requestHeaders = {
        ...ApiConstants.headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      final response = await _client
          .get(Uri.parse(fullUrl), headers: requestHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 ApiService: GET response status: ${response.statusCode}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        debugPrint('🔴 ApiService: Unauthorized - token may be expired');
        await _tokenService.clearTokens();
      }

      return response;
    } catch (e) {
      debugPrint('🔴 ApiService: GET request error: $e');
      rethrow;
    }
  }

  /// Public POST request method
  Future<http.Response> post(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    debugPrint('🌐 ApiService: Public POST request to: $url');
    debugPrint(
      '📦 ApiService: Request body: ${body != null ? json.encode(body) : 'null'}',
    );

    try {
      // Get auth token from TokenService
      final token = await _tokenService.getToken();

      // Prepare headers with authorization
      final Map<String, String> requestHeaders = {
        ...ApiConstants.headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      final response = await _client
          .post(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 ApiService: POST response status: ${response.statusCode}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        debugPrint('🔴 ApiService: Unauthorized - token may be expired');
        await _tokenService.clearTokens();
      }

      return response;
    } catch (e) {
      debugPrint('🔴 ApiService: POST request error: $e');
      rethrow;
    }
  }

  /// Public PUT request method
  Future<http.Response> put(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    debugPrint('🌐 ApiService: Public PUT request to: $url');

    try {
      // Get auth token from TokenService
      final token = await _tokenService.getToken();

      // Prepare headers with authorization
      final Map<String, String> requestHeaders = {
        ...ApiConstants.headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      final response = await _client
          .put(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 ApiService: PUT response status: ${response.statusCode}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        debugPrint('🔴 ApiService: Unauthorized - token may be expired');
        await _tokenService.clearTokens();
      }

      return response;
    } catch (e) {
      debugPrint('🔴 ApiService: PUT request error: $e');
      rethrow;
    }
  }

  /// Public DELETE request method
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    debugPrint('🌐 ApiService: Public DELETE request to: $url');

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
    }

    try {
      // Get auth token from TokenService
      final token = await _tokenService.getToken();

      // Prepare headers with authorization
      final Map<String, String> requestHeaders = {
        ...ApiConstants.headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      final response = await _client
          .delete(Uri.parse(fullUrl), headers: requestHeaders)
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📨 ApiService: DELETE response status: ${response.statusCode}',
      );

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        debugPrint('🔴 ApiService: Unauthorized - token may be expired');
        await _tokenService.clearTokens();
      }

      return response;
    } catch (e) {
      debugPrint('🔴 ApiService: DELETE request error: $e');
      rethrow;
    }
  }

  /// Public PATCH request method
  Future<http.Response> patch(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    debugPrint('🌐 ApiService: Public PATCH request to: $url');

    try {
      // Get auth token from TokenService
      final token = await _tokenService.getToken();

      // Prepare headers with authorization
      final Map<String, String> requestHeaders = {
        ...ApiConstants.headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        if (headers != null) ...headers,
      };

      final response = await _client
          .patch(
            Uri.parse(url),
            headers: requestHeaders,
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '📨 ApiService: PATCH response status: ${response.statusCode}',
      );

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        debugPrint('🔴 ApiService: Unauthorized - token may be expired');
        await _tokenService.clearTokens();
      }

      return response;
    } catch (e) {
      debugPrint('🔴 ApiService: PATCH request error: $e');
      rethrow;
    }
  }

  // ============= PRIVATE HELPER METHODS =============

  // Generic GET request method with authentication (private)
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

    try {
      // Get auth token from TokenService
      final token = await _tokenService.getToken();
      debugPrint('🔑 ApiService: Auth token present: ${token != null}');

      // Prepare headers with authorization
      final headers = {
        ...ApiConstants.headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      if (additionalHeaders != null) {
        headers.addAll(additionalHeaders);
      }

      debugPrint('📋 ApiService: Headers: $headers');

      final response = await _client
          .get(Uri.parse(fullUrl), headers: headers)
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 ApiService: Response status code: ${response.statusCode}');
      debugPrint('📄 ApiService: Response body: ${response.body}');

      // Handle 401 Unauthorized - token expired or invalid
      if (response.statusCode == 401) {
        debugPrint('🔴 ApiService: Unauthorized - token may be expired');
        // Clear invalid token
        await _tokenService.clearTokens();
        throw ApiException(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      }

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

  // Generic POST request method with authentication (private)
  Future<dynamic> _makePostRequest<T>(
    String url,
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>)? fromJson,
  ) async {
    debugPrint('🌐 ApiService: Making POST request to: $url');
    debugPrint('📦 ApiService: Request body: ${json.encode(body)}');

    try {
      // Get auth token from TokenService
      final token = await _tokenService.getToken();
      debugPrint('🔑 ApiService: Auth token present: ${token != null}');

      // Prepare headers with authorization
      final headers = {
        ...ApiConstants.headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      debugPrint('📋 ApiService: Headers: $headers');

      final response = await _client
          .post(Uri.parse(url), headers: headers, body: json.encode(body))
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 ApiService: Response status code: ${response.statusCode}');
      debugPrint('📄 ApiService: Response body: ${response.body}');

      // Handle 401 Unauthorized
      if (response.statusCode == 401) {
        debugPrint('🔴 ApiService: Unauthorized - token may be expired');
        // Clear invalid token
        await _tokenService.clearTokens();
        throw ApiException(
          'Session expired. Please login again.',
          statusCode: 401,
        );
      }

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
      // Check if user is logged in first
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (!isLoggedIn) {
        debugPrint('🔴 ApiService: User not logged in, cannot fetch posts');
        throw ApiException('Please login to view posts');
      }

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

      // Use latitude/longitude parameters if provided
      final useLat = latitude ?? lat;
      final useLng = longitude ?? lng;

      if (useLat != null && useLng != null) {
        queryParams['latitude'] = useLat.toString();
        queryParams['longitude'] = useLng.toString();
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

  // ============= PROFILE IMAGE ENDPOINT =============
  /// Upload profile image using base64 string
  Future<UpdateProfileImageResponse> uploadProfileImageBase64({
    required String base64Image,
    required String mimeType, // e.g., 'image/jpeg', 'image/png'
  }) async {
    debugPrint('🖼️ ApiService: Uploading profile image');

    try {
      // Create data URL with proper mime type
      final dataUrl = 'data:$mimeType;base64,$base64Image';

      final body = {'image': dataUrl};

      debugPrint(
        '📦 ApiService: Image data URL created (length: ${dataUrl.length})',
      );

      final response = await _makePostRequest<dynamic>(
        ApiConstants.uploadAvatarBase64,
        body,
        null, // No fromJson needed as we'll parse directly
      );

      // Since _makePostRequest returns AuthResponse, we need to extract the data
      if (response is AuthResponse) {
        if (response.isSuccess && response.data != null) {
          // The data should be a Map containing the response
          return UpdateProfileImageResponse.fromJson(
            response.data as Map<String, dynamic>,
          );
        } else {
          throw ApiException(response.message);
        }
      } else {
        // Fallback: try to parse response directly
        return UpdateProfileImageResponse.fromJson(response);
      }
    } catch (e) {
      debugPrint('🔴 ApiService: Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Upload profile image with automatic mime type detection
  Future<UpdateProfileImageResponse> uploadProfileImage(
    String base64Image,
  ) async {
    // Default to JPEG if mime type not specified
    return await uploadProfileImageBase64(
      base64Image: base64Image,
      mimeType: 'image/jpeg',
    );
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

  Future<void> removeFavorite(String favoriteId) async {
    final token = await TokenService().getToken();

    final response = await http.delete(
      Uri.parse('${ApiConstants.baseUrl}/favorites/$favoriteId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove favorite: ${response.body}');
    }
  }

  // ============= CLEANUP =============
  void dispose() {
    _client.close();
    debugPrint('♻️ ApiService: Disposed HTTP client');
  }
}
