import 'dart:convert';
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trade_history_model.dart';

class TradeHistoryService {
  static final TradeHistoryService _instance = TradeHistoryService._internal();

  factory TradeHistoryService() {
    return _instance;
  }

  TradeHistoryService._internal();

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

  // Get current user ID from token or storage
  Future<String?> getCurrentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('user_id');
    } catch (e) {
      print('Error getting user ID: $e');
      return null;
    }
  }

  // Fetch user stats from API
  Future<TradeStatsData> getUserStats() async {
    final token = await _getToken();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}/me/stats'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final tradeResponse = TradeHistoryResponse.fromJson(jsonResponse);

        // Save user ID from token if not already saved
        if (await getCurrentUserId() == null) {
          // You might want to decode the JWT token here to get the user ID
          // For now, we'll extract it from the first trade if available
          final allTrades = tradeResponse.data.trades.getAllTrades();
          if (allTrades.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(
              'user_id',
              allTrades.first.product.postedById,
            );
          }
        }

        return tradeResponse.data;
      } else if (response.statusCode == 401) {
        throw Exception('Session expired. Please login again.');
      } else {
        throw Exception(
          'Failed to load stats: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('Error fetching user stats: $e');
      throw Exception('Network error. Please check your connection.');
    }
  }

  // Refresh trade history data
  Future<TradeStatsData> refreshStats() async {
    return await getUserStats();
  }
}
