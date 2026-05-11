import 'dart:convert';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/services/api_service.dart';

class CoinService {
  static final CoinService _instance = CoinService._internal();
  factory CoinService() => _instance;
  CoinService._internal();

  final ApiService _api = ApiService();

  Future<List<Map<String, dynamic>>> getPackages({String? countryCode}) async {
    final response = await _api.get(
      ApiConstants.coinPackages,
      queryParams: countryCode != null && countryCode.isNotEmpty
          ? {'countryCode': countryCode}
          : null,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load coin packages');
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    final packages = data['packages'] as List<dynamic>? ?? [];
    return packages.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getWallet() async {
    final response = await _api.get(ApiConstants.coinWallet);

    if (response.statusCode != 200) {
      throw Exception('Failed to load coin wallet');
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return Map<String, dynamic>.from(data['wallet'] as Map? ?? {});
  }

  Future<List<Map<String, dynamic>>> getTransactions({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.get(
      ApiConstants.coinTransactions,
      queryParams: {'page': page, 'limit': limit},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load coin transactions');
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    final txns = data['transactions'] as List<dynamic>? ?? [];
    return txns.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> purchaseCoins({
    required String coinPackageId,
    String? countryCode,
  }) async {
    final response = await _api.post(
      ApiConstants.coinPurchase,
      body: {
        'coinPackageId': coinPackageId,
        if (countryCode != null && countryCode.isNotEmpty)
          'countryCode': countryCode,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final payload = json.decode(response.body) as Map<String, dynamic>?;
      final message = payload?['message']?.toString() ?? 'Coin purchase failed';
      throw Exception(message);
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(payload['data'] as Map? ?? {});
  }
}
