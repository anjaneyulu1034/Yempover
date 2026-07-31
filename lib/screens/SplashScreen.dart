

import 'package:yempover_app/screens/LoginScreen.dart';
import 'package:yempover_app/services/shared_prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:yempover_app/screens/OnboardingScreen.dart';
import 'package:yempover_app/screens/Home_screen.dart';
import 'package:yempover_app/screens/PostDetailScreen.dart';
import 'package:yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/main.dart';
import 'package:yempover_app/models/ProductPostmain.dart';
import 'package:yempover_app/services/api_service.dart';
import 'package:yempover_app/services/resume_state_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Small delay for splash screen visibility
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Check if user is already logged in
      final isLoggedIn = await TokenService().isLoggedIn();
      final isGuestUser = await TokenService().isGuestUser();

      // Check if onboarding has been seen before
      final hasSeenOnboarding = await SharedPrefsService.hasSeenOnboarding();

      if (!mounted) return;

      if (isLoggedIn || isGuestUser) {
        debugPrint(
          '🟢 SplashScreen: User is authenticated or guest, navigating to Home',
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        // Fire-and-forget: if the OS killed the app while the user was on
        // a chat or post detail screen, reopen it on top of Home instead
        // of silently dropping them back at the top-level feed.
        _restoreLastScreen();
      } else {
        if (!hasSeenOnboarding) {
          debugPrint('🟢 SplashScreen: First time user, showing onboarding');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          );
        } else {
          debugPrint('🟢 SplashScreen: Returning user, showing login');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint('🔴 SplashScreen: Error checking login status: $e');
      if (!mounted) return;

      // On error, default to onboarding for safety
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  /// Reopens the chat/post the user last had open, if the app records one
  /// (only true when the process was killed mid-screen rather than the
  /// user backing out normally — see [ResumeStateService]). Any failure
  /// here (deleted chat/post, network error, etc.) just leaves the user on
  /// Home rather than surfacing an error for something they didn't ask for.
  Future<void> _restoreLastScreen() async {
    try {
      final record = await ResumeStateService.read();
      if (record == null) return;

      // Home is pushed synchronously above with no transition animation
      // configured app-wide, but give the frame a beat to settle before
      // pushing on top of it via the root navigator.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final navigator = rootNavigatorKey.currentState;
      if (navigator == null) return;

      final type = record['type'];
      final id = record['id'];
      if (id == null || id.isEmpty) return;

      if (type == 'chat') {
        final currentUserId = await TokenService().getUserId();
        if (currentUserId == null || currentUserId.isEmpty) return;

        final chat = await TradeChatService().getChatById(id);
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              chat: chat,
              currentUserId: currentUserId,
              onChatUpdated: (_) {},
            ),
          ),
        );
      } else if (type == 'post') {
        final isService = record['isService'] == 'true';
        final response = await ApiService().getPostDetail(
          postId: id,
          type: isService ? PostType.service : PostType.product,
        );
        navigator.push(
          MaterialPageRoute(
            builder: (_) =>
                PostDetailScreen(post: response.post, userItems: const []),
          ),
        );
      }
    } catch (e) {
      debugPrint('🟡 SplashScreen: Could not restore last screen: $e');
    } finally {
      // Consume the record either way — don't keep retrying a broken
      // restore on every future cold start.
      await ResumeStateService.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Image.asset(
                  'assets/BarterX_applogo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // App Name
            const Column(
              children: [
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  AppConstants.appTagline,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            // Loading Indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
