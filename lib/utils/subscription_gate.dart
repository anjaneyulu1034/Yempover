import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/main.dart' as app;
import 'package:yempover_app/payment/SubscriptionScreen.dart';
import 'package:yempover_app/utils/session_manager.dart';

/// Central gate for the "you need an active subscription" flow.
///
/// Triggered from two places:
///  - Right after login, when verify-otp reports `subscription.isValid == false`.
///  - Anywhere a request comes back 403 with `code == 'SUBSCRIPTION_REQUIRED'` —
///    the backend's safety net for a plan that lapses mid-session.
class SubscriptionGate {
  SubscriptionGate._();

  static bool _isShowing = false;

  /// Shows the non-dismissible "please subscribe" popup, unless one is
  /// already on screen. Uses the app's root navigator so it can be called
  /// from services that have no [BuildContext] of their own.
  static void showIfNeeded() {
    final context = app.rootNavigatorKey.currentContext;
    if (context == null || _isShowing) return;
    _isShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Subscription required'),
          content: const Text(
            "You don't have an active subscription. Please subscribe to access the app.",
          ),
          actions: [
            TextButton(
              onPressed: () => _logout(dialogContext),
              child: const Text('Logout'),
            ),
            ElevatedButton(
              onPressed: () => _goToPlans(dialogContext),
              child: const Text('Subscribe / View Plans'),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _isShowing = false);
  }

  /// Inspects a raw HTTP response and shows the gate if it's the backend's
  /// `SUBSCRIPTION_REQUIRED` 403. Safe to call on every response — no-ops
  /// otherwise.
  static void checkResponse(http.Response response) {
    if (response.statusCode != 403) return;
    try {
      final body = json.decode(response.body);
      if (body is Map && body['code'] == 'SUBSCRIPTION_REQUIRED') {
        showIfNeeded();
      }
    } catch (_) {
      // Non-JSON body — nothing to do.
    }
  }

  static void _goToPlans(BuildContext dialogContext) {
    Navigator.of(dialogContext, rootNavigator: true).pop();
    app.rootNavigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
    );
  }

  static Future<void> _logout(BuildContext dialogContext) async {
    Navigator.of(dialogContext, rootNavigator: true).pop();
    await SessionManager.forceLogout();
  }
}
