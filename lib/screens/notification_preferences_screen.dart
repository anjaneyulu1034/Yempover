// lib/screens/notification_preferences_screen.dart
import 'package:Yempover_app/utils/loading_widget.dart';
import 'package:Yempover_app/utils/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.loadPreferences();
    setState(() => _isLoading = false);
  }

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await provider.updatePreferences();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _savePreferences,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                final prefs = provider.preferences;
                if (prefs == null) {
                  return const Center(
                    child: Text('Failed to load preferences'),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notification Types',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Offer Notifications
                      _buildSwitchTile(
                        title: 'Offer Notifications',
                        subtitle: 'Get notified when you receive offers',
                        value: prefs.offerNotifications,
                        icon: Icons.local_offer,
                        onChanged: (value) {
                          provider.updatePreference(
                            prefs.copyWith(offerNotifications: value),
                          );
                        },
                      ),

                      const Divider(),

                      // Message Notifications
                      _buildSwitchTile(
                        title: 'Message Notifications',
                        subtitle: 'Get notified when you receive messages',
                        value: prefs.messageNotifications,
                        icon: Icons.message,
                        onChanged: (value) {
                          provider.updatePreference(
                            prefs.copyWith(messageNotifications: value),
                          );
                        },
                      ),

                      const Divider(),

                      // Deal Notifications
                      _buildSwitchTile(
                        title: 'Deal Notifications',
                        subtitle: 'Get notified about deal updates',
                        value: prefs.dealNotifications,
                        icon: Icons.handshake,
                        onChanged: (value) {
                          provider.updatePreference(
                            prefs.copyWith(dealNotifications: value),
                          );
                        },
                      ),

                      const Divider(),

                      // Block Notifications
                      _buildSwitchTile(
                        title: 'Block Notifications',
                        subtitle: 'Get notified when users are blocked',
                        value: prefs.blockNotifications,
                        icon: Icons.block,
                        onChanged: (value) {
                          provider.updatePreference(
                            prefs.copyWith(blockNotifications: value),
                          );
                        },
                      ),

                      const Divider(),

                      // Promotional Notifications
                      _buildSwitchTile(
                        title: 'Promotional Notifications',
                        subtitle: 'Receive updates about offers and promotions',
                        value: prefs.promotionalNotifications,
                        icon: Icons.campaign,
                        onChanged: (value) {
                          provider.updatePreference(
                            prefs.copyWith(promotionalNotifications: value),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Delivery Channels',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Push Notifications
                      _buildSwitchTile(
                        title: 'Push Notifications',
                        subtitle: 'Receive notifications on this device',
                        value: prefs.pushEnabled,
                        icon: Icons.notifications_active,
                        onChanged: (value) {
                          provider.updatePreference(
                            prefs.copyWith(pushEnabled: value),
                          );
                        },
                      ),

                      const Divider(),

                      // Email Notifications
                      _buildSwitchTile(
                        title: 'Email Notifications',
                        subtitle: 'Receive notifications via email',
                        value: prefs.emailEnabled,
                        icon: Icons.email,
                        onChanged: (value) {
                          provider.updatePreference(
                            prefs.copyWith(emailEnabled: value),
                          );
                        },
                      ),

                      const Divider(),

                      // SMS Notifications
                      _buildSwitchTile(
                        title: 'SMS Notifications',
                        subtitle: 'Receive notifications via SMS',
                        value: prefs.smsEnabled,
                        icon: Icons.sms,
                        onChanged: (value) {
                          provider.updatePreference(
                            prefs.copyWith(smsEnabled: value),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      secondary: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: value ? Colors.blue.shade50 : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: value ? Colors.blue : Colors.grey, size: 20),
      ),
      activeColor: Colors.blue,
      onChanged: _isSaving ? null : onChanged,
    );
  }
}
