// lib/screens/HamburgerMenuScreen.dart
import 'package:Yempover_app/utils/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:Yempover_app/payment/SubscriptionScreen.dart';
import 'package:Yempover_app/screens/EditProfileScreen.dart';
import 'package:Yempover_app/screens/FavoritesScreen.dart';
import 'package:Yempover_app/screens/HelpSupportScreen.dart';
import 'package:Yempover_app/screens/NotificationsScreen.dart';
import 'package:Yempover_app/screens/PrivacyScreen.dart';
import 'package:Yempover_app/screens/TermsScreen.dart';
import 'package:Yempover_app/screens/TradeHistoryScreen.dart';
import 'package:Yempover_app/services/profile_session_manager.dart';
import 'package:Yempover_app/utils/token_manager.dart';
import 'package:Yempover_app/screens/LoginScreen.dart';
import 'package:Yempover_app/services/subscription_plan_service.dart';
import 'package:Yempover_app/models/get_current_subscription_plan_response.dart';

class HamburgerMenuScreen extends StatefulWidget {
  const HamburgerMenuScreen({super.key});

  @override
  State<HamburgerMenuScreen> createState() => _HamburgerMenuScreenState();
}

class _HamburgerMenuScreenState extends State<HamburgerMenuScreen> {
  CurrentPlan? _currentSubscription;
  bool _isLoadingSubscription = false;

  @override
  void initState() {
    super.initState();
    // Load unread count when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUnreadCount();
      _loadCurrentSubscription();
    });
  }

  Future<void> _loadUnreadCount() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.loadUnreadCount();
  }

  Future<void> _loadCurrentSubscription() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final token = await TokenManager.getToken();
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoadingSubscription = false;
          _currentSubscription = null;
        });
        return;
      }

      final response = await SubscriptionPlanService()
          .getCurrentSubscriptionPlan();

      if (mounted) {
        setState(() {
          _currentSubscription = response.data;
          _isLoadingSubscription = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading subscription: $e');
      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
          _currentSubscription = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(context),

            // Divider
            const Divider(height: 1, thickness: 0.5),

            // Menu Items Section
            Expanded(child: _buildMenuItems(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context) {
    final profile = ProfileSessionManager.instance.profile;
    final sessionManager = ProfileSessionManager.instance;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile Image with edit button
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue, width: 3),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: profile?.profileImage != null
                      ? NetworkImage(profile!.profileImage!)
                      : null,
                  child: profile?.profileImage == null
                      ? Text(
                          sessionManager.initials.isNotEmpty
                              ? sessionManager.initials
                              : '?',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                    onPressed: () async {
                      // Navigate to Edit Profile Screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );

                      // If profile was updated, refresh the UI
                      if (result != null && mounted) {
                        setState(() {});
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            sessionManager.fullName.isNotEmpty
                ? sessionManager.fullName
                : 'James William',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 8),

          // Location
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                profile?.homeAddress != null
                    ? profile!.homeAddress.toString()
                    : 'Location not set',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: const Text(
                  'Verified',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Joined',
                formatJoinedDate(profile?.registrationDate),
                Icons.calendar_today,
              ),
              _buildStatItem(
                'Trades',
                profile?.totalTradesCompleted?.toString() ?? '0',
                Icons.swap_horiz,
              ),
              _buildStatItem(
                'Subscription',
                _getSubscriptionStatus(),
                Icons.verified_user,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Subscription Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Plan',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getCurrentPlanName(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getSubscriptionExpiryDate(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubscriptionScreen(),
                      ),
                    );
                    // Refresh subscription data when returning
                    _loadCurrentSubscription();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Manage'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentPlanName() {
    if (_isLoadingSubscription) {
      return 'Loading...';
    }
    if (_currentSubscription != null) {
      return _currentSubscription!.planName ?? 'Active Plan';
    }
    return 'Free Trial';
  }

  String _getSubscriptionStatus() {
    if (_isLoadingSubscription) {
      return '...';
    }
    if (_currentSubscription != null) {
      return 'Active';
    }
    return 'Inactive';
  }

  String _getSubscriptionExpiryDate() {
    if (_isLoadingSubscription) {
      return 'Loading...';
    }
    if (_currentSubscription?.endDate != null) {
      try {
        final date = DateTime.parse(_currentSubscription!.endDate!);
        return 'Until ${DateFormat('dd MMM yyyy').format(date)}';
      } catch (e) {
        return 'No expiry';
      }
    }
    return '90 days free trial';
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        // Edit Profile Menu Item
        _buildMenuItem(
          icon: Icons.person_outline,
          title: 'Edit Profile',
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const EditProfileScreen(),
              ),
            );
            if (result != null && mounted) {
              setState(() {});
            }
          },
        ),

        // Favorites
        _buildMenuItem(
          icon: Icons.favorite_border,
          title: 'Favorites',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FavoritesScreen()),
            );
          },
        ),

        // Trade History
        // _buildMenuItem(
        //   icon: Icons.history,
        //   title: 'Trade History',
        //   onTap: () {
        //     Navigator.push(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => const TradeHistoryScreen(),
        //       ),
        //     );
        //   },
        // ),

        // Subscription
        _buildMenuItem(
          icon: Icons.subscriptions,
          title: 'Subscription',
          trailing: _isLoadingSubscription
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                    ),
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getSubscriptionStatus() == 'Active'
                        ? Colors.orange.shade50
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getSubscriptionStatus(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getSubscriptionStatus() == 'Active'
                          ? Colors.orange
                          : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SubscriptionScreen(),
              ),
            );
            // Refresh subscription data when returning
            _loadCurrentSubscription();
          },
        ),

        // Divider
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Divider(height: 1, thickness: 0.5),
        ),

        // Help & Support
        _buildMenuItem(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            );
          },
        ),

        // Terms and Conditions
        _buildMenuItem(
          icon: Icons.description_outlined,
          title: 'Terms and Conditions',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TermsScreen()),
            );
          },
        ),

        // Privacy Policy
        _buildMenuItem(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PrivacyScreen()),
            );
          },
        ),

        // Notifications - Updated with Badge
        Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            return _buildMenuItem(
              icon: Icons.notifications,
              title: 'Notifications',
              trailing: provider.unreadCount > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        provider.unreadCount > 99
                            ? '99+'
                            : '${provider.unreadCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationsScreen(
                      notifications: const [],
                      onNotificationTap: (p1) {},
                    ),
                  ),
                ).then((_) {
                  // Refresh unread count when returning
                  provider.loadUnreadCount();
                });
              },
            );
          },
        ),

        // Logout
        _buildMenuItem(
          icon: Icons.logout,
          title: 'Logout',
          titleColor: Colors.red,
          iconColor: Colors.red,
          onTap: () {
            _showLogoutDialog(context);
          },
        ),

        // App version
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'iScripts Solutions',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dedicated, Development, Service',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.phone, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text(
                    '1 847 607 6123',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.language, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () {
                      _showComingSoon(context, 'Website');
                    },
                    child: const Text(
                      'http://www.iscripts.com',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'App Version 1.0.0',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature coming soon!'),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Clear session and token
                ProfileSessionManager.instance.clearSession();
                await TokenManager.clearToken();

                if (mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  String formatJoinedDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return "-";

    try {
      final parsed = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (e) {
      return "-";
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 24),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: titleColor ?? Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }
}
