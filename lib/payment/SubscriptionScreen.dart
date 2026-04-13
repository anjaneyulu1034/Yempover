import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Yempover_app/models/get_current_subscription_plan_response.dart';
import 'package:Yempover_app/models/get_subscription_plans_response.dart';
import 'package:Yempover_app/services/subscription_plan_service.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/utils/snackbar_utils.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Plans? _selectedPlan;
  CurrentPlan? currentPlan;
  bool _isLoadingPlans = true;
  bool _isLoadingCurrentPlan = true;
  bool _isSubscribing = false;
  String? _errorMessage;
  List<Plans> plans = [];
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await TokenService().isLoggedIn();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });

    if (isLoggedIn) {
      _fetchData();
    } else {
      setState(() {
        _isLoadingPlans = false;
        _isLoadingCurrentPlan = false;
      });
      SnackbarUtils.showLoginDialog(context);
    }
  }

  Future<void> _fetchData() async {
    // Fetch both in parallel
    await Future.wait([
      _fetchSubscriptionPlans(),
      _fetchCurrentSubscriptionPlan(),
    ]);
  }

  Future<void> _fetchSubscriptionPlans() async {
    setState(() {
      _isLoadingPlans = true;
      _errorMessage = null;
    });

    try {
      final response = await SubscriptionPlanService().getSubscriptionPlans();

      if (response.data?.plans != null) {
        plans = response.data!.plans!;

        // Auto-select first plan if none selected
        if (plans.isNotEmpty && _selectedPlan == null) {
          _selectedPlan = plans.first;
        }
      }

      setState(() {
        _isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingPlans = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (_errorMessage!.contains('Session expired') ||
          _errorMessage!.contains('Unauthorized')) {
        SnackbarUtils.showLoginDialog(context);
      } else {
        SnackbarUtils.showError(context, _errorMessage!);
      }
    }
  }

  Future<void> _fetchCurrentSubscriptionPlan() async {
    setState(() {
      _isLoadingCurrentPlan = true;
    });

    try {
      if (!_isLoggedIn) {
        setState(() {
          _isLoadingCurrentPlan = false;
        });
        return;
      }

      final response = await SubscriptionPlanService()
          .getCurrentSubscriptionPlan();

      setState(() {
        currentPlan = response.data;
        _isLoadingCurrentPlan = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCurrentPlan = false;
      });

      // Don't show error for no subscription - it's normal
      if (!e.toString().contains('No active subscription') &&
          !e.toString().contains('No authentication token')) {
        debugPrint('Error fetching current plan: $e');
      }
    }
  }

  bool get _isLoading => _isLoadingPlans || _isLoadingCurrentPlan;

  bool _isSelectedPlanCurrent() {
    if (_selectedPlan == null || currentPlan == null) return false;

    final selectedId = _selectedPlan!.id?.trim();
    final currentId = currentPlan?.planId?.trim();

    if (selectedId != null &&
        selectedId.isNotEmpty &&
        currentId != null &&
        currentId.isNotEmpty) {
      return selectedId == currentId;
    }

    final selectedName = (_selectedPlan!.name ?? '').trim().toLowerCase();
    final currentName = (currentPlan?.planName ?? '').trim().toLowerCase();

    if (selectedName.isEmpty || currentName.isEmpty) return false;
    return selectedName == currentName;
  }

  Future<void> _subscribeToSelectedPlan() async {
    if (_selectedPlan == null || _isSubscribing) return;

    final planId = _selectedPlan!.id?.trim() ?? '';
    if (planId.isEmpty) {
      SnackbarUtils.showError(
        context,
        'Invalid plan selected. Please try again.',
      );
      return;
    }

    setState(() => _isSubscribing = true);

    try {
      final response = await SubscriptionPlanService().subscribe(planId);
      final message =
          (response['message']?.toString().trim().isNotEmpty ?? false)
          ? response['message'].toString().trim()
          : 'Subscription activated successfully.';

      await _fetchCurrentSubscriptionPlan();
      if (!mounted) return;

      SnackbarUtils.showSuccess(context, message);
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('Session expired') ||
          e.toString().contains('Unauthorized')) {
        SnackbarUtils.showLoginDialog(context);
      } else {
        SnackbarUtils.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubscribing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Subscription',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.transparent,
      body: !_isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Please login to view subscriptions',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      SnackbarUtils.showLoginDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5BFF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Login'),
                  ),
                ],
              ),
            )
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  20,
                  20,
                  20,
                  20 + MediaQuery.of(context).viewPadding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Plan Card
                    if (currentPlan != null) _buildCurrentPlanCard(),

                    if (currentPlan != null) const SizedBox(height: 32),

                    // Choose Plan Title
                    const Text(
                      'Choose your Plan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Select the plan that best suits your needs',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),

                    const SizedBox(height: 24),

                    // Plans Grid
                    if (plans.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            "No plans available",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.85,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: plans.length,
                        itemBuilder: (context, index) {
                          final plan = plans[index];
                          return _buildPlanOption(plan);
                        },
                      ),

                    const SizedBox(height: 20),

                    // Yearly Savings (show if annual is selected)
                    if (_selectedPlan?.name?.toLowerCase() == 'annual')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.savings, size: 20, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You save compared to monthly billing',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Free Trial Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 20,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Special Offer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'All first-time users get 3 months free subscription on any plan!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Subscribe Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _selectedPlan == null ||
                                _isSelectedPlanCurrent() ||
                                _isSubscribing
                            ? null
                            : _subscribeToSelectedPlan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E5BFF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: Text(
                          _selectedPlan == null
                              ? 'Select a Plan'
                              : _isSelectedPlanCurrent()
                              ? 'Current Plan Selected'
                              : currentPlan != null
                              ? 'Upgrade Plan'
                              : 'Subscribe Now',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Cancel Subscription
                    if (currentPlan != null)
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _showCancelSubscriptionDialog,
                          child: const Text(
                            'Cancel Subscription',
                            style: TextStyle(fontSize: 14, color: Colors.red),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanCard() {
    // Safely access planName and status with null checks
    String planDisplayName = currentPlan?.planName ?? 'Free Trial';
    String planStatus = currentPlan?.status ?? 'active';
    bool isTrialing = planStatus.toLowerCase() == 'trialing';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Current Plan: $planDisplayName',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    isTrialing ? 'TRIAL' : planStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildPlanDetailRow(
              'Start Date',
              _formatDate(currentPlan?.startDate),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            _buildPlanDetailRow(
              'End Date',
              _formatDate(currentPlan?.endDate),
              Icons.event,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isTrialing
                        ? 'You are currently on a free trial period. Upgrade to continue using all features.'
                        : 'Your subscription is active.',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildPlanOption(Plans plan) {
    final isSelected = _selectedPlan?.id == plan.id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlan = plan;
          });
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF2E5BFF), Color(0xFF6A8DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF2E5BFF)
                      : Colors.grey.shade300,
                  width: isSelected ? 2.5 : 1,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plan.name ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    plan.formattedAmount,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${plan.durationDays ?? 0} Days',
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan.description ?? '',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            /// SELECTED BADGE
            if (isSelected)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "SELECTED",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showCancelSubscriptionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your billing period.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Subscription'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription cancelled successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }
}
