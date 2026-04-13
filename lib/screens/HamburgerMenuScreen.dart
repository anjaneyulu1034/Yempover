import 'package:Yempover_app/utils/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Yempover_app/payment/SubscriptionScreen.dart';
import 'package:Yempover_app/screens/FavoritesScreen.dart';
import 'package:Yempover_app/screens/HelpSupportScreen.dart';
import 'package:Yempover_app/screens/HiddenPostsScreen.dart';
import 'package:Yempover_app/screens/MyProfileScreen.dart';
import 'package:Yempover_app/screens/NotificationsScreen.dart';
import 'package:Yempover_app/screens/PrivacyScreen.dart';
import 'package:Yempover_app/screens/service/AppointmentsDashboardScreen.dart';
import 'package:Yempover_app/screens/TermsScreen.dart';
import 'package:Yempover_app/screens/TradeHistoryScreen.dart';
import 'package:Yempover_app/services/account_service.dart';
import 'package:Yempover_app/services/auth_service.dart';
import 'package:Yempover_app/services/profile_session_manager.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/screens/LoginScreen.dart';
import 'package:Yempover_app/screens/Home_screen.dart';
import 'package:Yempover_app/services/subscription_plan_service.dart';
import 'package:Yempover_app/models/get_current_subscription_plan_response.dart';
import 'package:Yempover_app/utils/snackbar_utils.dart';

class HamburgerMenuScreen extends StatefulWidget {
  const HamburgerMenuScreen({super.key});

  @override
  State<HamburgerMenuScreen> createState() => _HamburgerMenuScreenState();
}

