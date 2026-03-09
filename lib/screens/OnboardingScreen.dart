// import 'package:flutter/material.dart';
// import 'package:Yempover_app/screens/SignupScreen.dart';

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   _OnboardingScreenState createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _pageController = PageController();
//   int _currentPage = 0;

//   final List<OnboardingPage> _pages = [
//     OnboardingPage(
//       title: 'Welcome to\nYempover Barter System!',
//       description:
//           'Trade and exchange battery systems efficiently with our innovative platform.',
//       icon: Icons.battery_charging_full,
//     ),
//     OnboardingPage(
//       title: 'Easy Battery Trading',
//       description:
//           'List your batteries or find the perfect match for your energy needs.',
//       icon: Icons.swap_horiz,
//     ),
//     OnboardingPage(
//       title: 'Secure Transactions',
//       description:
//           'Safe and reliable trading with verified users and secure payments.',
//       icon: Icons.security,
//     ),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => const SignupScreen()),
//               );
//             },
//             child: const Text(
//               'Skip',
//               style: TextStyle(color: Color(0xFF1A73E8), fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: PageView.builder(
//               controller: _pageController,
//               itemCount: _pages.length,
//               onPageChanged: (index) {
//                 setState(() {
//                   _currentPage = index;
//                 });
//               },
//               itemBuilder: (context, index) {
//                 return OnboardingPageWidget(page: _pages[index]);
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               children: [
//                 // Page Indicators
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: List.generate(_pages.length, (index) {
//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 4),
//                       width: _currentPage == index ? 24 : 8,
//                       height: 8,
//                       decoration: BoxDecoration(
//                         color: _currentPage == index
//                             ? const Color(0xFF1A73E8)
//                             : Colors.grey.shade300,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     );
//                   }),
//                 ),
//                 const SizedBox(height: 40),
//                 // Next/Get Started Button
//                 SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       if (_currentPage < _pages.length - 1) {
//                         _pageController.nextPage(
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeInOut,
//                         );
//                       } else {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => const SignupScreen(),
//                           ),
//                         );
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF1A73E8),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 2,
//                     ),
//                     child: Text(
//                       _currentPage == _pages.length - 1
//                           ? 'Get Started'
//                           : 'Next',
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class OnboardingPage {
//   final String title;
//   final String description;
//   final IconData icon;

//   OnboardingPage({
//     required this.title,
//     required this.description,
//     required this.icon,
//   });
// }

// class OnboardingPageWidget extends StatelessWidget {
//   final OnboardingPage page;

//   const OnboardingPageWidget({super.key, required this.page});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 140,
//             height: 140,
//             decoration: BoxDecoration(
//               color: const Color(0xFF1A73E8).withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(page.icon, size: 64, color: const Color(0xFF1A73E8)),
//           ),
//           const SizedBox(height: 40),
//           Text(
//             page.title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: Colors.black87,
//               height: 1.3,
//             ),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             page.description,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade600,
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// screens/OnboardingScreen.dart

import 'package:flutter/material.dart';
import 'package:Yempover_app/screens/LoginScreen.dart';
import 'package:Yempover_app/services/shared_prefs_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to\nYempover Barter System!',
      description:
          'Trade and exchange items efficiently with our innovative platform.',
      icon: Icons.swap_horiz,
    ),
    OnboardingPage(
      title: 'Easy Trading',
      description: 'List your items or find the perfect match for your needs.',
      icon: Icons.shopping_bag,
    ),
    OnboardingPage(
      title: 'Secure Transactions',
      description: 'Safe and reliable trading with verified users.',
      icon: Icons.security,
    ),
  ];

  Future<void> _completeOnboarding() async {
    // Mark onboarding as seen
    await SharedPrefsService.markOnboardingSeen();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _completeOnboarding,
            child: const Text(
              'Skip',
              style: TextStyle(color: Color(0xFF1A73E8), fontSize: 16),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _pages.length,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemBuilder: (context, index) {
                return OnboardingPageWidget(page: _pages[index]);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? const Color(0xFF1A73E8)
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),
                // Next/Get Started Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A73E8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class OnboardingPageWidget extends StatelessWidget {
  final OnboardingPage page;

  const OnboardingPageWidget({super.key, required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: const Color(0xFF1A73E8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(page.icon, size: 64, color: const Color(0xFF1A73E8)),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
