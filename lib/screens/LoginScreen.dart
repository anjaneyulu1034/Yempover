import 'package:flutter/material.dart';
import 'package:yempower_app/constants/api_constants.dart';
import 'package:yempower_app/screens/Home_screen.dart';
import 'package:yempower_app/screens/OTPVerificationScreen.dart';
import 'package:yempower_app/screens/SignupScreen.dart';
import 'package:yempower_app/services/api_service.dart' hide ErrorMessages;
import 'package:yempower_app/services/auth_service.dart';
import 'package:yempower_app/services/token_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    debugPrint('🟣 LoginScreen: initState() called');
    //_checkIfAlreadyLoggedIn();
  }

  // Future<void> _checkIfAlreadyLoggedIn() async {
  //   final isLoggedIn = await TokenService().isLoggedIn();
  //   if (isLoggedIn && mounted) {
  //     debugPrint('🟣 LoginScreen: User already logged in, navigating to home');
  //     _navigateToHomeScreen();
  //   }
  // }

  @override
  void dispose() {
    _phoneController.dispose();
    debugPrint('🟣 LoginScreen: dispose() called');
    super.dispose();
  }

  String? _validatePhone(String? value) {
    debugPrint('🟣 LoginScreen: _validatePhone called with value: "$value"');
    if (value == null || value.isEmpty) {
      return ErrorMessages.emptyField;
    }
    if (!ValidationRegex.phoneRegex.hasMatch(value)) {
      return ErrorMessages.invalidPhoneNumber;
    }
    return null;
  }

  void _loginAsGuest() {
    debugPrint('🟣 LoginScreen: _loginAsGuest() called');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Guest Mode'),
        content: const Text(
          'You are now browsing as a guest. Some features may be limited.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🟣 LoginScreen: Guest mode cancelled');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              debugPrint('🟣 LoginScreen: Continuing as guest');
              Navigator.pop(context); // Close dialog
              _navigateToHomeScreen(); // Navigate to home screen
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
    debugPrint('🟣 LoginScreen: _navigateToHomeScreen() called');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _navigateToSignupScreen() {
    debugPrint('🟣 LoginScreen: _navigateToSignupScreen() called');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  Future<void> _handleLogin() async {
    debugPrint('🟣 LoginScreen: _handleLogin() called');

    if (!_formKey.currentState!.validate()) {
      debugPrint('🔴 LoginScreen: Form validation failed');
      return;
    }

    debugPrint('🟢 LoginScreen: Form validation passed');
    debugPrint('📱 LoginScreen: Phone number: ${_phoneController.text}');

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 LoginScreen: Calling sendOtp API...');
      // First send OTP
      final otpResponse = await _authService.sendOtp(
        mobileNumber: _phoneController.text.trim(),
      );

      debugPrint(
        '📨 LoginScreen: API Response - Success: ${otpResponse.isSuccess}, Message: ${otpResponse.message}',
      );

      if (otpResponse.isSuccess) {
        debugPrint(
          '🟢 LoginScreen: OTP sent successfully, navigating to OTP screen',
        );
        // Navigate to OTP screen for login
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              phoneNumber: _phoneController.text.trim(),
              onVerificationSuccess: (_) => _navigateToHomeScreen(),
              isSignupFlow: false,
            ),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(otpResponse.message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        debugPrint('🔴 LoginScreen: OTP send failed: ${otpResponse.message}');
        AuthService.showErrorDialog(context, otpResponse.message);
      }
    } on ApiException catch (e) {
      debugPrint('🔴 LoginScreen: ApiException caught: ${e.message}');
      AuthService.showErrorDialog(context, e.message);
    } catch (e) {
      debugPrint('🔴 LoginScreen: General exception caught: $e');
      AuthService.showErrorDialog(context, ErrorMessages.unknownError);
    } finally {
      if (mounted) {
        debugPrint('🟣 LoginScreen: Setting isLoading to false');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🟣 LoginScreen: build() called');

    return Scaffold(
      backgroundColor: Colors.white,
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

                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                const Text(
                  AppConstants.appTagline,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),

                const SizedBox(height: 32),

                // Phone Field
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: 'Enter your phone number (e.g., +1234567890)',
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
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                  ),
                  validator: _validatePhone,
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
                            'Login',
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
                GestureDetector(
                  onTap: _navigateToSignupScreen,
                  child: const Text.rich(
                    TextSpan(
                      text: "Don't have account? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                        style: TextStyle(color: Colors.grey, fontSize: 14),
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
                          child: const Text(
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
