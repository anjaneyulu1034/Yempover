// import 'dart:convert';
// import 'package:Yempover_app/models/favorites_response.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:Yempover_app/constants/api_constants.dart';
// import 'package:Yempover_app/models/ProductPostmain.dart';
// import 'package:Yempover_app/models/hide_post_response.dart';
// import 'package:Yempover_app/models/report_post_response.dart';
// import 'package:Yempover_app/services/token_service.dart';

// class PostActionService {
//   final TokenService _tokenService = TokenService();

//   // ========== FAVORITE METHODS ==========

//   // Add to favorites (auto-detects type)
//   Future<AddFavoriteResponse> addToFavorites({
//     required String postId,
//     required bool isService,
//   }) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites');

//       final Map<String, dynamic> body = {};
//       if (isService) {
//         body['serviceId'] = postId;
//       } else {
//         body['productId'] = postId;
//       }

//       debugPrint(
//         '📱 Adding to favorites - Post ID: $postId, Type: ${isService ? 'Service' : 'Product'}',
//       );

//       final response = await http
//           .post(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📱 Add to favorites response: ${response.statusCode}');
//       debugPrint('📱 Add to favorites body: ${response.body}');

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return AddFavoriteResponse.fromJson(responseData);
//       } else if (response.statusCode == 409) {
//         // Already favorited - treat as success but show message
//         throw Exception(responseData['message'] ?? 'Already in favorites');
//       } else {
//         throw Exception(
//           responseData['message'] ?? 'Failed to add to favorites',
//         );
//       }
//     } catch (e) {
//       debugPrint('📱 Error adding to favorites: $e');
//       rethrow;
//     }
//   }

//   // Remove from favorites - CORRECTED to use POST with body instead of DELETE with ID
//   Future<RemoveFavoriteResponse> removeFromFavorites({
//     required String postId,
//     required bool isService,
//   }) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites');

//       final Map<String, dynamic> body = {};
//       if (isService) {
//         body['serviceId'] = postId;
//       } else {
//         body['productId'] = postId;
//       }

//       debugPrint(
//         '📱 Removing from favorites - Post ID: $postId, Type: ${isService ? 'Service' : 'Product'}',
//       );

//       // Using DELETE with body - some servers support this
//       final request = http.Request('DELETE', url);
//       request.headers.addAll({
//         ...ApiConstants.headers,
//         'Authorization': 'Bearer $token',
//       });
//       request.body = jsonEncode(body);

//       final streamedResponse = await request.send();
//       final response = await http.Response.fromStream(streamedResponse);

//       debugPrint('📱 Remove from favorites response: ${response.statusCode}');
//       debugPrint('📱 Remove from favorites body: ${response.body}');

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return RemoveFavoriteResponse.fromJson(responseData);
//       } else {
//         throw Exception(
//           responseData['message'] ?? 'Failed to remove from favorites',
//         );
//       }
//     } catch (e) {
//       debugPrint('📱 Error removing from favorites: $e');
//       rethrow;
//     }
//   }

//   // Alternative method using POST with _method override if DELETE with body doesn't work
//   Future<RemoveFavoriteResponse> removeFromFavoritesWithPost({
//     required String postId,
//     required bool isService,
//   }) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites');

//       final Map<String, dynamic> body = {};
//       if (isService) {
//         body['serviceId'] = postId;
//       } else {
//         body['productId'] = postId;
//       }
//       // Add method override for servers that don't support DELETE with body
//       body['_method'] = 'DELETE';

//       debugPrint(
//         '📱 Removing from favorites (POST with override) - Post ID: $postId',
//       );

//       final response = await http
//           .post(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📱 Remove from favorites response: ${response.statusCode}');
//       debugPrint('📱 Remove from favorites body: ${response.body}');

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return RemoveFavoriteResponse.fromJson(responseData);
//       } else {
//         throw Exception(
//           responseData['message'] ?? 'Failed to remove from favorites',
//         );
//       }
//     } catch (e) {
//       debugPrint('📱 Error removing from favorites: $e');
//       rethrow;
//     }
//   }

//   // Get favorites list
//   Future<FavoritesResponse> getFavorites({int page = 1, int limit = 20}) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse(
//         '${ApiConstants.baseUrl}/me/favorites?page=$page&limit=$limit',
//       );

//       debugPrint('📱 Fetching favorites - Page: $page, Limit: $limit');

