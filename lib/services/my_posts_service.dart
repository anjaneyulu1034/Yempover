// // lib/services/my_posts_service.dart
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:YemPover_app/services/token_service.dart';
// import 'package:YemPover_app/constants/api_constants.dart';
// import 'package:YemPover_app/models/my_post_model.dart';
// import 'package:YemPover_app/models/api_response.dart'; // Add this import

// class MyPostsService {
//   static final MyPostsService _instance = MyPostsService._internal();
//   factory MyPostsService() => _instance;
//   MyPostsService._internal();

//   Future<String?> _getToken() async {
//     final token = await TokenService().getToken();
//     debugPrint(
//       '🔑 MyPostsService: Token retrieved: ${token != null ? 'Yes (${token.substring(0, token.length > 20 ? 20 : token.length)}...)' : 'No'}',
//     );
//     return token;
//   }

//   Future<MyPostsResponse> getMyPosts({int page = 1, int limit = 20}) async {
//     // Create a new client for this request
//     final client = http.Client();

//     try {
//       final token = await _getToken();
//       if (token == null || token.isEmpty) {
//         debugPrint('🔴 MyPostsService: No authentication token found');
//         throw Exception('No authentication token found. Please login again.');
//       }

//       final url = '${ApiConstants.baseUrl}/me/posts?page=$page&limit=$limit';
//       debugPrint('🌐 MyPostsService: Fetching my posts from: $url');

//       final response = await client
//           .get(
//             Uri.parse(url),
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📨 MyPostsService: Response status: ${response.statusCode}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         debugPrint('✅ MyPostsService: Posts fetched successfully');
//         return MyPostsResponse.fromJson(jsonResponse);
//       } else if (response.statusCode == 401) {
//         debugPrint(
//           '🔴 MyPostsService: Unauthorized - Token expired or invalid',
//         );
//         // Clear invalid token
//         await TokenService().clearTokens();
//         throw Exception('Session expired. Please login again.');
//       } else {
//         throw Exception('Failed to load posts: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('🔴 MyPostsService: Error fetching my posts: $e');
//       rethrow;
//     } finally {
//       // Always close the client
//       client.close();
//     }
//   }

//   // ADD THIS NEW METHOD - Update Post (Product or Service)
//   Future<ApiResponse> updatePost(
//     String postId,
//     Map<String, dynamic> data,
//   ) async {
//     final client = http.Client();

//     try {
//       final token = await _getToken();
//       if (token == null || token.isEmpty) {
//         throw Exception('No authentication token found. Please login again.');
//       }

//       // Determine if it's a product or service based on the data
//       final bool isProduct =
//           data['type'] == 'product' ||
//           (data['categoryId'] != null &&
//               !data.containsKey('serviceSpecificField'));

//       // Use the correct endpoint based on post type
//       final String endpoint = isProduct
//           ? '${ApiConstants.products}/$postId'
//           : '${ApiConstants.services}/$postId';

//       debugPrint('🌐 MyPostsService: Updating post at: $endpoint');
//       debugPrint('📦 Request data: ${json.encode(data)}');

//       final response = await client
//           .put(
//             Uri.parse(endpoint),
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//             body: json.encode(data),
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📨 Update response status: ${response.statusCode}');
//       debugPrint('📨 Update response body: ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         return ApiResponse.fromJson(
//           jsonResponse,
//           (json) => MyPost.fromJson(json),
//         );
//       } else if (response.statusCode == 401) {
//         await TokenService().clearTokens();
//         throw Exception('Session expired. Please login again.');
//       } else if (response.statusCode == 404) {
//         throw Exception('Post not found');
//       } else {
//         throw Exception(
//           'Failed to update post: ${response.statusCode} - ${response.body}',
//         );
//       }
//     } catch (e) {
//       debugPrint('🔴 MyPostsService: Error updating post: $e');
//       rethrow;
//     } finally {
//       client.close();
//     }
//   }

