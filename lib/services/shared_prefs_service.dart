// services/shared_prefs_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _onboardingKey = 'has_seen_onboarding';

  // Mark that user has seen onboarding
  static Future<void> markOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      debugPrint('📱 SharedPrefs: Onboarding marked as seen');
    } catch (e) {
      debugPrint('🔴 SharedPrefs: Error marking onboarding: $e');
    }
  }

  // Check if user has seen onboarding
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_onboardingKey) ?? false;
      debugPrint('📱 SharedPrefs: Has seen onboarding: $hasSeen');
      return hasSeen;
    } catch (e) {
      debugPrint('🔴 SharedPrefs: Error checking onboarding: $e');
      return false;
    }
  }

  // Clear onboarding flag (useful for testing)
  static Future<void> clearOnboardingFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_onboardingKey);
      debugPrint('📱 SharedPrefs: Onboarding flag cleared');
    } catch (e) {
      debugPrint('🔴 SharedPrefs: Error clearing onboarding: $e');
    }
  }
}