//       final response = await http
//           .get(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📱 Get favorites response: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         return FavoritesResponse.fromJson(responseData);
//       } else {
//         final responseData = jsonDecode(response.body);
//         throw Exception(responseData['message'] ?? 'Failed to get favorites');
//       }
//     } catch (e) {
//       debugPrint('📱 Error getting favorites: $e');
//       rethrow;
//     }
//   }

//   // Check if post is a service
//   Future<bool> isServicePost(String postId) async {
//     try {
//       final post = await getPostById(postId);
//       return post.type == PostType.service;
//     } catch (e) {
//       return false;
//     }
//   }

//   // ========== EXISTING METHODS ==========

//   // Hide a post
//   Future<HidePostResponse> hidePost(String postId) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final isService = await isServicePost(postId);

//       final url = Uri.parse('${ApiConstants.baseUrl}/me/hidden-posts');

//       final Map<String, dynamic> body = {};
//       if (isService) {
//         body['serviceId'] = postId;
//       } else {
//         body['productId'] = postId;
//       }

//       debugPrint(
//         '📱 Hiding post - Post ID: $postId, Type: ${isService ? 'Service' : 'Product'}',
//       );

//       final response = await http
//           .post(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📱 Hide post response: ${response.statusCode}');

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return HidePostResponse.fromJson(responseData);
//       } else {
//         throw Exception(responseData['message'] ?? 'Failed to hide post');
//       }
//     } catch (e) {
//       debugPrint('📱 Error hiding post: $e');
//       rethrow;
//     }
//   }

//   // Unhide a post
//   Future<HidePostResponse> unhidePost(String hiddenPostId) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse(
//         '${ApiConstants.baseUrl}/me/hidden-posts/$hiddenPostId',
//       );

//       debugPrint('📱 Unhiding post - Hidden Post ID: $hiddenPostId');

//       final response = await http
//           .delete(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📱 Unhide post response: ${response.statusCode}');

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return HidePostResponse.fromJson(responseData);
//       } else {
//         throw Exception(responseData['message'] ?? 'Failed to unhide post');
//       }
//     } catch (e) {
//       debugPrint('📱 Error unhiding post: $e');
//       rethrow;
//     }
//   }

//   // Report a post
//   Future<ReportPostResponse> reportPost({
//     required String postId,
//     required String reason,
//     String? description,
//   }) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final isService = await isServicePost(postId);

//       final url = Uri.parse('${ApiConstants.baseUrl}/reports');

//       final Map<String, dynamic> body = {'reason': reason};

//       if (isService) {
//         body['serviceId'] = postId;
//       } else {
//         body['productId'] = postId;
//       }

//       if (description != null && description.isNotEmpty) {
//         body['description'] = description;
//       }

//       debugPrint('📱 Reporting post - Post ID: $postId');

//       final response = await http
//           .post(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📱 Report post response: ${response.statusCode}');

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return ReportPostResponse.fromJson(responseData);
//       } else {
//         throw Exception(responseData['message'] ?? 'Failed to report post');
//       }
//     } catch (e) {
//       debugPrint('📱 Error reporting post: $e');
//       rethrow;
//     }
//   }

//   // Get a single post by ID
//   Future<Post> getPostById(String postId) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/posts/$postId');

//       debugPrint('📱 Fetching post by ID: $postId');

//       final response = await http
//           .get(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(const Duration(seconds: 30));

//       debugPrint('📱 Get post response: ${response.statusCode}');

//       if (response.statusCode == 200) {
//         final responseData = jsonDecode(response.body);
//         final postData = responseData['data'] ?? responseData;
//         return Post.fromJson(postData);
//       } else {
//         final responseData = jsonDecode(response.body);
//         throw Exception(responseData['message'] ?? 'Failed to fetch post');
//       }
//     } catch (e) {
//       debugPrint('📱 Error fetching post: $e');
//       rethrow;
//     }
//   }
// }

import 'dart:convert';
import 'package:Yempover_app/models/favorites_response.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:Yempover_app/models/ProductPostmain.dart';
import 'package:Yempover_app/models/hide_post_response.dart';
import 'package:Yempover_app/models/report_post_response.dart';
import 'package:Yempover_app/services/token_service.dart';

class PostActionService {
  final TokenService _tokenService = TokenService();

  // ========== FAVORITE METHODS ==========

