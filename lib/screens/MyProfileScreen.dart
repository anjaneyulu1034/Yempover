import 'package:YemPover_app/models/get_my_profile_response.dart';
import 'package:YemPover_app/models/get_current_subscription_plan_response.dart';
import 'package:YemPover_app/screens/EditProfileScreen.dart';
import 'package:YemPover_app/services/profile_service.dart';
import 'package:YemPover_app/services/profile_session_manager.dart';
import 'package:YemPover_app/services/notification1_service.dart';
import 'package:YemPover_app/services/subscription_plan_service.dart';
import 'package:YemPover_app/utils/error_message_utils.dart';
import 'package:YemPover_app/utils/loading_widget.dart';
import 'package:YemPover_app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final ProfileService _profileService = ProfileService();

  ProfileData? _profile;
  CurrentPlan? _currentSubscription;
  bool _isLoading = true;
  bool _isLoadingSubscription = false;
  bool _isRequestingNotificationPermission = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profile = ProfileSessionManager.instance.profile;
    _loadProfile();
    _loadSubscription();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await _profileService.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final friendly = ErrorMessageUtils.sanitize(
        e,
        fallback: 'Unable to load profile right now. Please try again.',
      );
      setState(() {
        _isLoading = false;
        _error = friendly;
      });
      SnackbarUtils.showError(
        context,
        friendly,
        fallback: 'Unable to load profile right now. Please try again.',
      );
    }
  }

  Future<void> _loadSubscription() async {
    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final response = await SubscriptionPlanService()
          .getCurrentSubscriptionPlan();
      if (!mounted) return;
      setState(() {
        _currentSubscription = response.data;
        _isLoadingSubscription = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _currentSubscription = null;
        _isLoadingSubscription = false;
      });
    }
  }

  String _formatDate(String? rawDate) {
    if (rawDate == null || rawDate.isEmpty) return '-';
    final parsed = DateTime.tryParse(rawDate)?.toLocal();
    if (parsed == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
  }

  String _subscriptionStatus() {
    if (_isLoadingSubscription) return 'Loading...';
    if (_currentSubscription != null) return 'Active';
    return 'Inactive';
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadProfile(), _loadSubscription()]);
  }

  Future<void> _requestNotificationPermissionFromProfile() async {
    if (_isRequestingNotificationPermission) return;

    setState(() {
      _isRequestingNotificationPermission = true;
    });

    try {
      final granted = await NotificationService1()
          .requestNotificationPermissionAgain();
      if (!mounted) return;

      if (granted) {
        SnackbarUtils.showSuccess(
          context,
          'Notifications enabled successfully.',
        );
        return;
      }

      SnackbarUtils.showError(
        context,
        'Notification permission denied. Opening app settings now.',
        fallback: 'Notification permission denied. Opening app settings now.',
      );
      await openAppSettings();
    } catch (e) {
      if (!mounted) return;
      final message = ErrorMessageUtils.sanitize(
        e,
        fallback: 'Unable to request notification permission right now.',
      );
      SnackbarUtils.showError(
        context,
        message,
        fallback: 'Unable to request notification permission right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingNotificationPermission = false;
        });
      }
    }
  }

  Future<void> _handleNotificationToggleTap(bool currentlyEnabled) async {
    if (_isRequestingNotificationPermission) return;

    // When profile shows OFF, take user directly to app settings to enable it.
    if (!currentlyEnabled) {
      final opened = await openAppSettings();
      if (!opened && mounted) {
        SnackbarUtils.showError(
          context,
          'Unable to open app settings. Please open settings manually.',
          fallback:
              'Unable to open app settings. Please open settings manually.',
        );
      }
      return;
    }

    await _requestNotificationPermissionFromProfile();
  }

  String _subscriptionPlanName() {
    if (_isLoadingSubscription) return 'Loading...';
    if (_currentSubscription?.planName != null &&
        _currentSubscription!.planName!.isNotEmpty) {
      return _currentSubscription!.planName!;
    }
    return 'Free Trial';
  }

  String _subscriptionExpiryText() {
    if (_isLoadingSubscription) return 'Please wait...';
    if (_currentSubscription?.endDate != null) {
      final endDate = DateTime.tryParse(_currentSubscription!.endDate!);
      if (endDate != null) {
        return 'Valid until ${_formatDate(endDate.toIso8601String())}';
      }
    }
    return 'No active paid plan';
  }

  Color _subscriptionStatusColor() {
    final status = _subscriptionStatus();
    if (status == 'Active') return const Color(0xFF0F9D58);
    if (status == 'Loading...') return const Color(0xFF1A73E8);
    return const Color(0xFFD93025);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F6FB),
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _error != null && _profile == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Unable to load profile right now.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshAll,
              color: const Color(0xFF2E5BFF),
              backgroundColor: Colors.white,
              elevation: 0,
              strokeWidth: 2.2,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _buildHeroHeader(),
                  const SizedBox(height: 18),
                  _buildProfileCard(),
                  const SizedBox(height: 18),
                  _buildSubscriptionCard(),
                  const SizedBox(height: 18),
                  _buildVisibilityCard(),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1266F1), Color(0xFF00A3FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x331266F1),
                            blurRadius: 14,
                            offset: Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          if (result != null && mounted) {
                            await _refreshAll();
                          }
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1266F1),
                          shadowColor: Colors.transparent,
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroHeader() {
    final profile = _profile;
    final firstName = profile?.firstName?.trim() ?? '';
    final lastName = profile?.lastName?.trim() ?? '';
    final name = ('$firstName $lastName').trim().isEmpty
        ? 'User'
        : ('$firstName $lastName').trim();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E4BA8), Color(0xFF168CE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white24,
            backgroundImage:
                profile?.profileImage != null &&
                    profile!.profileImage!.isNotEmpty
                ? NetworkImage(profile.profileImage!)
                : null,
            child:
                profile?.profileImage == null || profile!.profileImage!.isEmpty
                ? Text(
                    name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Member since ${_formatDate(profile?.registrationDate)}',
                  style: const TextStyle(
                    color: Color(0xFFE3F2FF),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Completed Trades: ${profile?.totalTradesCompleted ?? 0}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final profile = _profile;
    final firstName = profile?.firstName?.trim() ?? '';
    final lastName = profile?.lastName?.trim() ?? '';
    final name = ('$firstName $lastName').trim().isEmpty
        ? 'User'
        : ('$firstName $lastName').trim();
    final location = (profile?.homeAddress?.toString() ?? '').trim();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact & Account',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            _buildInfoTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: profile?.email?.trim().isNotEmpty == true
                  ? profile!.email!
                  : '-',
            ),
            _buildInfoTile(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: profile?.mobileNumber?.trim().isNotEmpty == true
                  ? profile!.mobileNumber!
                  : '-',
            ),
            _buildInfoTile(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: location.isNotEmpty ? location : '-',
            ),
            _buildInfoTile(
              icon: Icons.handshake_outlined,
              label: 'Total Posts',
              value: '${profile?.totalPosts ?? 0}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityCard() {
    final profile = _profile;
    final notificationsEnabled = profile?.notificationEnabled ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visibility Settings',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            const Text(
              'NOTIFICATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9AA0A6),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _buildVisibilitySection(
              children: [
                _buildVisibilityRow(
                  label: 'Push Notifications',
                  enabled: notificationsEnabled,
                  onTap: _isRequestingNotificationPermission
                      ? null
                      : () =>
                            _handleNotificationToggleTap(notificationsEnabled),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'PRIVACY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF9AA0A6),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            _buildVisibilitySection(
              children: [
                _buildVisibilityRow(
                  label: 'Share Email',
                  enabled: profile?.shareEmail ?? true,
                ),
                _buildVisibilityRow(
                  label: 'Share Phone Number',
                  enabled: profile?.sharePhone ?? true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isRequestingNotificationPermission)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Requesting notification permission...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (!notificationsEnabled)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'Tap notifications row to open app settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              'Other users can only see your shared contact details according to your settings.',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilitySection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE6E8EF)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildVisibilityRow({
    required String label,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF4B4F5C),
                  ),
                ),
              ),
              _buildStaticToggle(enabled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaticToggle(bool enabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 46,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF22C55E) : const Color(0xFFD1D5DB),
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: enabled ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7ECF3)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Subscription',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _subscriptionStatusColor().withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _subscriptionStatus(),
                    style: TextStyle(
                      color: _subscriptionStatusColor(),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Plan',
              value: _subscriptionPlanName(),
            ),
            _buildInfoTile(
              icon: Icons.event_available_outlined,
              label: 'Details',
              value: _subscriptionExpiryText(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF5C6F89)),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
