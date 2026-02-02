// import 'package:flutter/material.dart';
// import 'package:yempower_app/screens/Home_screen.dart';
// import 'package:yempower_app/screens/OTPVerificationScreen.dart';
// import 'package:yempower_app/screens/SignupScreen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final TextEditingController _phoneController = TextEditingController(
//     text: '(555) 555-1234',
//   );
//   bool _isLoading = false;

//   void _loginAsGuest() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text('Guest Mode'),
//         content: const Text(
//           'You are now browsing as a guest. Some features may be limited.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context); // Close dialog
//               _navigateToHomeScreen(); // Navigate to home screen
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF1A73E8),
//             ),
//             child: const Text('Continue as Guest'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _navigateToHomeScreen() {
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (_) => const HomeScreen()),
//     );
//   }

//   void _handleLogin() {
//     if (_phoneController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter your phone number'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     // Show loading
//     setState(() {
//       _isLoading = true;
//     });

//     // Simulate API call to send OTP
//     Future.delayed(const Duration(seconds: 2), () {
//       setState(() {
//         _isLoading = false;
//       });

//       // Navigate to OTP screen for login
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => OTPVerificationScreen(
//             phoneNumber: _phoneController.text,
//             onVerificationSuccess: _navigateToHomeScreen,
//             isSignupFlow: false,
//           ),
//         ),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               // Logo
//               Container(
//                 height: 80,
//                 width: 80,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF1A73E8),
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//                 child: const Icon(
//                   Icons.battery_charging_full,
//                   color: Colors.white,
//                   size: 40,
//                 ),
//               ),

//               const SizedBox(height: 24),

//               const Text(
//                 'YemPower',
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                   color: Color(0xFF1A73E8),
//                 ),
//               ),
//               const Text(
//                 'Battery Systems',
//                 style: TextStyle(fontSize: 14, color: Colors.grey),
//               ),

//               const SizedBox(height: 40),

//               // Welcome Text
//               const Text(
//                 'Hello Again!',
//                 style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 6),
//               const Text(
//                 'Welcome back.',
//                 style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               const Text(
//                 'Login to your account',
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),

//               const SizedBox(height: 32),

//               // Phone Field
//               TextField(
//                 controller: _phoneController,
//                 keyboardType: TextInputType.phone,
//                 decoration: InputDecoration(
//                   hintText: 'Enter your phone number',
//                   filled: true,
//                   fillColor: Colors.grey.shade100,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 18,
//                   ),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide.none,
//                   ),
//                   prefixIcon: const Icon(Icons.phone, color: Colors.grey),
//                 ),
//               ),

//               const SizedBox(height: 24),

//               // Login Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: _isLoading
//                     ? ElevatedButton(
//                         onPressed: null,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(
//                             0xFF1A73E8,
//                           ).withOpacity(0.7),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(28),
//                           ),
//                         ),
//                         child: const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         ),
//                       )
//                     : ElevatedButton(
//                         onPressed: _handleLogin,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF1A73E8),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(28),
//                           ),
//                         ),
//                         child: const Text(
//                           'Login',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//               ),

//               const SizedBox(height: 20),

//               // Sign Up
//               GestureDetector(
//                 onTap: () {
//                   Navigator.pushReplacement(
//                     context,
//                     MaterialPageRoute(builder: (_) => const SignupScreen()),
//                   );
//                 },
//                 child: const Text.rich(
//                   TextSpan(
//                     text: "Don't have account? ",
//                     style: TextStyle(color: Colors.grey),
//                     children: [
//                       TextSpan(
//                         text: 'Sign Up',
//                         style: TextStyle(
//                           color: Color(0xFF1A73E8),
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 32),

//               // Guest Login
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: Column(
//                   children: [
//                     const Text(
//                       'Skip this process to login as:',
//                       style: TextStyle(color: Colors.grey, fontSize: 14),
//                     ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       width: double.infinity,
//                       height: 48,
//                       child: OutlinedButton(
//                         onPressed: _loginAsGuest,
//                         style: OutlinedButton.styleFrom(
//                           side: BorderSide(color: Colors.grey.shade400),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: const Text(
//                           'Guest user',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Color(0xFF1A73E8),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:yempower_app/constants/api_constants.dart';

import 'package:yempower_app/screens/Home_screen.dart';
import 'package:yempower_app/screens/OTPVerificationScreen.dart';
import 'package:yempower_app/screens/SignupScreen.dart';
import 'package:yempower_app/services/auth_service.dart';
import 'package:yempower_app/utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final storedPhone = await _authService.getStoredPhone();
    if (storedPhone != null && mounted) {
      setState(() {
        _phoneController.text = storedPhone;
      });
    }
  }

  Future<void> _loginAsGuest() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Guest Mode'),
        content: const Text(
          'You are now browsing as a guest. Some features may be limited.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // Set guest mode
              await _authService.setGuestMode(true);

              // Navigate to home screen
              _navigateToHomeScreen();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: const Text('Continue as Guest'),
          ),
        ],
      ),
    );
  }

  void _navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> _handleLogin() async {
    // Reset error message
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final phone = _phoneController.text.trim();

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Call API to send login OTP
      final otpResponse = await _authService.sendLoginOtp(phone);

      if (otpResponse.success) {
        // Navigate to OTP screen for login
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              phoneNumber: phone,
              onVerificationSuccess: (authResponse) {
                // After OTP verification, navigate to home screen
                _navigateToHomeScreen();
              },
              isSignupFlow: false,
              devOtp: otpResponse.devMode ? otpResponse.otp : null,
            ),
          ),
        );
      } else {
        setState(() {
          _errorMessage = otpResponse.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.battery_charging_full,
                    color: Colors.white,
                    size: 40,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  AppConstants.appName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                Text(
                  AppConstants.appTagline,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppConstants.greyColor,
                  ),
                ),

                const SizedBox(height: 40),

                // Welcome Text
                const Text(
                  'Hello Again!',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Welcome back.',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Login to your account',
                  style: TextStyle(fontSize: 16, color: AppConstants.greyColor),
                ),

                const SizedBox(height: 32),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppConstants.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppConstants.primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number (e.g., +919876543210)',
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.phone,
                      color: AppConstants.greyColor,
                    ),
                  ),
                  validator: Validators.validatePhone,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 24),

                // Login Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: _isLoading
                      ? ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor
                                .withOpacity(0.7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Send OTP',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(color: AppConstants.greyColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Guest Login
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Skip this process to login as:',
                        style: TextStyle(
                          color: AppConstants.greyColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _loginAsGuest,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Guest user',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