//   Future<void> deletePost(String postId) async {
//     final client = http.Client();

//     try {
//       final token = await _getToken();
//       if (token == null || token.isEmpty) {
//         throw Exception('No authentication token found. Please login again.');
//       }

//       final url = '${ApiConstants.baseUrl}/posts/$postId';
//       debugPrint('🌐 MyPostsService: Deleting post: $url');

//       final response = await client
//           .delete(
//             Uri.parse(url),
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(const Duration(seconds: 30));

//       if (response.statusCode == 200 || response.statusCode == 204) {
//         debugPrint('✅ MyPostsService: Post deleted successfully');
//         return;
//       } else if (response.statusCode == 401) {
//         await TokenService().clearTokens();
//         throw Exception('Session expired. Please login again.');
//       } else if (response.statusCode == 404) {
//         throw Exception('Post not found');
//       } else {
//         throw Exception('Failed to delete post: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('🔴 MyPostsService: Error deleting post: $e');
//       rethrow;
//     } finally {
//       client.close();
//     }
//   }

//   Future<void> updatePostStatus(String postId, String status) async {
//     final client = http.Client();

//     try {
//       final token = await _getToken();
//       if (token == null || token.isEmpty) {
//         throw Exception('No authentication token found. Please login again.');
//       }

//       final url = '${ApiConstants.baseUrl}/posts/$postId/status';
//       debugPrint('🌐 MyPostsService: Updating post status: $url');

//       final response = await client
//           .patch(
//             Uri.parse(url),
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//             body: json.encode({'status': status}),
//           )
//           .timeout(const Duration(seconds: 30));

//       if (response.statusCode == 200 || response.statusCode == 204) {
//         debugPrint('✅ MyPostsService: Post status updated successfully');
//         return;
//       } else if (response.statusCode == 401) {
//         await TokenService().clearTokens();
//         throw Exception('Session expired. Please login again.');
//       } else if (response.statusCode == 404) {
//         throw Exception('Post not found');
//       } else {
//         throw Exception('Failed to update post status: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('🔴 MyPostsService: Error updating post status: $e');
//       rethrow;
//     } finally {
//       client.close();
//     }
//   }

//   // Get post by ID
//   Future<ApiResponse> getPostById(String postId) async {
//     final client = http.Client();

//     try {
//       final token = await _getToken();
//       if (token == null || token.isEmpty) {
//         throw Exception('No authentication token found. Please login again.');
//       }

//       final url = ApiConstants.postDetail(postId);
//       debugPrint('🌐 MyPostsService: Fetching post by ID: $url');

//       final response = await client
//           .get(
//             Uri.parse(url),
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(const Duration(seconds: 30));

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> jsonResponse = json.decode(response.body);
//         return ApiResponse.fromJson(
//           jsonResponse,
//           (json) => MyPost.fromJson(json),
//         );
//       } else if (response.statusCode == 401) {
//         await TokenService().clearTokens();
//         throw Exception('Session expired. Please login again.');
//       } else if (response.statusCode == 404) {
//         throw Exception('Post not found');
//       } else {
//         throw Exception('Failed to load post: ${response.statusCode}');
//       }
//     } catch (e) {
//       debugPrint('🔴 MyPostsService: Error fetching post: $e');
//       rethrow;
//     } finally {
//       client.close();
//     }
//   }

//   // Remove dispose method since we're not keeping a persistent client
//   // void dispose() {
//   //   _client.close();
//   // }
// }

// int min(int a, int b) => a < b ? a : b;

// lib/services/my_posts_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/models/my_post_model.dart';
import 'package:YemPover_app/models/api_response.dart';

class MyPostsService {
  static final MyPostsService _instance = MyPostsService._internal();
  factory MyPostsService() => _instance;
  MyPostsService._internal();

  Future<String?> _getToken() async {
    final token = await TokenService().getToken();
    debugPrint(
      '🔑 MyPostsService: Token retrieved: ${token != null ? 'Yes (${token.substring(0, token.length > 20 ? 20 : token.length)}...)' : 'No'}',
    );
    return token;
  }

