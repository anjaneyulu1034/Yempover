// lib/services/favorites_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:Yempover_app/models/favorites_response.dart';
import 'package:Yempover_app/utils/token_manager.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  Future<FavoritesResponse> getFavorites({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found. Please login again.');
      }

      debugPrint('Fetching favorites - Page: $page, Limit: $limit');

      final response = await http.get(
        Uri.parse(ApiConstants.favoritesWithPagination(page, limit)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Favorites response status: ${response.statusCode}');
      debugPrint('Favorites response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return FavoritesResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
      throw Exception('Failed to load favorites: ${e.toString()}');
    }
  }

  Future<bool> addToFavorites(String postId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.favorites}/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        throw Exception('Failed to add to favorites');
      }
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      return false;
    }
  }

  Future<bool> removeFromFavorites(String postId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.delete(
        Uri.parse('${ApiConstants.favorites}/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to remove from favorites');
      }
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      return false;
    }
  }

  Future<bool> checkIfFavorite(String postId) async {
    try {
      final token = await TokenManager.getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('${ApiConstants.favorites}/check/$postId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['isFavorite'] ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }
}
