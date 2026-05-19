import 'dart:convert';
import 'dart:math';

import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/services/api_service.dart';

class CoinService {
  static final CoinService _instance = CoinService._internal();
  factory CoinService() => _instance;
  CoinService._internal();

  final ApiService _api = ApiService();
  final Random _random = Random.secure();

  static int parseCoinAmount(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _newIdempotencyKey() {
    String segment(int length) {
      return List.generate(
        length,
        (_) => _random.nextInt(16).toRadixString(16),
      ).join();
    }

    return '${segment(8)}-${segment(4)}-${segment(4)}-${segment(4)}-${segment(12)}';
  }

  String? _messageFromBody(String body) {
    try {
      final payload = json.decode(body) as Map<String, dynamic>?;
      return payload?['message']?.toString();
    } catch (_) {
      return null;
    }
  }

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

  /// GET /api/mobile/wallet — returns null when wallet does not exist yet.
  Future<Map<String, dynamic>?> getWallet() async {
    final response = await _api.get(ApiConstants.wallet);

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode != 200) {
      final message =
          _messageFromBody(response.body) ?? 'Failed to load wallet';
      throw Exception(message);
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    final wallet = data['wallet'];
    if (wallet == null) return null;
    return Map<String, dynamic>.from(wallet as Map);
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
      final message =
          _messageFromBody(response.body) ?? 'Coin purchase failed';
      throw Exception(message);
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(payload['data'] as Map? ?? {});
  }

  /// POST /api/mobile/wallet/add
  Future<Map<String, dynamic>> addCoins({
    required int amount,
    required String description,
    String? idempotencyKey,
  }) async {
    final response = await _api.post(
      ApiConstants.walletAdd,
      headers: {'Idempotency-Key': idempotencyKey ?? _newIdempotencyKey()},
      body: {
        'amount': amount,
        'description': description,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _messageFromBody(response.body) ?? 'Failed to add coins';
      throw Exception(message);
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return Map<String, dynamic>.from(data['transaction'] as Map? ?? {});
  }
}
