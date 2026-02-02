// import 'package:flutter/material.dart';
// import 'package:yempower_app/screens/LocationScreen.dart';
// import 'package:yempower_app/screens/OTPVerificationScreen.dart';

// class SignupScreen extends StatefulWidget {
//   const SignupScreen({super.key});

//   @override
//   State<SignupScreen> createState() => _SignupScreenState();
// }

// class _SignupScreenState extends State<SignupScreen> {
//   final TextEditingController _nameController = TextEditingController(
//     text: 'James',
//   );
//   final TextEditingController _phoneController = TextEditingController(
//     text: '(555) 555-1234',
//   );
//   final TextEditingController _emailController = TextEditingController(
//     text: 'james.test@gmail.com',
//   );

//   bool _agreeToTerms = true;
//   bool _isLoading = false;

//   void _handleSignup() {
//     if (!_agreeToTerms) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please agree to the Terms & Conditions'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (_nameController.text.isEmpty ||
//         _phoneController.text.isEmpty ||
//         _emailController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please fill all fields'),
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

//       // Navigate to OTP screen for signup
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (_) => OTPVerificationScreen(
//             phoneNumber: _phoneController.text,
//             onVerificationSuccess: () {
//               // After OTP verification, navigate to location screen
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (_) => const LocationScreen()),
//               );
//             },
//             isSignupFlow: true,
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
//         child: SingleChildScrollView(
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
//                 child: const Center(
//                   child: Icon(
//                     Icons.battery_charging_full,
//                     size: 40,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

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

//               const SizedBox(height: 32),

//               // Title
//               const Text(
//                 'Welcome to',
//                 style: TextStyle(fontSize: 16, color: Colors.grey),
//               ),
//               const SizedBox(height: 4),
//               const Text(
//                 'YemPower Barter System!',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 6),
//               const Text(
//                 'Create a new account',
//                 style: TextStyle(color: Colors.grey),
//               ),

//               const SizedBox(height: 32),

//               // Name
//               _buildField(hint: 'Full Name', controller: _nameController),
//               const SizedBox(height: 16),

//               // Phone
//               _buildField(
//                 hint: 'Phone Number',
//                 controller: _phoneController,
//                 keyboardType: TextInputType.phone,
//               ),
//               const SizedBox(height: 16),

//               // Email
//               _buildField(
//                 hint: 'Email Address',
//                 controller: _emailController,
//                 keyboardType: TextInputType.emailAddress,
//               ),

//               const SizedBox(height: 20),

//               // Terms
//               Row(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Checkbox(
//                     value: _agreeToTerms,
//                     activeColor: const Color(0xFF1A73E8),
//                     onChanged: (value) {
//                       setState(() => _agreeToTerms = value ?? false);
//                     },
//                   ),
//                   Expanded(
//                     child: Text.rich(
//                       TextSpan(
//                         text: 'I agree to the ',
//                         style: const TextStyle(color: Colors.grey),
//                         children: const [
//                           TextSpan(
//                             text: 'Terms & Conditions',
//                             style: TextStyle(
//                               color: Color(0xFF1A73E8),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                           TextSpan(text: ' and '),
//                           TextSpan(
//                             text: 'Privacy Policy',
//                             style: TextStyle(
//                               color: Color(0xFF1A73E8),
//                               fontWeight: FontWeight.w600,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),

//               const SizedBox(height: 24),

//               // Sign Up Button
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
//                         onPressed: _agreeToTerms ? _handleSignup : null,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF1A73E8),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(28),
//                           ),
//                         ),
//                         child: const Text(
//                           'Sign Up',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildField({
//     required String hint,
//     required TextEditingController controller,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return TextField(
//       controller: controller,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: Colors.grey.shade100,
//         contentPadding: const EdgeInsets.symmetric(
//           horizontal: 16,
//           vertical: 18,
//         ),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:yempower_app/constants/api_constants.dart';

import 'package:yempower_app/screens/LocationScreen.dart';
import 'package:yempower_app/screens/LoginScreen.dart';
import 'package:yempower_app/screens/OTPVerificationScreen.dart';
import 'package:yempower_app/services/auth_service.dart';
import 'package:yempower_app/utils/validators.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _agreeToTerms = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscureText = true;

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

  Future<void> _handleSignup() async {
    // Reset error message
    setState(() {
      _errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the Terms & Conditions';
      });
      return;
    }

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Call API to send OTP
      final otpResponse = await _authService.sendSignupOtp(
        name: name,
        phone: phone,
        email: email,
        termsAccepted: _agreeToTerms,
      );

      if (otpResponse.success) {
        // Navigate to OTP screen for signup
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              phoneNumber: phone,
              onVerificationSuccess: (authResponse) {
                // After OTP verification, navigate to location screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LocationScreen()),
                );
              },
              isSignupFlow: true,
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
        child: SingleChildScrollView(
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
                  child: const Center(
                    child: Icon(
                      Icons.battery_charging_full,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Welcome to',
                  style: TextStyle(fontSize: 16, color: AppConstants.greyColor),
                ),
                const SizedBox(height: 4),
                const Text(
                  'YemPower Barter System!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create a new account',
                  style: TextStyle(color: AppConstants.greyColor),
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

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Full Name',
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
                      Icons.person_outline,
                      color: AppConstants.greyColor,
                    ),
                  ),
                  validator: Validators.validateName,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Phone Number (e.g., +919876543210)',
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
                      Icons.phone_outlined,
                      color: AppConstants.greyColor,
                    ),
                  ),
                  validator: Validators.validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Email Address',
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
                      Icons.email_outlined,
                      color: AppConstants.greyColor,
                    ),
                  ),
                  validator: Validators.validateEmail,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 20),

                // Terms Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      activeColor: AppConstants.primaryColor,
                      onChanged: (value) {
                        setState(() {
                          _agreeToTerms = value ?? false;
                          if (_errorMessage ==
                              'Please agree to the Terms & Conditions') {
                            _errorMessage = null;
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          // Show terms dialog
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Terms & Conditions'),
                              content: SingleChildScrollView(
                                child: Text.rich(
                                  TextSpan(
                                    text:
                                        'By creating an account, you agree to our ',
                                    style: const TextStyle(
                                      color: AppConstants.greyColor,
                                    ),
                                    children: const [
                                      TextSpan(
                                        text: 'Terms & Conditions',
                                        style: TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: TextStyle(
                                          color: AppConstants.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      TextSpan(text: '. This includes:\n\n'),
                                      TextSpan(
                                        text: '• Agreement to service terms\n',
                                      ),
                                      TextSpan(
                                        text:
                                            '• Privacy and data usage policies\n',
                                      ),
                                      TextSpan(
                                        text: '• User responsibilities\n',
                                      ),
                                      TextSpan(text: '• Service limitations\n'),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            text: 'I agree to the ',
                            style: const TextStyle(
                              color: AppConstants.greyColor,
                            ),
                            children: const [
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Sign Up Button
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
                          onPressed: _handleSignup,
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

                // Already have account?
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: AppConstants.greyColor),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