  // Add to favorites (auto-detects type)
  Future<AddFavoriteResponse> addToFavorites({
    required String postId,
    required bool isService,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites');

      final Map<String, dynamic> body = {};
      if (isService) {
        body['serviceId'] = postId;
      } else {
        body['productId'] = postId;
      }

      debugPrint(
        '📱 Adding to favorites - Post ID: $postId, Type: ${isService ? 'Service' : 'Product'}',
      );

      final response = await http
          .post(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📱 Add to favorites response: ${response.statusCode}');
      debugPrint('📱 Add to favorites body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AddFavoriteResponse.fromJson(responseData);
      } else if (response.statusCode == 409) {
        // Already favorited - treat as success but show message
        throw Exception(responseData['message'] ?? 'Already in favorites');
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to add to favorites',
        );
      }
    } catch (e) {
      debugPrint('📱 Error adding to favorites: $e');
      rethrow;
    }
  }

  // Remove from favorites - CORRECTED to use POST with body instead of DELETE with ID
  Future<RemoveFavoriteResponse> removeFromFavorites({
    required String postId,
    required bool isService,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites');

      final Map<String, dynamic> body = {};
      if (isService) {
        body['serviceId'] = postId;
      } else {
        body['productId'] = postId;
      }

      debugPrint(
        '📱 Removing from favorites - Post ID: $postId, Type: ${isService ? 'Service' : 'Product'}',
      );

      // Using DELETE with body - some servers support this
      final request = http.Request('DELETE', url);
      request.headers.addAll({
        ...ApiConstants.headers,
        'Authorization': 'Bearer $token',
      });
      request.body = jsonEncode(body);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📱 Remove from favorites response: ${response.statusCode}');
      debugPrint('📱 Remove from favorites body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return RemoveFavoriteResponse.fromJson(responseData);
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to remove from favorites',
        );
      }
    } catch (e) {
      debugPrint('📱 Error removing from favorites: $e');
      rethrow;
    }
  }

  // Alternative method using POST with _method override if DELETE with body doesn't work
  Future<RemoveFavoriteResponse> removeFromFavoritesWithPost({
    required String postId,
    required bool isService,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites');

      final Map<String, dynamic> body = {};
      if (isService) {
        body['serviceId'] = postId;
      } else {
        body['productId'] = postId;
      }
      // Add method override for servers that don't support DELETE with body
      body['_method'] = 'DELETE';

      debugPrint(
        '📱 Removing from favorites (POST with override) - Post ID: $postId',
      );

      final response = await http
          .post(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📱 Remove from favorites response: ${response.statusCode}');
      debugPrint('📱 Remove from favorites body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return RemoveFavoriteResponse.fromJson(responseData);
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to remove from favorites',
        );
      }
    } catch (e) {
      debugPrint('📱 Error removing from favorites: $e');
      rethrow;
    }
  }

  // Get favorites list
  Future<FavoritesResponse> getFavorites({int page = 1, int limit = 20}) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/me/favorites?page=$page&limit=$limit',
      );

      debugPrint('📱 Fetching favorites - Page: $page, Limit: $limit');

      final response = await http
          .get(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📱 Get favorites response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return FavoritesResponse.fromJson(responseData);
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to get favorites');
      }
    } catch (e) {
      debugPrint('📱 Error getting favorites: $e');
      rethrow;
    }
  }

  // ========== HELPER METHODS ==========

  // Safe post parser
  Post _safeParsePost(Map<String, dynamic> json) {
    try {
      // Ensure all required fields have default values
      final safeJson = {
        'id': json['id'] ?? json['_id'] ?? '',
        'title': json['title'] ?? 'Untitled',
        'description': json['description'] ?? '',
        'images': json['images'] ?? [],
        'status': json['status'] ?? 'FOR_SALE',
        'barterStatus': json['barterStatus'] ?? 'NO_BARTER',
        'price': (json['price'] ?? 0).toDouble(),
        'categoryId': json['categoryId'] ?? '',
        'latitude': json['latitude'],
        'longitude': json['longitude'],
        'location': json['location'] ?? 'Location not specified',
        'postedById': json['postedById'] ?? '',
        'postedDate': json['postedDate'] ?? DateTime.now().toIso8601String(),
        'viewCount': json['viewCount'] ?? 0,
        'isListed': json['isListed'] ?? true,
        'createdAt': json['createdAt'] ?? DateTime.now().toIso8601String(),
        'updatedAt': json['updatedAt'] ?? DateTime.now().toIso8601String(),
        'category':
            json['category'] ??
            {
              'id': '',
              'name': 'Uncategorized',
              'type': 'product',
              'isActive': true,
            },
        'postedBy':
            json['postedBy'] ??
            {
              'id': json['postedById'] ?? '',
              'firstName': 'Unknown',
              'lastName': 'User',
              'profileImage': null,
            },
        'type': json['type'] ?? 'product',
      };

      return Post.fromJson(safeJson);
    } catch (e) {
      debugPrint('📱 Error parsing post: $e');
      // Return a minimal valid post
      return Post(
        id: json['id'] ?? json['_id'] ?? '',
        title: json['title'] ?? 'Untitled',
        description: json['description'] ?? '',
        images: json['images'] ?? [],
        status: PostStatus.FOR_SALE,
        barterStatus: BarterStatus.NO_BARTER,
        price: (json['price'] ?? 0).toDouble(),
        categoryId: json['categoryId'] ?? '',
        latitude: null,
        longitude: null,
        location: json['location'] ?? '',
        postedById: json['postedById'] ?? '',
        postedDate: DateTime.now(),
        viewCount: 0,
        isListed: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: Category(
          id: '',
          name: 'Unknown',
          type: 'product',
          isActive: true,
        ),
        postedBy: User(
          id: json['postedById'] ?? '',
          firstName: 'Unknown',
          lastName: 'User',
          profileImage: null,
        ),
        type: PostType.product,
      );
    }
  }

  // Check if post is a service
  Future<bool> isServicePost(String postId) async {
    try {
      final post = await getPostById(postId);
      return post.type == PostType.service;
    } catch (e) {
      debugPrint('📱 Error checking if post is service: $e');
      // Try to determine from status or return false as default
      return false;
    }
  }

  // Get a single post by ID
  Future<Post> getPostById(String postId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/posts/$postId');

      debugPrint('📱 Fetching post by ID: $postId');

      final response = await http
          .get(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📱 Get post response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle different response structures
        Map<String, dynamic> postData;
        if (responseData['data'] != null) {
          if (responseData['data']['post'] != null) {
            postData = responseData['data']['post'];
          } else {
            postData = responseData['data'];
          }
        } else {
          postData = responseData;
        }

        debugPrint('📱 Post data parsed: ${postData.keys}');

        // Use safe parsing
        return _safeParsePost(postData);
      } else {
        final responseData = jsonDecode(response.body);
        throw Exception(responseData['message'] ?? 'Failed to fetch post');
      }
    } catch (e) {
      debugPrint('📱 Error fetching post: $e');
      rethrow;
    }
  }

  // ========== HIDE POST METHOD ==========

  // Hide a post
  Future<HidePostResponse> hidePost(String postId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      // Try to determine if it's a service post, but don't fail if we can't
      bool isService = false;
      try {
        isService = await isServicePost(postId);
      } catch (e) {
        debugPrint(
          '📱 Could not determine post type, defaulting to product: $e',
        );
        // Default to product if we can't determine
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/me/hidden-posts');

      final Map<String, dynamic> body = {};
      if (isService) {
        body['serviceId'] = postId;
      } else {
        body['productId'] = postId;
      }

      debugPrint(
        '📱 Hiding post - Post ID: $postId, Type: ${isService ? 'Service' : 'Product'}',
      );
      debugPrint('📱 Request body: $body');

      final response = await http
          .post(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📱 Hide post response: ${response.statusCode}');
      debugPrint('📱 Hide post body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return HidePostResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to hide post');
      }
    } catch (e) {
      debugPrint('📱 Error hiding post: $e');
      rethrow;
    }
  }

  // Unhide a post
  Future<HidePostResponse> unhidePost(String hiddenPostId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/me/hidden-posts/$hiddenPostId',
      );

      debugPrint('📱 Unhiding post - Hidden Post ID: $hiddenPostId');

      final response = await http
          .delete(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📱 Unhide post response: ${response.statusCode}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return HidePostResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to unhide post');
      }
    } catch (e) {
      debugPrint('📱 Error unhiding post: $e');
      rethrow;
    }
  }

  // Report a post
  Future<ReportPostResponse> reportPost({
    required String postId,
    required String reason,
    String? description,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final isService = await isServicePost(postId);

      final url = Uri.parse('${ApiConstants.baseUrl}/reports');

      final Map<String, dynamic> body = {'reason': reason};

      if (isService) {
        body['serviceId'] = postId;
      } else {
        body['productId'] = postId;
      }

      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      debugPrint('📱 Reporting post - Post ID: $postId');

      final response = await http
          .post(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('📱 Report post response: ${response.statusCode}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReportPostResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to report post');
      }
    } catch (e) {
      debugPrint('📱 Error reporting post: $e');
      rethrow;
    }
  }
}
