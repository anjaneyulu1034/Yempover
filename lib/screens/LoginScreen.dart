import 'package:flutter/material.dart';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/screens/Home_screen.dart';
import 'package:YemPover_app/screens/OTPVerificationScreen.dart';
import 'package:YemPover_app/screens/SignupScreen.dart';
import 'package:YemPover_app/services/api_service.dart';
import 'package:YemPover_app/services/auth_service.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final TokenService _tokenService = TokenService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    debugPrint('Ã°Å¸Å¸Â£ LoginScreen: initState() called');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    debugPrint('Ã°Å¸Å¸Â£ LoginScreen: dispose() called');
    super.dispose();
  }

  String? _validatePhone(String? value) {
    debugPrint(
      'Ã°Å¸Å¸Â£ LoginScreen: _validatePhone called with value: "$value"',
    );
    if (value == null || value.isEmpty) {
      return ErrorMessages.emptyField;
    }
    final sanitizedValue = value.trim().replaceAll(RegExp(r'\s+'), '');
    final digitsOnly = sanitizedValue.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }

    if (!ValidationRegex.phoneRegex.hasMatch(sanitizedValue)) {
      return ErrorMessages.invalidPhoneNumber;
    }
    return null;
  }

  void _loginAsGuest() {
    debugPrint('Ã°Å¸Å¸Â£ LoginScreen: _loginAsGuest() called');
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
              debugPrint('Ã°Å¸Å¸Â£ LoginScreen: Guest mode cancelled');
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              debugPrint('Ã°Å¸Å¸Â£ LoginScreen: Continuing as guest');
              await _tokenService.enableGuestMode();
              if (!mounted) return;
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
    debugPrint('Ã°Å¸Å¸Â£ LoginScreen: _navigateToHomeScreen() called');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _navigateToSignupScreen() {
    debugPrint('Ã°Å¸Å¸Â£ LoginScreen: _navigateToSignupScreen() called');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  Future<void> _handleLogin() async {
    debugPrint('Ã°Å¸Å¸Â£ LoginScreen: _handleLogin() called');

    if (!_formKey.currentState!.validate()) {
      debugPrint('Ã°Å¸â€Â´ LoginScreen: Form validation failed');
      return;
    }

    final phoneNumber = _phoneController.text.trim().replaceAll(
      RegExp(r'\s+'),
      '',
    );

    debugPrint('Ã°Å¸Å¸Â¢ LoginScreen: Form validation passed');
    debugPrint('Ã°Å¸â€œÂ± LoginScreen: Phone number: $phoneNumber');

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Ã°Å¸â€â€ž LoginScreen: Calling sendOtp API...');
      // First send OTP
      final otpResponse = await _authService.sendOtp(mobileNumber: phoneNumber);
      if (!mounted) return;

      debugPrint(
        'Ã°Å¸â€œÂ¨ LoginScreen: API Response - Success: ${otpResponse.isSuccess}, Message: ${otpResponse.message}',
      );

      if (otpResponse.isSuccess) {
        debugPrint(
          'Ã°Å¸Å¸Â¢ LoginScreen: OTP sent successfully, navigating to OTP screen',
        );
        // Navigate to OTP screen for login
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              phoneNumber: phoneNumber,
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
        debugPrint(
          'Ã°Å¸â€Â´ LoginScreen: OTP send failed: ${otpResponse.message}',
        );
        AuthService.showErrorDialog(context, otpResponse.message);
      }
    } on ApiException catch (e) {
      debugPrint('Ã°Å¸â€Â´ LoginScreen: ApiException caught: ${e.message}');
      if (!mounted) return;
      AuthService.showErrorDialog(context, e.message);
    } catch (e) {
      debugPrint('Ã°Å¸â€Â´ LoginScreen: General exception caught: $e');
      if (!mounted) return;
      AuthService.showErrorDialog(context, ErrorMessages.unknownError);
    } finally {
      if (mounted) {
        debugPrint('Ã°Å¸Å¸Â£ LoginScreen: Setting isLoading to false');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('Ã°Å¸Å¸Â£ LoginScreen: build() called');

    // Get screen size for responsive calculations
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final textScale = MediaQuery.of(context).textScaler.scale(1.0);
    final loginButtonHeight = (56 * textScale.clamp(1.0, 1.25)).toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: keyboardSpace > 0
                    ? 24
                    : 24 + MediaQuery.of(context).viewPadding.bottom,
              ),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          height: 110,
                          width: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFE5E7EB),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Image.asset(
                              'assets/YemPover_applogo.png',
                              fit: BoxFit.contain,
                            ),
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
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Welcome back.',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Login to your account',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),

                        const SizedBox(height: 32),

                        AppTextField(
                          label: 'Phone Number',
                          hint: 'e.g., +1234567890',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.grey,
                          ),
                          validator: _validatePhone,
                        ),

                        const SizedBox(height: 24),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: loginButtonHeight,
                          child: _isLoading
                              ? ElevatedButton(
                                  onPressed: null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppConstants.primaryColor
                                        .withValues(alpha: 0.7),
                                    minimumSize: Size.fromHeight(
                                      loginButtonHeight,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
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
                                    minimumSize: Size.fromHeight(
                                      loginButtonHeight,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                      fontSize: 18,
                                      height: 1.2,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                style: TextStyle(
                                  color: Colors.grey,
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
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                    ),
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

                        // Add extra bottom padding for smaller screens
                        SizedBox(height: keyboardSpace > 0 ? 20 : 0),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
