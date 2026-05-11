import 'dart:convert';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delete_account_response.dart';

class AccountService {
  static final AccountService _instance = AccountService._internal();

  factory AccountService() {
    return _instance;
  }

  AccountService._internal();

  // Get authentication token from storage
  Future<String?> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Delete account API call
  Future<DeleteAccountResponse> deleteAccount() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    try {
      final response = await http
          .delete(
            Uri.parse('${ApiConstants.baseUrl}/me'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      final jsonResponse = json.decode(response.body);

      if (response.statusCode == 200) {
        return DeleteAccountResponse.fromJson(jsonResponse);
      } else {
        throw Exception(jsonResponse['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      print('Error deleting account: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  // Clear all local data after account deletion
  Future<void> clearAllLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all shared preferences
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }
}
