// services/token_refresh_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'token_service.dart';

class TokenRefreshService {
  static final TokenRefreshService _instance = TokenRefreshService._internal();
  factory TokenRefreshService() => _instance;
  TokenRefreshService._internal();

  final TokenService _tokenService = TokenService();

  // Flag to prevent multiple simultaneous refresh attempts
  bool _isRefreshing = false;

  // Queue of requests waiting for token refresh
  final List<Completer<String?>> _refreshCompleters = [];

  /// Attempts to refresh the token using the refresh token
  Future<String?> refreshToken() async {
    // If already refreshing, add to queue
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    debugPrint('🔄 TokenRefreshService: Attempting to refresh token');

    try {
      final refreshToken = await _tokenService.getRefreshToken();

      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('🔴 TokenRefreshService: No refresh token available');
        await _handleRefreshFailure();
        return null;
      }

      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('🔴 TokenRefreshService: Refresh request timeout');
              throw Exception('Request timeout');
            },
          );

      debugPrint(
        '📨 TokenRefreshService: Refresh response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' && data['data'] != null) {
          final newToken = data['data']['token'];

          // Save the new token
          await _tokenService.saveTokens(
            token: newToken,
            refreshToken: refreshToken, // Keep the same refresh token
          );

          debugPrint('✅ TokenRefreshService: Token refreshed successfully');

          // Resolve all queued completers with new token
          _resolveAllCompleters(newToken);

          return newToken;
        } else {
          debugPrint('🔴 TokenRefreshService: Invalid response format');
          await _handleRefreshFailure();
          return null;
        }
      } else if (response.statusCode == 401) {
        debugPrint('🔴 TokenRefreshService: Refresh token expired or invalid');
        await _handleRefreshFailure();
        return null;
      } else {
        debugPrint(
          '🔴 TokenRefreshService: Refresh failed with status ${response.statusCode}',
        );
        await _handleRefreshFailure();
        return null;
      }
    } catch (e) {
      debugPrint('🔴 TokenRefreshService: Error refreshing token: $e');
      await _handleRefreshFailure();
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Handle refresh failure - clear tokens and notify all waiting requests
  Future<void> _handleRefreshFailure() async {
    await _tokenService.clearTokens();
    _resolveAllCompleters(null);
  }

  /// Resolve all waiting completers with the new token or null on failure
  void _resolveAllCompleters(String? token) {
    for (final completer in _refreshCompleters) {
      if (!completer.isCompleted) {
        completer.complete(token);
      }
    }
    _refreshCompleters.clear();
  }

  /// Check if token needs refresh based on expiration (optional)
  bool isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];

      if (exp == null) return true;

      // Check if token expires in next 5 minutes
      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final fiveMinutesFromNow = now.add(const Duration(minutes: 5));

      return expiryTime.isBefore(fiveMinutesFromNow);
    } catch (e) {
      debugPrint('🔴 TokenRefreshService: Error checking token expiry: $e');
      return true;
    }
  }
}
