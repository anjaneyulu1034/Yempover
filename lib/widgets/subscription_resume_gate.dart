import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yempover_app/services/subscription_plan_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/utils/subscription_gate.dart';

/// Re-checks subscription status whenever the app resumes from background,
/// so a plan that lapsed while the app was closed gets caught before the
/// user even makes a gated request. Renders nothing on its own — just
/// observes lifecycle events around [child].
class SubscriptionResumeGate extends StatefulWidget {
  const SubscriptionResumeGate({super.key, required this.child});

  final Widget child;

  @override
  State<SubscriptionResumeGate> createState() =>
      _SubscriptionResumeGateState();
}

class _SubscriptionResumeGateState extends State<SubscriptionResumeGate>
    with WidgetsBindingObserver {
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _checkSubscription);
  }

  Future<void> _checkSubscription() async {
    if (!await TokenService().isLoggedIn()) return;

    try {
      final response = await SubscriptionPlanService()
          .getCurrentSubscriptionPlan();
      // getCurrentSubscriptionPlan() never throws — a failed fetch (network
      // hiccup, profile lookup error) is swallowed internally and comes
      // back as status: 'error', data: null, which `isValid ?? false`
      // would otherwise treat identically to "really has no subscription".
      // Only pop the gate on a genuine successful check that says invalid;
      // anything else falls through to the same silent skip as the catch
      // below (the global HTTP interceptor still catches a real lapse on
      // the next actual request).
      if (response.status != 'success') return;
      final isValid = response.data?.isValid ?? false;
      if (!isValid) {
        SubscriptionGate.showIfNeeded();
      }
    } catch (_) {
      // Network hiccup — the global HTTP interceptor still catches a lapse
      // on the next real request, so this is fine to skip silently.
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
