// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:yempower_app/constants/api_constants.dart';
// import 'package:yempower_app/models/ProductPost.dart';
// import 'package:yempower_app/models/ProductPostmain.dart' hide ProductPost;

// class PostService {
//   static final PostService _instance = PostService._internal();
//   factory PostService() => _instance;
//   PostService._internal();

//   Future<PostsResponse> getPosts({
//     int page = 1,
//     int limit = 20,
//     String? type,
//     String? categoryId,
//     String? status,
//     String? location,
//     double? radius,
//   }) async {
//     try {
//       debugPrint('🌐 PostService: Fetching posts - page: $page, limit: $limit');

//       // Build query parameters
//       final Map<String, String> queryParams = {
//         'page': page.toString(),
//         'limit': limit.toString(),
//       };

//       if (type != null) queryParams['type'] = type;
//       if (categoryId != null) queryParams['categoryId'] = categoryId;
//       if (status != null) queryParams['status'] = status;
//       if (location != null) queryParams['location'] = location;
//       if (radius != null) queryParams['radius'] = radius.toString();

//       final uri = Uri.parse('${ApiConstants.baseUrl}/posts').replace(
//         queryParameters: queryParams,
//       );

//       debugPrint('📡 PostService: Request URL: $uri');

//       final response = await http.get(
//         uri,
//         headers: ApiConstants.headers,
//       ).timeout(const Duration(seconds: 30));

//       debugPrint('📨 PostService: Response status: ${response.statusCode}');
//       debugPrint('📄 PostService: Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
        
//         if (responseData['status'] == 'success') {
//           final postsResponse = PostsResponse.fromJson(responseData);
//           debugPrint('✅ PostService: Successfully fetched ${postsResponse.data.posts.length} posts');
//           return postsResponse;
//         } else {
//           throw Exception(responseData['message'] ?? 'Failed to fetch posts');
//         }
//       } else if (response.statusCode == 401) {
//         throw Exception('Authentication required');
//       } else if (response.statusCode == 500) {
//         throw Exception('Server error');
//       } else {
//         final Map<String, dynamic> errorData = json.decode(response.body);
//         throw Exception(errorData['message'] ?? 'Failed to fetch posts');
//       }
//     } on http.ClientException catch (e) {
//       debugPrint('🔴 PostService: Network error: ${e.message}');
//       throw Exception('Network error: ${e.message}');
//     } on FormatException catch (e) {
//       debugPrint('🔴 PostService: Format error: $e');
//       throw Exception('Invalid response format');
//     } catch (e) {
//       debugPrint('🔴 PostService: Error: $e');
//       rethrow;
//     }
//   }

//   Future<ProductPost> getPostDetail(String postId, {String type = 'product'}) async {
//     try {
//       debugPrint('🌐 PostService: Fetching post detail for ID: $postId');

//       final uri = Uri.parse('${ApiConstants.baseUrl}/posts/$postId')
//           .replace(queryParameters: {'type': type});

//       debugPrint('📡 PostService: Request URL: $uri');

//       final response = await http.get(
//         uri,
//         headers: ApiConstants.headers,
//       ).timeout(const Duration(seconds: 30));

//       debugPrint('📨 PostService: Response status: ${response.statusCode}');
//       debugPrint('📄 PostService: Response body: ${response.body}');

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
        
//         if (responseData['status'] == 'success') {
//           final postData = responseData['data']['post'];
//           final post = ProductPost.fromJson(postData);
//           debugPrint('✅ PostService: Successfully fetched post detail');
//           return post;
//         } else {
//           throw Exception(responseData['message'] ?? 'Failed to fetch post detail');
//         }
//       } else if (response.statusCode == 404) {
//         throw Exception('Post not found');
//       } else if (response.statusCode == 500) {
//         throw Exception('Server error');
//       } else {
//         final Map<String, dynamic> errorData = json.decode(response.body);
//         throw Exception(errorData['message'] ?? 'Failed to fetch post detail');
//       }
//     } on http.ClientException catch (e) {
//       debugPrint('🔴 PostService: Network error: ${e.message}');
//       throw Exception('Network error: ${e.message}');
//     } on FormatException catch (e) {
//       debugPrint('🔴 PostService: Format error: $e');
//       throw Exception('Invalid response format');
//     } catch (e) {
//       debugPrint('🔴 PostService: Error: $e');
//       rethrow;
//     }
//   }

//   Future<void> toggleFavorite(String postId, bool isCurrentlyFavorite) async {
//     try {
//       debugPrint('🌐 PostService: Toggling favorite for post: $postId');
      
//       // Simulate API call - replace with actual endpoint
//       await Future.delayed(const Duration(milliseconds: 500));
      
//       debugPrint('✅ PostService: Favorite toggled successfully');
//     } catch (e) {
//       debugPrint('🔴 PostService: Error toggling favorite: $e');
//       rethrow;
//     }
//   }

//   Future<void> hidePost(String postId) async {
//     try {
//       debugPrint('🌐 PostService: Hiding post: $postId');
      
//       // Simulate API call - replace with actual endpoint
//       await Future.delayed(const Duration(milliseconds: 500));
      
//       debugPrint('✅ PostService: Post hidden successfully');
//     } catch (e) {
//       debugPrint('🔴 PostService: Error hiding post: $e');
//       rethrow;
//     }
//   }

//   Future<void> reportPost(String postId, String reason) async {
//     try {
//       debugPrint('🌐 PostService: Reporting post: $postId, reason: $reason');
      
//       // Simulate API call - replace with actual endpoint
//       await Future.delayed(const Duration(milliseconds: 500));
      
//       debugPrint('✅ PostService: Post reported successfully');
//     } catch (e) {
//       debugPrint('🔴 PostService: Error reporting post: $e');
//       rethrow;
//     }
//   }

//   Future<List<String>> getCategories() async {
//     try {
//       debugPrint('🌐 PostService: Fetching categories');
      
//       // Simulate API call - replace with actual endpoint
//       await Future.delayed(const Duration(milliseconds: 500));
      
//       // Return mock categories - replace with actual API response
//       return ['Electronics', 'Furniture', 'Books', 'Fashion', 'Services', 'Home Appliances'];
//     } catch (e) {
//       debugPrint('🔴 PostService: Error fetching categories: $e');
//       rethrow;
//     }
//   }
// }