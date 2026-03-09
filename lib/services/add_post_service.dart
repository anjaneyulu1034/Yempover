// // lib/services/add_post_service.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:Yempover_app/constants/api_constants.dart';
// import 'package:Yempover_app/models/add_post_model.dart';
// import 'package:Yempover_app/services/token_service.dart';

// class AddPostService {
//   static final AddPostService _instance = AddPostService._internal();
//   factory AddPostService() => _instance;
//   AddPostService._internal();

//   final http.Client _client = http.Client();

//   Future<String?> _getToken() async {
//     return await TokenService().getToken();
//   }

//   // Convert image to base64 and create a data URL
//   Future<String> imageToBase64Url(File image) async {
//     try {
//       final bytes = await image.readAsBytes();
//       final base64Image = base64Encode(bytes);

//       // Get file extension to determine MIME type
//       final extension = image.path.split('.').last.toLowerCase();
//       String mimeType;

//       switch (extension) {
//         case 'jpg':
//         case 'jpeg':
//           mimeType = 'image/jpeg';
//           break;
//         case 'png':
//           mimeType = 'image/png';
//           break;
//         case 'gif':
//           mimeType = 'image/gif';
//           break;
//         case 'webp':
//           mimeType = 'image/webp';
//           break;
//         default:
//           mimeType = 'image/jpeg';
//       }

//       return 'data:$mimeType;base64,$base64Image';
//     } catch (e) {
//       debugPrint('🔴 AddPostService: Error converting image to base64: $e');
//       rethrow;
//     }
//   }

//   // REMOVED: uploadImage and uploadImages methods - they're not needed and are failing

//   // Direct base64 approach - send base64 images directly to the post endpoint
//   Future<List<String>> getImageUrlsFromBase64(List<File> images) async {
//     List<String> imageUrls = [];

//     for (var i = 0; i < images.length; i++) {
//       try {
//         debugPrint(
//           '🖼️ AddPostService: Converting image ${i + 1}/${images.length} to base64',
//         );
//         final base64Url = await imageToBase64Url(images[i]);
//         imageUrls.add(base64Url);
//         debugPrint('✅ AddPostService: Image ${i + 1} converted successfully');
//       } catch (e) {
//         debugPrint('🔴 AddPostService: Failed to convert image ${i + 1}: $e');
//         // Continue with other images
//       }
//     }

//     debugPrint(
//       '✅ AddPostService: Converted ${imageUrls.length} images to base64',
//     );
//     return imageUrls;
//   }

//   // Create product post with direct base64 images
//   Future<CreateProductResponse> createProductPost(
//     CreateProductRequest request,
//   ) async {
//     try {
//       final token = await _getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       // Ensure images are provided
//       final images = request.images ?? [];
//       if (images.isEmpty) {
//         throw Exception('At least one image is required for product posts');
//       }

//       // Convert request to JSON
//       final Map<String, dynamic> requestBody = {
//         'title': request.title,
//         'description': request.description,
//         'categoryId': request.categoryId,
//         'images': images, // These should be base64 data URLs
//         'location': request.location,
//         'barterStatus': request.barterStatus,
//         'price': request.price,
//       };

//       final url = '${ApiConstants.baseUrl}/me/posts/products';
//       debugPrint('🌐 AddPostService: Creating product post: $url');
//       debugPrint(
//         '📦 AddPostService: Request body: ${json.encode(requestBody)}',
//       );

//       final response = await _client
//           .post(
//             Uri.parse(url),
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//             body: json.encode(requestBody),
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📨 AddPostService: Response status: ${response.statusCode}');
//       debugPrint('📄 AddPostService: Response body: ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         debugPrint('✅ AddPostService: Product created successfully');
//         return CreateProductResponse.fromJson(jsonResponse);
//       } else {
//         throw Exception(
//           'Failed to create product: ${response.statusCode} - ${response.body}',
//         );
//       }
//     } catch (e) {
//       debugPrint('🔴 AddPostService: Error creating product: $e');
//       rethrow;
//     }
//   }

//   // Create service post
//   Future<CreateServiceResponse> createServicePost(
//     CreateServiceRequest request,
//   ) async {
//     try {
//       final token = await _getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       // Convert request to JSON
//       final Map<String, dynamic> requestBody = {
//         'title': request.title,
//         'description': request.description,
//         'categoryId': request.categoryId,
//         'images': request.images ?? [], // Services might have optional images
//         'status': request.status,
//         'price': request.price,
//       };

//       final url = '${ApiConstants.baseUrl}/me/posts/services';
//       debugPrint('🌐 AddPostService: Creating service post: $url');
//       debugPrint(
//         '📦 AddPostService: Request body: ${json.encode(requestBody)}',
//       );

//       final response = await _client
//           .post(
//             Uri.parse(url),
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//             body: json.encode(requestBody),
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📨 AddPostService: Response status: ${response.statusCode}');
//       debugPrint('📄 AddPostService: Response body: ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         debugPrint('✅ AddPostService: Service created successfully');
//         return CreateServiceResponse.fromJson(jsonResponse);
//       } else {
//         throw Exception(
//           'Failed to create service: ${response.statusCode} - ${response.body}',
//         );
//       }
//     } catch (e) {
//       debugPrint('🔴 AddPostService: Error creating service: $e');
//       rethrow;
//     }
//   }

//   void dispose() {
//     _client.close();
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:Yempover_app/models/add_post_model.dart';
import 'package:Yempover_app/services/token_service.dart';

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
        throw Exception('No authentication token found');
      }

      // Ensure images are provided
      final images = request.images ?? [];
      if (images.isEmpty) {
        throw Exception('At least one image is required for product posts');
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
        'price': request.price,
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
          'Failed to create product: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('🔴 AddPostService: Error creating product: $e');
      rethrow;
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
        throw Exception('No authentication token found');
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
        throw Exception(
          'Failed to create service: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('🔴 AddPostService: Error creating service: $e');
      rethrow;
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
