// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:Yempover_app/constants/api_constants.dart';
// import '../models/favorite_response.dart';
// import '../models/hide_post_response.dart';
// import '../models/report_post_response.dart';
// import '../services/token_service.dart';

// class PostActionService {
//   final TokenService _tokenService = TokenService();

//   // Add to favorites
//   Future<FavoriteResponse> addToFavorites(String productId) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites');

//       final response = await http
//           .post(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//             body: jsonEncode({'productId': productId}),
//           )
//           .timeout(
//             const Duration(seconds: 30),
//             onTimeout: () => throw Exception('Request timeout'),
//           );

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return FavoriteResponse.fromJson(responseData);
//       } else {
//         throw Exception(
//           responseData['message'] ?? 'Failed to add to favorites',
//         );
//       }
//     } catch (e) {
//       throw Exception(e.toString().replaceAll('Exception: ', ''));
//     }
//   }

//   // Remove from favorites
//   Future<HidePostResponse> removeFromFavorites(String favoriteId) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites/$favoriteId');

//       final response = await http
//           .delete(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(
//             const Duration(seconds: 30),
//             onTimeout: () => throw Exception('Request timeout'),
//           );

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return HidePostResponse.fromJson(responseData);
//       } else {
//         throw Exception(
//           responseData['message'] ?? 'Failed to remove from favorites',
//         );
//       }
//     } catch (e) {
//       throw Exception(e.toString().replaceAll('Exception: ', ''));
//     }
//   }

//   // Hide a post
//   Future<HidePostResponse> hidePost(String productId) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/me/hidden-posts');

//       final response = await http
//           .post(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//             body: jsonEncode({'productId': productId}),
//           )
//           .timeout(
//             const Duration(seconds: 30),
//             onTimeout: () => throw Exception('Request timeout'),
//           );

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return HidePostResponse.fromJson(responseData);
//       } else {
//         throw Exception(responseData['message'] ?? 'Failed to hide post');
//       }
//     } catch (e) {
//       throw Exception(e.toString().replaceAll('Exception: ', ''));
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

//       final response = await http
//           .delete(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(
//             const Duration(seconds: 30),
//             onTimeout: () => throw Exception('Request timeout'),
//           );

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         return HidePostResponse.fromJson(responseData);
//       } else {
//         throw Exception(responseData['message'] ?? 'Failed to unhide post');
//       }
//     } catch (e) {
//       throw Exception(e.toString().replaceAll('Exception: ', ''));
//     }
//   }

//   // Report a post
//   Future<ReportPostResponse> reportPost({
//     required String productId,
//     required String reason,
//     String? description,
//   }) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/reports');

//       final Map<String, dynamic> body = {
//         'productId': productId,
//         'reason': reason,
//       };

//       if (description != null && description.isNotEmpty) {
//         body['description'] = description;
//       }

//       final response = await http
//           .post(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//             body: jsonEncode(body),
//           )
//           .timeout(
//             const Duration(seconds: 30),
//             onTimeout: () => throw Exception('Request timeout'),
//           );

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return ReportPostResponse.fromJson(responseData);
//       } else {
//         throw Exception(responseData['message'] ?? 'Failed to report post');
//       }
//     } catch (e) {
//       throw Exception(e.toString().replaceAll('Exception: ', ''));
//     }
//   }

//   // Get user's favorites
//   Future<List<Favorite>> getFavorites({int page = 1, int limit = 10}) async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse(
//         '${ApiConstants.baseUrl}/me/favorites?page=$page&limit=$limit',
//       );

//       final response = await http
//           .get(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(
//             const Duration(seconds: 30),
//             onTimeout: () => throw Exception('Request timeout'),
//           );

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         // Assuming the response has a data field with favorites array
//         if (responseData['data'] != null &&
//             responseData['data']['favorites'] != null) {
//           final List<dynamic> favoritesJson = responseData['data']['favorites'];
//           return favoritesJson.map((json) => Favorite.fromJson(json)).toList();
//         }
//         return [];
//       } else {
//         throw Exception(responseData['message'] ?? 'Failed to get favorites');
//       }
//     } catch (e) {
//       throw Exception(e.toString().replaceAll('Exception: ', ''));
//     }
//   }

