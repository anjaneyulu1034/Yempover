// lib/services/my_posts_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/my_post_model.dart';

class MyPostsService {
  static final MyPostsService _instance = MyPostsService._internal();
  factory MyPostsService() => _instance;
  MyPostsService._internal();

  final http.Client _client = http.Client();

  Future<String?> _getToken() async {
    final token = await TokenService().getToken();
    debugPrint(
      '🔑 MyPostsService: Token retrieved: ${token != null ? 'Yes (${token.substring(0, min(20, token.length))}...)' : 'No'}',
    );
    return token;
  }

  Future<MyPostsResponse> getMyPosts({int page = 1, int limit = 20}) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint('🔴 MyPostsService: No authentication token found');
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '${ApiConstants.baseUrl}/me/posts?page=$page&limit=$limit';
      debugPrint('🌐 MyPostsService: Fetching my posts from: $url');

      final response = await _client
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
        // Clear invalid token
        await TokenService().clearTokens();
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 MyPostsService: Error fetching my posts: $e');
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '${ApiConstants.baseUrl}/posts/$postId';
      debugPrint('🌐 MyPostsService: Deleting post: $url');

      final response = await _client
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
    }
  }

  Future<void> updatePostStatus(String postId, String status) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '${ApiConstants.baseUrl}/posts/$postId/status';
      debugPrint('🌐 MyPostsService: Updating post status: $url');

      final response = await _client
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
    }
  }

  void dispose() {
    _client.close();
  }
}

int min(int a, int b) => a < b ? a : b;
