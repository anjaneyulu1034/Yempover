import 'package:YemPover_app/screens/PrivacyPolicyScreen.dart';
import 'package:YemPover_app/screens/SignupPhotoVerificationScreen.dart';
import 'package:YemPover_app/screens/TermsAndConditionsScreen.dart';
import 'package:YemPover_app/services/notification1_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/screens/LoginScreen.dart';

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

  String? _validatePhone(String? value) {
    debugPrint('🔵 SignupScreen: _validatePhone called with value: "$value"');
    if (value == null || value.isEmpty) {
      return ErrorMessages.emptyField;
    }
    if (!ValidationRegex.phoneRegex.hasMatch(value)) {
      return ErrorMessages.invalidPhoneNumber;
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
    debugPrint(
      '📋 SignupScreen: Form data - First: ${_firstNameController.text}, Last: ${_lastNameController.text}, Phone: ${_phoneController.text}, Email: ${_emailController.text}',
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignupPhotoVerificationScreen(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          mobileNumber: _phoneController.text.trim(),
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
                        'assets/YemPover_applogo.png',
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
                const Text(
                  'YemPover Barter System!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create a new account',
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 32),

                // First Name
                _buildField(
                  label: 'First Name',
                  controller: _firstNameController,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),

                // Last Name
                _buildField(
                  label: 'Last Name',
                  controller: _lastNameController,
                  validator: _validateName,
                ),
                const SizedBox(height: 16),

                // Phone
                _buildField(
                  label: 'Phone Number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                ),
                const SizedBox(height: 16),

                // Email
                _buildField(
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final borderRadius = BorderRadius.circular(12);
    final outlineBorder = OutlineInputBorder(
      borderRadius: borderRadius,
      borderSide: BorderSide(color: Colors.grey.shade300),
    );

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        floatingLabelStyle: const TextStyle(
          color: AppConstants.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: validator,
    );
  }
}
