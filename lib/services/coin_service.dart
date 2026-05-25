import 'dart:convert';
import 'dart:math';

import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/services/api_service.dart';
import 'package:http/http.dart' as http;

class WalletTransactionsPage {
  final List<Map<String, dynamic>> transactions;
  final int total;
  final int limit;
  final bool hasMore;

  const WalletTransactionsPage({
    required this.transactions,
    required this.total,
    required this.limit,
    required this.hasMore,
  });
}

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

  static bool isTransientNetworkError(Object error) {
    final message = error.toString().toLowerCase();
    return error is http.ClientException ||
        message.contains('connection closed') ||
        message.contains('connection reset') ||
        message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network is unreachable') ||
        message.contains('timed out') ||
        message.contains('handshake');
  }

  static String friendlyNetworkMessage(Object error) {
    if (isTransientNetworkError(error)) {
      return 'Connection issue. Pull to refresh and try again.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<T> _withNetworkRetry<T>(
    Future<T> Function() action, {
    int attempts = 3,
  }) async {
    Object? lastError;
    for (var attempt = 0; attempt < attempts; attempt++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        final isLastAttempt = attempt == attempts - 1;
        if (!isTransientNetworkError(e) || isLastAttempt) break;
        await Future.delayed(Duration(milliseconds: 350 * (attempt + 1)));
      }
    }
    throw Exception(friendlyNetworkMessage(lastError ?? 'Request failed'));
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
    return _withNetworkRetry(() async {
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
    });
  }

  static String? _dateQueryParam(DateTime? date) {
    if (date == null) return null;
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// GET /api/mobile/wallet/transactions
  /// [cursor] — id of the last transaction from the previous page (omit on first page).
  /// [type] — e.g. ADD_FUNDS for add-coin transactions only.
  /// [fromDate]/[toDate] — inclusive calendar-day filter (yyyy-MM-dd).
  Future<WalletTransactionsPage> getTransactions({
    int limit = 20,
    String? cursor,
    String? type,
    String? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    final from = _dateQueryParam(fromDate);
    final to = _dateQueryParam(toDate);
    if (from != null) queryParams['from'] = from;
    if (to != null) queryParams['to'] = to;

    return _withNetworkRetry(() async {
      final response = await _api.get(
        ApiConstants.walletTransactions,
        queryParams: queryParams,
      );

      if (response.statusCode != 200) {
        final message =
            _messageFromBody(response.body) ?? 'Failed to load transactions';
        throw Exception(message);
      }

      final payload = json.decode(response.body) as Map<String, dynamic>;
      final data = payload['data'] as Map<String, dynamic>? ?? {};
      final txns = data['transactions'] as List<dynamic>? ?? [];
      final pagination = data['pagination'] as Map<String, dynamic>? ?? {};

      final transactions = txns
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final total = parseCoinAmount(pagination['total']);
      final pageLimit = parseCoinAmount(pagination['limit']);
      final effectiveLimit = pageLimit > 0 ? pageLimit : limit;

      return WalletTransactionsPage(
        transactions: transactions,
        total: total,
        limit: effectiveLimit,
        hasMore:
            transactions.length >= effectiveLimit && total > transactions.length,
      );
    });
  }

  /// GET /api/mobile/wallet/transactions/:id
  Future<Map<String, dynamic>> getTransactionById(String transactionId) async {
    final response = await _api.get(
      ApiConstants.walletTransactionDetail(transactionId),
    );

    if (response.statusCode != 200) {
      final message =
          _messageFromBody(response.body) ?? 'Failed to load transaction';
      throw Exception(message);
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return Map<String, dynamic>.from(data['transaction'] as Map? ?? {});
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

  /// POST /api/mobile/wallet/pay — transfer coins to another user.
  Future<Map<String, dynamic>> pay({
    required String toUserId,
    required int amount,
    required String referenceId,
    required String referenceType,
    required String description,
    Map<String, dynamic>? metadata,
    String? idempotencyKey,
  }) async {
    final response = await _api.post(
      ApiConstants.walletPay,
      headers: {'Idempotency-Key': idempotencyKey ?? _newIdempotencyKey()},
      body: {
        'toUserId': toUserId,
        'amount': amount,
        'referenceId': referenceId,
        'referenceType': referenceType,
        'description': description,
        if (metadata != null) 'metadata': metadata,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final message = _messageFromBody(response.body) ?? 'Wallet payment failed';
      throw Exception(message);
    }

    final payload = json.decode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>? ?? {};
    return Map<String, dynamic>.from(data);
  }
}
