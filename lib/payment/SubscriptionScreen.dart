import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempower_app/payment/PaymentScreen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = 'Monthly';
  bool _isSubscribed = true;

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
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Plan Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Current Plan: Free Trial',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
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
                          child: const Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildPlanDetailRow(
                      'Start Date',
                      'Nov 12, 2023',
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),
                    _buildPlanDetailRow(
                      'Billing Date',
                      'Feb 12, 2024',
                      Icons.payment,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You are currently on a free trial period. Upgrade to continue using all features.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

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

            // Plan Options
            Row(
              children: [
                Expanded(
                  child: _buildPlanOption(
                    title: 'Monthly',
                    price: '\$10',
                    description: 'Billed monthly\nCancel anytime',
                    isSelected: _selectedPlan == 'Monthly',
                    onTap: () {
                      setState(() {
                        _selectedPlan = 'Monthly';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPlanOption(
                    title: 'Yearly',
                    price: '\$99',
                    description: 'Billed annually\nSave \$21 vs monthly',
                    isSelected: _selectedPlan == 'Yearly',
                    onTap: () {
                      setState(() {
                        _selectedPlan = 'Yearly';
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Yearly Savings
            if (_selectedPlan == 'Yearly')
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.savings, size: 20, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You save \$21 compared to monthly billing',
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

            const SizedBox(height: 32),

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
                      const Icon(Icons.star, size: 20, color: Colors.orange),
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
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Terms and Conditions
            const Text(
              'By joining you agree to our privacy policy and terms of service',
              style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Subscribe Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(plan: _selectedPlan),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5BFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSubscribed ? 'Upgrade Plan' : 'Subscribe Now',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cancel Subscription
            if (_isSubscribed)
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

  Widget _buildPlanOption({
    required String title,
    required String price,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              price,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.blue : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? Colors.blue : Colors.grey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            if (isSelected)
              const Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Selected',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
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