  Future<MyPostsResponse> getMyPosts({int page = 1, int limit = 20}) async {
    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint('🔴 MyPostsService: No authentication token found');
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '${ApiConstants.baseUrl}/me/posts?page=$page&limit=$limit';
      debugPrint('🌐 MyPostsService: Fetching my posts from: $url');

      final response = await client
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 MyPostsService: Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint('✅ MyPostsService: Posts fetched successfully');
        return MyPostsResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        debugPrint(
          '🔴 MyPostsService: Unauthorized - Token expired or invalid',
        );
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 MyPostsService: Error fetching my posts: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<List<String>> uploadPostImagesBase64(List<String> images) async {
    if (images.isEmpty) return const [];

    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final endpoint = '${ApiConstants.baseUrl}/me/posts/images/base64';
      debugPrint('🌐 MyPostsService: Uploading post images to: $endpoint');
      debugPrint('📦 Upload image count: ${images.length}');

      final response = await client
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'images': images}),
          )
          .timeout(const Duration(seconds: 60));

      debugPrint('📨 Image upload response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final data = jsonResponse['data'];
        final urls = (data is Map<String, dynamic> && data['urls'] is List)
            ? (data['urls'] as List)
                  .map((e) => e.toString().trim())
                  .where((e) => e.isNotEmpty)
                  .toList()
            : <String>[];

        if (urls.isEmpty) {
          throw Exception('Image upload failed. No image URLs returned.');
        }

        return urls;
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Failed to upload images: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('🔴 MyPostsService: Error uploading images: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  // FIXED: Update Post method with correct endpoint based on post type
  Future<ApiResponse> updatePost(
    String postId,
    Map<String, dynamic> data,
  ) async {
    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      // Determine the correct endpoint based on post type
      // We need to pass the type in the request data
      final String postType = data['type'] ?? 'product';

      // Use the correct endpoint based on post type
      final String endpoint;
      if (postType == 'service') {
        endpoint = '${ApiConstants.baseUrl}/me/posts/services/$postId';
      } else {
        endpoint = '${ApiConstants.baseUrl}/me/posts/products/$postId';
      }

      debugPrint('🌐 MyPostsService: Updating post at: $endpoint');
      debugPrint('📦 Request data: ${json.encode(data)}');
      debugPrint('📦 Post type: $postType');

      final response = await client
          .put(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📨 Update response status: ${response.statusCode}');
      debugPrint('📨 Update response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(
          jsonResponse,
          (json) => MyPost.fromJson(json),
        );
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception(
          'Failed to update post: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('🔴 MyPostsService: Error updating post: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> deletePost(String postId) async {
    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '${ApiConstants.baseUrl}/posts/$postId';
      debugPrint('🌐 MyPostsService: Deleting post: $url');

      final response = await client
          .delete(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ MyPostsService: Post deleted successfully');
        return;
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 MyPostsService: Error deleting post: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<void> updatePostStatus(String postId, String status) async {
    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '${ApiConstants.baseUrl}/posts/$postId/status';
      debugPrint('🌐 MyPostsService: Updating post status: $url');

      final response = await client
          .patch(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'status': status}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        debugPrint('✅ MyPostsService: Post status updated successfully');
        return;
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to update post status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 MyPostsService: Error updating post status: $e');
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<ApiResponse> getPostById(String postId) async {
    final client = http.Client();

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = ApiConstants.postDetail(postId);
      debugPrint('🌐 MyPostsService: Fetching post by ID: $url');

      final response = await client
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(
          jsonResponse,
          (json) => MyPost.fromJson(json),
        );
      } else if (response.statusCode == 401) {
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 MyPostsService: Error fetching post: $e');
      rethrow;
    } finally {
      client.close();
    }
  }
}

int min(int a, int b) => a < b ? a : b;
