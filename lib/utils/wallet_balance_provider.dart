import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:yempover_app/services/coin_service.dart';
import 'package:yempover_app/services/socket_io/socket_service.dart';
import 'package:yempover_app/services/token_service.dart';

// Single shared source of truth for the user's coin balance, so every
// screen showing coins (wallet screen, chat deal panel, offer sheets,
// checkout, ...) reflects the same number instantly instead of each
// independently fetching a possibly-stale value on its own open. Kept live
// via the wallet:updated socket event, which the server now emits on every
// balance change: top-ups, redemptions, escrow hold/release/refund.
class WalletBalanceProvider extends ChangeNotifier {
  final CoinService _coinService = CoinService();
  final SocketService _socketService = SocketService();
  final TokenService _tokenService = TokenService();

  int? _balance; // null = not loaded yet (don't render "0" during this)
  bool _isLoading = false;
  bool _liveStarted = false;

  int? get balance => _balance;
  bool get isLoading => _isLoading;

  // Idempotent — safe to call from every screen that cares about the
  // balance (in addition to the one app-level call at login/launch), so a
  // screen opened before the app-level bootstrap has run still ends up
  // connected instead of silently missing live updates.
  Future<void> ensureLive() async {
    if (!_liveStarted) {
      _liveStarted = true;
      _socketService.on('wallet:updated', _handleWalletUpdated);
    }
    unawaited(_connectSocket());
    if (_balance == null && !_isLoading) {
      unawaited(refresh());
    }
  }

  Future<void> _connectSocket() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null || token.isEmpty) return;
      _socketService.init(token: token);
    } catch (_) {
      // Best-effort — REST refresh() still works without a live socket.
    }
  }

  void _handleWalletUpdated(dynamic data) {
    try {
      final raw = data is Map ? data['balance'] : null;
      if (raw == null) return;
      _balance = CoinService.parseCoinAmount(raw);
      notifyListeners();
    } catch (_) {
      // Malformed payload — ignore, next refresh()/event will correct it.
    }
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    try {
      final wallet = await _coinService.getWallet();
      _balance = CoinService.parseCoinAmount(wallet?['balance']);
    } catch (_) {
      // Keep whatever value we already had rather than blanking it out on
      // a transient fetch failure.
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Call right after a successful login (a fresh token) so the socket
  /// reconnects under the new identity instead of waiting for some other
  /// screen to happen to call ensureLive() first.
  Future<void> onLogin() async {
    _liveStarted = false;
    _balance = null;
    await ensureLive();
  }

  void reset() {
    _balance = null;
    _isLoading = false;
    notifyListeners();
  }
}
