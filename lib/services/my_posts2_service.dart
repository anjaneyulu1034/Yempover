import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:Yempover_app/models/api_response.dart';
import 'package:Yempover_app/models/my_post_model.dart';
import 'package:Yempover_app/services/token_service.dart';

class MyPostsService {
  final http.Client _client = http.Client();

  Future<void> dispose() async {
    _client.close();
  }

  Future<ApiResponse> getMyPosts({int page = 1, int limit = 20}) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await _client
          .get(
            Uri.parse('${ApiConstants.myPosts}?page=$page&limit=$limit'),
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, MyPost.fromJson);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<ApiResponse> getPostById(String postId) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await _client
          .get(
            Uri.parse('${ApiConstants.postDetail(postId)}'),
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, MyPost.fromJson);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to load post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<ApiResponse> updatePost(
    String postId,
    Map<String, dynamic> data,
  ) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final isProduct = data['type'] == 'product';
      final endpoint = isProduct
          ? '${ApiConstants.products}/$postId'
          : '${ApiConstants.services}/$postId';

      final response = await _client
          .put(
            Uri.parse(endpoint),
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: json.encode(data),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, MyPost.fromJson);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to update post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<ApiResponse> deletePost(String postId) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await _client
          .delete(
            Uri.parse(
              '${ApiConstants.products}/$postId',
            ), // Using products endpoint for delete
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, MyPost.fromJson);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to delete post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<ApiResponse> updatePostStatus(String postId, String status) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        throw Exception('No authentication token');
      }

      final response = await _client
          .patch(
            Uri.parse(ApiConstants.updatePostStatus(postId)),
            headers: {
              ...ApiConstants.headers,
              'Authorization': 'Bearer $token',
            },
            body: json.encode({'status': status}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return ApiResponse.fromJson(jsonResponse, MyPost.fromJson);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Post not found');
      } else {
        throw Exception('Failed to update post status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
