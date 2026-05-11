// // ignore: file_names
// import 'package:flutter/material.dart';
// import 'package:YemPover_app/screens/OnboardingScreen.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Simulate splash screen delay
//     Future.delayed(const Duration(seconds: 2), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const OnboardingScreen()),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF1A73E8),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // App Logo/Icon
//             Container(
//               width: 120,
//               height: 120,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withValues(alpha: 0.1),
//                     blurRadius: 20,
//                     spreadRadius: 2,
//                   ),
//                 ],
//               ),
//               child: const Icon(
//                 Icons.battery_charging_full,
//                 size: 64,
//                 color: Color(0xFF1A73E8),
//               ),
//             ),
//             const SizedBox(height: 30),
//             // App Name
//             const Column(
//               children: [
//                 Text(
//                   'YemPover',
//                   style: TextStyle(
//                     fontSize: 36,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                     letterSpacing: 1.2,
//                   ),
//                 ),
//                 SizedBox(height: 8),
//                 Text(
//                   'Battery System',
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.white70,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 50),
//             // Loading Indicator
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//               strokeWidth: 2,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// screens/SplashScreen.dart

import 'package:YemPover_app/screens/LoginScreen.dart';
import 'package:YemPover_app/services/shared_prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:YemPover_app/screens/OnboardingScreen.dart';
import 'package:YemPover_app/screens/Home_screen.dart';
import 'package:YemPover_app/services/token_service.dart';

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
                  'assets/YemPover_applogo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // App Name
            const Column(
              children: [
                Text(
                  'YemPover',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Barter System',
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