//   // Get hidden posts
//   Future<List<String>> getHiddenPostIds() async {
//     try {
//       final token = await _tokenService.getToken();
//       if (token == null) {
//         throw Exception('No authentication token found');
//       }

//       final url = Uri.parse('${ApiConstants.baseUrl}/me/hidden-posts');

//       final response = await http
//           .get(
//             url,
//             headers: {
//               ...ApiConstants.headers,
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(
//             const Duration(seconds: 30),
//             onTimeout: () => throw Exception('Request timeout'),
//           );

//       final responseData = jsonDecode(response.body);

//       if (response.statusCode == 200) {
//         // Assuming the response has a data field with hidden post IDs
//         if (responseData['data'] != null &&
//             responseData['data']['hiddenPosts'] != null) {
//           final List<dynamic> hiddenPostsJson =
//               responseData['data']['hiddenPosts'];
//           return hiddenPostsJson
//               .map((json) => json['productId'] as String)
//               .toList();
//         }
//         return [];
//       } else {
//         throw Exception(
//           responseData['message'] ?? 'Failed to get hidden posts',
//         );
//       }
//     } catch (e) {
//       throw Exception(e.toString().replaceAll('Exception: ', ''));
//     }
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Yempover_app/constants/api_constants.dart';
import '../models/ProductPostmain.dart'; // Add this import
import '../models/favorite_response.dart';
import '../models/hide_post_response.dart';
import '../models/report_post_response.dart';
import '../services/token_service.dart';

class PostActionService {
  final TokenService _tokenService = TokenService();

  // Add to favorites
  Future<FavoriteResponse> addToFavorites(String productId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites');

      final response = await http
          .post(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'productId': productId}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FavoriteResponse.fromJson(responseData);
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to add to favorites',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Remove from favorites
  Future<HidePostResponse> removeFromFavorites(String favoriteId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/me/favorites/$favoriteId');

      final response = await http
          .delete(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return HidePostResponse.fromJson(responseData);
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to remove from favorites',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Hide a post
  Future<HidePostResponse> hidePost(String productId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/me/hidden-posts');

      final response = await http
          .post(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'productId': productId}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return HidePostResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to hide post');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
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

      final response = await http
          .delete(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return HidePostResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to unhide post');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Report a post
  Future<ReportPostResponse> reportPost({
    required String productId,
    required String reason,
    String? description,
  }) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/reports');

      final Map<String, dynamic> body = {
        'productId': productId,
        'reason': reason,
      };

      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      final response = await http
          .post(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReportPostResponse.fromJson(responseData);
      } else {
        throw Exception(responseData['message'] ?? 'Failed to report post');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Get user's favorites
  Future<List<Favorite>> getFavorites({int page = 1, int limit = 10}) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse(
        '${ApiConstants.baseUrl}/me/favorites?page=$page&limit=$limit',
      );

      final response = await http
          .get(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Assuming the response has a data field with favorites array
        if (responseData['data'] != null &&
            responseData['data']['favorites'] != null) {
          final List<dynamic> favoritesJson = responseData['data']['favorites'];
          return favoritesJson.map((json) => Favorite.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception(responseData['message'] ?? 'Failed to get favorites');
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // NEW METHOD: Get a single post by ID
  Future<Post> getPostById(String postId) async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/posts/$postId');

      final response = await http
          .get(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Check if response has data field
        if (responseData['data'] != null) {
          return Post.fromJson(responseData['data']);
        } else {
          return Post.fromJson(responseData);
        }
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to fetch post details',
        );
      }
    } catch (e) {
      throw Exception(
        'Failed to load post: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // Get hidden posts
  Future<List<String>> getHiddenPostIds() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/me/hidden-posts');

      final response = await http
          .get(
            url,
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout'),
          );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Assuming the response has a data field with hidden post IDs
        if (responseData['data'] != null &&
            responseData['data']['hiddenPosts'] != null) {
          final List<dynamic> hiddenPostsJson =
              responseData['data']['hiddenPosts'];
          return hiddenPostsJson
              .map((json) => json['productId'] as String)
              .toList();
        }
        return [];
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to get hidden posts',
        );
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