class _HamburgerMenuScreenState extends State<HamburgerMenuScreen> {
  CurrentPlan? _currentSubscription;
  bool _isLoadingSubscription = false;
  bool _isGuestUser = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Load unread count when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeMenuData();
    });
  }

  Future<void> _initializeMenuData() async {
    final isGuest = await TokenService().isGuestUser();
    if (mounted) {
      setState(() {
        _isGuestUser = isGuest;
      });
    }

    if (_isGuestUser) {
      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
          _currentSubscription = null;
        });
      }
      return;
    }

    await _loadUnreadCount();
    await _loadCurrentSubscription();
  }

  Future<void> _loadUnreadCount() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.loadUnreadCount();
  }

  Future<void> _loadCurrentSubscription() async {
    if (!mounted) return;

    if (_isGuestUser) {
      setState(() {
        _isLoadingSubscription = false;
        _currentSubscription = null;
      });
      return;
    }

    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final isLoggedIn = await TokenService().isLoggedIn();
      if (!isLoggedIn) {
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
      ),
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
    final hasHomeLocation =
        profile?.homeAddress != null &&
        profile?.homeAddress.toString().trim().isNotEmpty == true;
    final displayName = _isGuestUser
        ? 'Guest User'
        : (sessionManager.fullName.isNotEmpty
              ? sessionManager.fullName
              : 'James William');
    final displayLocation = _isGuestUser
        ? 'Guest Mode'
        : (hasHomeLocation
              ? profile?.homeAddress.toString() ?? 'Home Location not set'
              : 'Home Location not set');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade100,
            backgroundImage: !_isGuestUser && profile?.profileImage != null
                ? NetworkImage(profile!.profileImage!)
                : null,
            child: (_isGuestUser || profile?.profileImage == null)
                ? Text(
                    _isGuestUser
                        ? 'G'
                        : (sessionManager.initials.isNotEmpty
                              ? sessionManager.initials
                              : '?'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        displayLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!_isGuestUser)
            OutlinedButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyProfileScreen(),
                  ),
                );
                if (mounted) {
                  setState(() {});
                }
              },
              child: const Text('My Profile'),
            ),
        ],
      ),
    );
  }

  String _getSubscriptionStatus() {
    if (_isGuestUser) {
      return 'Guest';
    }
    if (_isLoadingSubscription) {
      return '...';
    }
    if (_currentSubscription != null) {
      return 'Active';
    }
    return 'Inactive';
  }

  Widget _buildMenuItems(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(0),
      children: [
        if (_isGuestUser)
          _buildMenuItem(
            icon: Icons.login,
            title: 'Login / Sign Up',
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          ),

        // Favorites
        if (!_isGuestUser)
          _buildMenuItem(
            icon: Icons.favorite_border,
            title: 'Favorites',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FavoritesScreen(),
                ),
              );
            },
          ),

        //Trade History
        if (!_isGuestUser)
          _buildMenuItem(
            icon: Icons.history,
            title: 'Trade History',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TradeHistoryScreen(),
                ),
              );
            },
          ),

        // Service Appointments Dashboard
        if (!_isGuestUser)
          _buildMenuItem(
            icon: Icons.calendar_month_outlined,
            title: 'Appointments',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AppointmentsDashboardScreen(),
                ),
              );
            },
          ),

        if (!_isGuestUser)
          _buildMenuItem(
            icon: Icons.visibility_off_outlined,
            title: 'Hidden Posts',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HiddenPostsScreen(),
                ),
              );
            },
          ),

        // Subscription
        if (!_isGuestUser)
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
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

        // Divider before account actions
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Divider(height: 1, thickness: 0.5),
        ),

        // Delete Account (New Menu Item)
        if (!_isGuestUser)
          _buildMenuItem(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            titleColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              _showDeleteAccountDialog(context);
            },
          ),

        // Logout
        if (!_isGuestUser)
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            titleColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              _showLogoutDialog(context);
            },
          ),
      ],
    );
  }

  // Updated logout method with API call - FIXED
  Future<void> _logout() async {
    try {
      // Show loading indicator
      if (!mounted) return;

      // Use a flag to track if dialog is showing
      bool isDialogShowing = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Logging out...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
      );

      // Call logout API
      try {
        await _authService.logout();
      } catch (apiError) {
        // If API fails, still proceed with local logout
        debugPrint(
          '⚠️ Logout API failed, proceeding with local logout: $apiError',
        );
      }

      // Clear all local data using the correct method name
      await TokenService()
          .clearTokens(); // FIXED: Using clearTokens() instead of deleteToken()

      // Clear session manager
      ProfileSessionManager.instance.clearSession();

      // Close loading dialog if it's still showing
      if (mounted && isDialogShowing) {
        Navigator.pop(context);
        isDialogShowing = false;
      }

      if (!mounted) return;

      // Navigate to login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      // Show success message
      SnackbarUtils.showSuccess(context, 'Logged out successfully');
    } catch (e) {
      debugPrint('🔴 Error during logout: $e');

      // Close loading dialog if open
      if (mounted) {
        Navigator.pop(context);
      }

      if (!mounted) return;

      // Still attempt to clear local data and navigate to login
      try {
        await TokenService()
            .clearTokens(); // FIXED: Using clearTokens() here too
        if (!mounted) return;
        ProfileSessionManager.instance.clearSession();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        SnackbarUtils.showSuccess(context, 'Logged out successfully');
      } catch (cleanupError) {
        SnackbarUtils.showError(
          context,
          'Error during logout: ${e.toString().replaceFirst('Exception: ', '')}',
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // Show loading indicator
      if (!mounted) return;

      bool isDialogShowing = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'Deleting your account...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          );
        },
      );

      // Call API to delete account
      final accountService = AccountService();
      final response = await accountService.deleteAccount();

      // Clear all local data
      await accountService.clearAllLocalData();

      // Close loading dialog
      if (mounted && isDialogShowing) {
        Navigator.pop(context);
        isDialogShowing = false;
      }

      if (!mounted) return;

      // Show success message
      SnackbarUtils.showSuccess(context, response.message);

      // Navigate to login screen and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.pop(context);
      }

      debugPrint('🔴 Error deleting account: $e');

      if (!mounted) return;

      SnackbarUtils.showError(
        context,
        'Failed to delete account: ${e.toString().replaceFirst('Exception: ', '')}',
      );
    }
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
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _logout(); // Perform logout with API
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you absolutely sure you want to delete your account?'),
              SizedBox(height: 16),
              Text(
                'This action cannot be undone. This will permanently delete:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Your profile and all personal information'),
                    Text('• All your posts and trade history'),
                    Text('• All your messages and conversations'),
                    Text('• Your subscription and payment information'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _deleteAccount(); // Perform account deletion
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
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
