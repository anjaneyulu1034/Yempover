import 'package:flutter/material.dart';
import 'package:Yempover_app/constants/api_constants.dart';
import 'package:Yempover_app/models/auth_models.dart';
import 'package:Yempover_app/services/api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // TODO: Replace with your actual user model or state management
  dynamic currentUser;

  Future<AuthResponse<RegisterResponseData>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String mobileNumber,
    required String photo,
    required bool acceptedTerms, // ✅ NEW
  }) async {
    debugPrint('👤 AuthService: registerUser called');
    debugPrint('👤 AuthService: First: $firstName, Last: $lastName');
    debugPrint('👤 AuthService: Email: $email, Phone: $mobileNumber');

    final request = RegisterRequest(
      firstName: firstName,
      lastName: lastName,
      email: email,
      mobileNumber: mobileNumber,
      photo: photo,
      acceptedTerms: acceptedTerms, // ✅ NEW
    );

    return await _apiService.register(request);
  }

  Future<AuthResponse<SendOtpResponseData>> sendOtp({
    required String mobileNumber,
  }) async {
    debugPrint('📱 AuthService: sendOtp called for: $mobileNumber');
    final request = SendOtpRequest(mobileNumber: mobileNumber);
    return await _apiService.sendOtp(request);
  }

  Future<AuthResponse<VerifyOtpResponseData>> verifyOtp({
    required String mobileNumber,
    required String otp,
  }) async {
    debugPrint('✅ AuthService: verifyOtp called');
    debugPrint('✅ AuthService: Phone: $mobileNumber, OTP: $otp');
    final request = VerifyOtpRequest(mobileNumber: mobileNumber, otp: otp);
    return await _apiService.verifyOtp(request);
  }

  static void showErrorDialog(BuildContext context, String message) {
    debugPrint('🚨 AuthService: Showing error dialog: $message');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Error',
          style: TextStyle(color: AppConstants.errorColor),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🚨 AuthService: Error dialog closed');
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showSuccessDialog(BuildContext context, String message) {
    debugPrint('🎉 AuthService: Showing success dialog: $message');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          'Success',
          style: TextStyle(color: AppConstants.successColor),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('🎉 AuthService: Success dialog closed');
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showLoadingDialog(BuildContext context) {
    debugPrint('⏳ AuthService: Showing loading dialog');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              AppConstants.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  bool get isAuthenticated => currentUser != null;

  Future<void> logout() async {
    try {
      // Clear user authentication data
      currentUser = null;

      // Add any additional logout logic here:
      // - Clear stored tokens
      // - Clear local cache
      // - Reset API client
      // - etc.

      notifyListeners();
    } catch (e) {
      print('Logout error: $e');
      rethrow;
    }
  }
}
