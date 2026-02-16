// lib/services/category_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/category_model.dart';
import 'package:yempover_app/services/token_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final http.Client _client = http.Client();

  Future<CategoryResponse> getCategories({required String type}) async {
    try {
      final token = await TokenService().getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = '${ApiConstants.baseUrl}/categories?type=$type';
      debugPrint('🌐 CategoryService: Fetching $type categories from: $url');

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

      debugPrint('📨 CategoryService: Response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        debugPrint('✅ CategoryService: Categories fetched successfully');
        return CategoryResponse.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 CategoryService: Error fetching categories: $e');
      rethrow;
    }
  }

  // Get all parent categories (categories with children)
  List<CategoryData> getParentCategories(CategoryResponse response) {
    return response.data
        .where((category) => category.children.isNotEmpty)
        .toList();
  }

  // Get all child categories from a parent category
  List<ChildCategory> getChildCategories(CategoryData parentCategory) {
    return parentCategory.children;
  }

  // Get flat list of all child categories (for dropdown)
  List<Map<String, dynamic>> getAllChildCategories(CategoryResponse response) {
    List<Map<String, dynamic>> allChildren = [];

    for (var parent in response.data) {
      for (var child in parent.children) {
        allChildren.add({
          'id': child.id,
          'name': child.name,
          'parentName': parent.name,
          'parentId': parent.id,
        });
      }
    }

    return allChildren;
  }

  void dispose() {
    _client.close();
  }
}
