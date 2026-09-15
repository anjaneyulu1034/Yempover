import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/add_post_model.dart';
import 'package:yempover_app/models/service_availability_plan.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/utils/api_exceptions.dart';
import 'package:yempover_app/utils/error_message_utils.dart';

class AddPostService {
  static final AddPostService _instance = AddPostService._internal();
  factory AddPostService() => _instance;
  AddPostService._internal();

  // Create a new client for each request instead of reusing one
  // This prevents the "Client is already closed" error

  Future<String?> _getToken() async {
    return await TokenService().getToken();
  }

  // Convert image to base64 and create a data URL
  Future<String> imageToBase64Url(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Get file extension to determine MIME type
      final extension = image.path.split('.').last.toLowerCase();
      String mimeType;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      return 'data:$mimeType;base64,$base64Image';
    } catch (e) {
      debugPrint('🔴 AddPostService: Error converting image to base64: $e');
      rethrow;
    }
  }

  // Convert multiple images to base64 data URLs
  Future<List<String>> getImageUrlsFromBase64(List<File> images) async {
    List<String> imageUrls = [];

    for (var i = 0; i < images.length; i++) {
      try {
        debugPrint(
          '🖼️ AddPostService: Converting image ${i + 1}/${images.length} to base64',
        );
        final base64Url = await imageToBase64Url(images[i]);
        imageUrls.add(base64Url);
        debugPrint('✅ AddPostService: Image ${i + 1} converted successfully');
      } catch (e) {
        debugPrint('🔴 AddPostService: Failed to convert image ${i + 1}: $e');
        // Continue with other images
      }
    }

    debugPrint(
      '✅ AddPostService: Converted ${imageUrls.length} images to base64',
    );
    return imageUrls;
  }

  // Create product post with direct base64 images
  Future<CreateProductResponse> createProductPost(
    CreateProductRequest request,
  ) async {
    // Create a new client for this request
    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Please login to continue');
      }

      // Ensure images are provided
      final images = request.images ?? [];
      if (images.isEmpty) {
        throw Exception('Please add at least one image to continue');
      }

      // Convert request to JSON
      final Map<String, dynamic> requestBody = {
        'title': request.title,
        'description': request.description,
        'categoryId': request.categoryId,
        'images': images, // These should be base64 data URLs
        'location': request.location,
        if (request.latitude != null) 'latitude': request.latitude,
        if (request.longitude != null) 'longitude': request.longitude,
        'barterStatus': request.barterStatus,
        'canClubItems': request.canClubItems,
        'isClubbable': request.canClubItems,
        'canBeClubbed': request.canClubItems,
        'price': request.price,
        if (request.validFrom != null && request.validFrom!.isNotEmpty)
          'validFrom': request.validFrom,
        if (request.validUntil != null && request.validUntil!.isNotEmpty)
          'validUntil': request.validUntil,
      };

      final url = '${ApiConstants.baseUrl}/me/posts/products';
      debugPrint('🌐 AddPostService: Creating product post: $url');
      debugPrint(
        '📦 AddPostService: Request body: ${json.encode(requestBody)}',
      );

      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 AddPostService: Response status: ${response.statusCode}');
      debugPrint('📄 AddPostService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint('✅ AddPostService: Product created successfully');
        return CreateProductResponse.fromJson(jsonResponse);
      } else {
        throw Exception(
          ErrorMessageUtils.sanitize(
            response.body,
            fallback: 'Unable to create post right now. Please try again.',
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 AddPostService: Error creating product: $e');
      throw Exception(ErrorMessageUtils.sanitize(e));
    } finally {
      // Always close the client
      client.close();
    }
  }

  // Create service post
  Future<CreateServiceResponse> createServicePost(
    CreateServiceRequest request,
  ) async {
    // Create a new client for this request
    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('Please login to continue');
      }

      // Convert request to JSON
      final Map<String, dynamic> requestBody = {
        'title': request.title,
        'description': request.description,
        'categoryId': request.categoryId,
        'images': request.images ?? [], // Services might have optional images
        if (request.location != null && request.location!.isNotEmpty)
          'location': request.location,
        if (request.latitude != null) 'latitude': request.latitude,
        if (request.longitude != null) 'longitude': request.longitude,
        if (request.validFrom != null && request.validFrom!.isNotEmpty)
          'validFrom': request.validFrom,
        if (request.validUntil != null && request.validUntil!.isNotEmpty)
          'validUntil': request.validUntil,
        'status': request.status,
        'price': request.price,
        if (request.availabilitySlots != null)
          'availabilitySlots': request.availabilitySlots,
        if (request.expiryUnit != null && request.expiryUnit!.isNotEmpty)
          'expiryUnit': request.expiryUnit,
        if (request.expiryValue != null) 'expiryValue': request.expiryValue,
        if (request.confirmAvailabilityChange != null)
          'confirmAvailabilityChange': request.confirmAvailabilityChange,
      };

      final url = '${ApiConstants.baseUrl}/me/posts/services';
      debugPrint('🌐 AddPostService: Creating service post: $url');
      debugPrint(
        '📦 AddPostService: Request body: ${json.encode(requestBody)}',
      );

      final response = await client
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 AddPostService: Response status: ${response.statusCode}');
      debugPrint('📄 AddPostService: Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint('✅ AddPostService: Service created successfully');
        return CreateServiceResponse.fromJson(jsonResponse);
      } else {
        // Backend-authored, user-safe messages (QA BUG-3/4) — read `message`
        // straight off the body rather than through ErrorMessageUtils, whose
        // generic heuristics (e.g. any message containing "invalid") are
        // tuned for garbling raw network/auth errors, not this copy.
        String message = 'Unable to create post right now. Please try again.';
        String? code;
        Map<String, dynamic>? details;
        try {
          final body = json.decode(response.body);
          if (body is Map && body['message'] != null) {
            message = body['message'].toString();
          }
          if (body is Map && body['code'] != null) {
            code = body['code'].toString();
          }
          if (body is Map && body['details'] is Map) {
            details = Map<String, dynamic>.from(body['details'] as Map);
          }
        } catch (_) {
          // Keep the generic fallback above.
        }

        // QA BUG-4: the expiry/availability the seller picked would swap the
        // mode and hasn't been confirmed yet — nothing was created. The
        // caller must show `details` as a confirmation dialog, not a toast.
        if (response.statusCode == 409 &&
            code == 'AVAILABILITY_MODE_CHANGE' &&
            details != null) {
          throw AvailabilityChangeRequiredException(
            message,
            AvailabilityConfirmation.fromJson(details),
          );
        }

        throw ApiCodedException(
          message,
          code: code,
          details: details,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      debugPrint('🔴 AddPostService: Error creating service: $e');
      // Typed exceptions already carry a backend-authored, verbatim message
      // (QA BUG-3/4) — only generic/unexpected errors go through sanitize.
      if (e is AvailabilityChangeRequiredException || e is ApiCodedException) {
        rethrow;
      }
      throw Exception(ErrorMessageUtils.sanitize(e));
    } finally {
      // Always close the client
      client.close();
    }
  }

  // Remove the dispose method since we're not keeping a persistent client
  void dispose() {
    // Nothing to dispose now
  }
}
