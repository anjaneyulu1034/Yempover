import 'package:yempover_app/screens/PrivacyPolicyScreen.dart';
import 'package:yempover_app/screens/SignupPhotoVerificationScreen.dart';
import 'package:yempover_app/screens/TermsAndConditionsScreen.dart';
import 'package:yempover_app/services/notification1_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/screens/LoginScreen.dart';
import 'package:yempover_app/widgets/app_text_field.dart';
import 'package:yempover_app/widgets/phone_number_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey<PhoneNumberFieldState> _phoneFieldKey =
      GlobalKey<PhoneNumberFieldState>();
  bool _agreeToTerms = false;
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('🔵 SignupScreen: initState() called');
    _getAndPrintFCMToken(); // Add this to verify token is working
  }

  // Add this method to verify FCM token
  Future<void> _getAndPrintFCMToken() async {
    String? token = await NotificationService1.getToken();
    debugPrint('📱 SignupScreen FCM Token: $token');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    debugPrint('🔵 SignupScreen: dispose() called');
    super.dispose();
  }

  String? _validateName(String? value) {
    debugPrint('🔵 SignupScreen: _validateName called with value: "$value"');
    if (value == null || value.isEmpty) {
      return ErrorMessages.emptyField;
    }
    if (!ValidationRegex.nameRegex.hasMatch(value)) {
      return 'Please enter a valid name (letters only)';
    }
    return null;
  }


  String? _validateEmail(String? value) {
    debugPrint('🔵 SignupScreen: _validateEmail called with value: "$value"');
    if (value == null || value.isEmpty) {
      return ErrorMessages.emptyField;
    }
    if (!ValidationRegex.emailRegex.hasMatch(value)) {
      return ErrorMessages.invalidEmail;
    }
    return null;
  }

  // Add these methods to your _SignupScreenState class

  void _navigateToTermsAndConditions() {
    debugPrint('🔵 SignupScreen: Navigating to Terms & Conditions');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen()),
    );
  }

  void _navigateToPrivacyPolicy() {
    debugPrint('🔵 SignupScreen: Navigating to Privacy Policy');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
    );
  }

  Future<void> _handleSignup() async {
    debugPrint('🔵 SignupScreen: _handleSignup() called');
    debugPrint('🔵 SignupScreen: Terms agreed: $_agreeToTerms');

    if (!_agreeToTerms) {
      debugPrint('🔴 SignupScreen: Terms not agreed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(ErrorMessages.termsNotAgreed),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('🔴 SignupScreen: Form validation failed');
      return;
    }

    debugPrint('🟢 SignupScreen: Form validation passed');
    final mobileNumber = _phoneFieldKey.currentState!.fullPhoneNumber;
    debugPrint(
      '📋 SignupScreen: Form data - First: ${_firstNameController.text}, Last: ${_lastNameController.text}, Phone: $mobileNumber, Email: ${_emailController.text}',
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupPhotoVerificationScreen(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          mobileNumber: mobileNumber,
          acceptedTerms: _agreeToTerms,
        ),
      ),
    );
  }

  void _navigateToLoginScreen() {
    debugPrint('🟢 SignupScreen: Navigating to LoginScreen');

    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    _emailController.clear();
    setState(() {
      _agreeToTerms = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔵 SignupScreen: build() called');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            24 + MediaQuery.of(context).viewPadding.bottom,
          ),
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
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Image.asset(
                        'assets/Yempover_Org-logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

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

                const SizedBox(height: 32),

                // Title
                const Text(
                  'Welcome to',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppConstants.appName}!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create a new account',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 32),

                AppTextField(
                  label: 'First Name',
                  controller: _firstNameController,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Last Name',
                  controller: _lastNameController,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),

                PhoneNumberField(
                  key: _phoneFieldKey,
                  controller: _phoneController,
                  hint: 'Enter phone number',
                ),
                const SizedBox(height: 16),

                AppTextField(
                  label: 'Email Address',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validateEmail,
                ),

                const SizedBox(height: 20),

                // Terms
                // Terms
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreeToTerms,
                      activeColor: AppConstants.primaryColor,
                      onChanged: (value) {
                        debugPrint(
                          '🔵 SignupScreen: Terms checkbox changed to: $value',
                        );
                        setState(() => _agreeToTerms = value ?? false);
                      },
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to the ',
                          style: const TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _navigateToTermsAndConditions,
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = _navigateToPrivacyPolicy,
                            ),
                          ],
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
                                .withValues(alpha: 0.7),
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
                          onPressed: _agreeToTerms ? _handleSignup : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 20),

                // Already have an account? Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(color: Colors.grey),
                    ),
                    GestureDetector(
                      onTap: _navigateToLoginScreen,
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
