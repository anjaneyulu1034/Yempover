import 'dart:convert';
import 'package:Yempover_app/models/favorites_response.dart';
import 'package:Yempover_app/services/api_service.dart';
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:Yempover_app/services/token_service.dart';

class FavoritesService {
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  // Get all favorites with pagination
  Future<FavoritesResponse> getFavorites({int page = 1, int limit = 20}) async {
    try {
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (!isLoggedIn) {
        throw Exception('Please login to view favorites');
      }

      final response = await _apiService.get(
        '${ApiConstants.favorites}?page=$page&limit=$limit',
      );

      if (response.statusCode == 200) {
        return FavoritesResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load favorites: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching favorites: $e');
    }
  }

  // Add product to favorites
  Future<AddFavoriteResponse> addProductToFavorites(String productId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.favorites,
        body: {'productId': productId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AddFavoriteResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add to favorites: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding to favorites: $e');
    }
  }

  // Add service to favorites
  Future<AddFavoriteResponse> addServiceToFavorites(String serviceId) async {
    try {
      final response = await _apiService.post(
        ApiConstants.favorites,
        body: {'serviceId': serviceId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AddFavoriteResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add to favorites: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding to favorites: $e');
    }
  }

  // Remove from favorites
  Future<RemoveFavoriteResponse> removeFromFavorites(String favoriteId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.favorites}/$favoriteId',
      );

      if (response.statusCode == 200) {
        return RemoveFavoriteResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception(
          'Failed to remove from favorites: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error removing from favorites: $e');
    }
  }
}
