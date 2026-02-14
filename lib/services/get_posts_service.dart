// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../constants/api_constants.dart';
// import '../models/post_model.dart';

// class ApiService {
//   final http.Client client;

//   ApiService({http.Client? client}) : client = client ?? http.Client();

//   Future<PostsResponse> getPosts({
//     int page = 1,
//     int limit = 20,
//     String? type,
//     String? category,
//   }) async {
//     try {
//       final response = await client.get(
//         Uri.parse(ApiConstants.getPosts(page, limit, type: type, category: category)),
//         headers: ApiConstants.headers,
//       );

//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);
//         return PostsResponse.fromJson(jsonResponse);
//       } else {
//         throw Exception('Failed to load posts: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load posts: $e');
//     }
//   }

//   Future<Post> getPostDetail(String postId, String type) async {
//     try {
//       final response = await client.get(
//         Uri.parse(ApiConstants.getPostDetail(postId, type)),
//         headers: ApiConstants.headers,
//       );

//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);
//         return Post.fromJson(jsonResponse['data']['post']);
//       } else {
//         throw Exception('Failed to load post detail: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load post detail: $e');
//     }
//   }

//   Future<List<CategoryWithChildren>> getCategories(String type) async {
//     try {
//       final response = await client.get(
//         Uri.parse(ApiConstants.getCategories(type)),
//         headers: ApiConstants.headers,
//       );

//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);
//         final List<dynamic> categoriesJson = jsonResponse['data'];
//         return categoriesJson
//             .map((json) => CategoryWithChildren.fromJson(json))
//             .toList();
//       } else {
//         throw Exception('Failed to load categories: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Failed to load categories: $e');
//     }
//   }

//   // For search functionality
//   Future<PostsResponse> searchPosts({
//     required String query,
//     int page = 1,
//     int limit = 20,
//     String? type,
//   }) async {
//     try {
//       // Note: This endpoint might not exist in your API
//       // You might need to filter on client side or implement search endpoint
//       final response = await client.get(
//         Uri.parse('${ApiConstants.posts}/search?q=$query&page=$page&limit=$limit${type != null ? '&type=$type' : ''}'),
//         headers: ApiConstants.headers,
//       );

//       if (response.statusCode == 200) {
//         final jsonResponse = json.decode(response.body);
//         return PostsResponse.fromJson(jsonResponse);
//       } else {
//         // Fallback to client-side filtering
//         final allPosts = await getPosts(page: page, limit: limit, type: type);
//         final filteredPosts = allPosts.data.posts.where((post) {
//           return post.title.toLowerCase().contains(query.toLowerCase()) ||
//                  post.description.toLowerCase().contains(query.toLowerCase()) ||
//                  (post.postedBy?.firstName.toLowerCase().contains(query.toLowerCase()) ?? false) ||
//                  (post.postedBy?.lastName.toLowerCase().contains(query.toLowerCase()) ?? false);
//         }).toList();

//         return PostsResponse(
//           status: 'success',
//           message: 'Search results',
//           data: PostsData(
//             posts: filteredPosts,
//             pagination: allPosts.data.pagination,
//           ),
//         );
//       }
//     } catch (e) {
//       throw Exception('Failed to search posts: $e');
//     }
//   }

//   void dispose() {
//     client.close();
//   }
// }
