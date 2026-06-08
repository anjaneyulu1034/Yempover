import 'dart:convert';
import 'dart:io';

import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/auth_models.dart';
import 'package:yempover_app/screens/Home_screen.dart';
import 'package:yempover_app/screens/LoginScreen.dart';
import 'package:yempover_app/screens/OTPVerificationScreen.dart';
import 'package:yempover_app/services/api_service.dart';
import 'package:yempover_app/services/auth_service.dart';
import 'package:yempover_app/services/notification1_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/profile_session_manager.dart';
import 'package:yempover_app/utils/blocked_users_cache.dart';
import 'package:yempover_app/utils/image_picker_utils.dart';
import 'package:flutter/material.dart';

class SignupPhotoVerificationScreen extends StatefulWidget {
  final bool isLoginFlow;
  final String? pendingOtp;
  final bool uploadOnly;
  final void Function(User?)? onLoginComplete;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final bool acceptedTerms;

  const SignupPhotoVerificationScreen({
    super.key,
    this.isLoginFlow = false,
    this.pendingOtp,
    this.uploadOnly = false,
    this.onLoginComplete,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    required this.mobileNumber,
    this.acceptedTerms = false,
  });

  @override
  State<SignupPhotoVerificationScreen> createState() =>
      _SignupPhotoVerificationScreenState();
}

class _SignupPhotoVerificationScreenState
    extends State<SignupPhotoVerificationScreen> {
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  final NotificationService1 _notificationService = NotificationService1();

  File? _capturedPhoto;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    debugPrint('📸 SignupPhotoVerificationScreen: initState() called');
    debugPrint(
      '📸 SignupPhotoVerificationScreen: isLoginFlow=${widget.isLoginFlow}, '
      'uploadOnly=${widget.uploadOnly}, pendingOtp=${widget.pendingOtp != null}',
    );
    debugPrint(
      '📸 SignupPhotoVerificationScreen: mobileNumber=${widget.mobileNumber}',
    );
  }

  @override
  void dispose() {
    debugPrint('📸 SignupPhotoVerificationScreen: dispose() called');
    super.dispose();
  }

  Future<void> _captureLivePhoto() async {
    debugPrint('📸 SignupPhotoVerificationScreen: _captureLivePhoto() called');
    final photo = await ImagePickerUtils.takePhotoWithCamera();
    if (!mounted) return;

    if (photo != null) {
      debugPrint(
        '📸 SignupPhotoVerificationScreen: Photo captured at ${photo.path}',
      );
      setState(() {
        _capturedPhoto = photo;
      });
    } else {
      debugPrint('📸 SignupPhotoVerificationScreen: Photo capture cancelled');
    }
  }

  bool _isUserAlreadyExistsError(String errorMessage) {
    final lowerCaseMessage = errorMessage.toLowerCase();
    return lowerCaseMessage.contains('already exists') ||
        lowerCaseMessage.contains('already registered') ||
        lowerCaseMessage.contains('user exists') ||
        lowerCaseMessage.contains('already have an account') ||
        lowerCaseMessage.contains('duplicate') ||
        lowerCaseMessage.contains('already taken') ||
        lowerCaseMessage.contains('exist');
  }

  void _navigateToDashboard() {
    debugPrint('📸 SignupPhotoVerificationScreen: Navigating to dashboard');
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _completeVerificationAndNavigateHome({User? user}) async {
    if (!widget.isLoginFlow) return;

    final userId = user?.id ?? await TokenService().getUserId();
    try {
      await _apiService.completeVerification(userId: userId);
      debugPrint(
        '📸 SignupPhotoVerificationScreen: verificationPending set to false',
      );
    } on ApiException catch (e) {
      debugPrint(
        '🟡 SignupPhotoVerificationScreen: completeVerification failed - ${e.message}',
      );
    } catch (e) {
      debugPrint(
        '🟡 SignupPhotoVerificationScreen: completeVerification error - $e',
      );
    }

    if (!mounted) return;
    await _notificationService.showLoginSuccessNotification();
    _navigateToDashboard();
  }

  Future<String> _photoToDataUrl() async {
    final photoBytes = await _capturedPhoto!.readAsBytes();
    final photoBase64 = base64Encode(photoBytes);
    return 'data:image/jpeg;base64,$photoBase64';
  }

  Future<void> _uploadProfilePhoto(String photoDataUrl) async {
    debugPrint(
      '📸 SignupPhotoVerificationScreen: _uploadProfilePhoto() called',
    );
    try {
      final base64Image = photoDataUrl.split(',').last;
      final response = await _apiService.uploadProfileImageBase64(
        base64Image: base64Image,
        mimeType: 'image/jpeg',
      );
      debugPrint(
        '📸 SignupPhotoVerificationScreen: Upload profile photo success - '
        'status=${response.status}, message=${response.message}',
      );

      if (!mounted) return;
      await _completeVerificationAndNavigateHome();
    } on ApiException catch (e) {
      debugPrint(
        '🔴 SignupPhotoVerificationScreen: Upload profile photo ApiException - '
        '${e.message} (statusCode=${e.statusCode})',
      );
      rethrow;
    } catch (e) {
      debugPrint(
        '🔴 SignupPhotoVerificationScreen: Upload profile photo error - $e',
      );
      rethrow;
    }
  }

  Future<void> _verifyOtpWithPhoto(String photoDataUrl) async {
    debugPrint(
      '📸 SignupPhotoVerificationScreen: _verifyOtpWithPhoto() called',
    );
    debugPrint(
      '📸 SignupPhotoVerificationScreen: Phone=${widget.mobileNumber}, '
      'OTP=${widget.pendingOtp}',
    );

    try {
      final response = await _authService.verifyOtp(
        mobileNumber: widget.mobileNumber,
        otp: widget.pendingOtp!,
        photo: photoDataUrl,
      );

      debugPrint(
        '📨 SignupPhotoVerificationScreen: verifyOtp response - '
        'isSuccess=${response.isSuccess}, message=${response.message}',
      );

      if (!response.isSuccess || response.data == null) {
        debugPrint(
          '🔴 SignupPhotoVerificationScreen: verifyOtp failed - ${response.message}',
        );
        if (!mounted) return;
        AuthService.showErrorDialog(context, response.message);
        return;
      }

      final responseData = response.data!;
      debugPrint(
        '🟢 SignupPhotoVerificationScreen: verifyOtp success - '
        'userId=${responseData.user.id}',
      );

      ProfileSessionManager.instance.clearSession();
      BlockedUsersCache.instance.reset();

      await TokenService().saveTokens(
        token: responseData.token,
        refreshToken: responseData.refreshToken,
        userId: responseData.user.id,
      );
      await NotificationService1.syncTokenWithBackend();
      debugPrint('📸 SignupPhotoVerificationScreen: Tokens saved after OTP+photo');

      if (!mounted) return;
      await _completeVerificationAndNavigateHome(user: responseData.user);
    } on ApiException catch (e) {
      debugPrint(
        '🔴 SignupPhotoVerificationScreen: verifyOtp ApiException - '
        '${e.message} (statusCode=${e.statusCode})',
      );
      if (!mounted) return;
      AuthService.showErrorDialog(context, e.message);
    } catch (e) {
      debugPrint(
        '🔴 SignupPhotoVerificationScreen: verifyOtp unexpected error - $e',
      );
      if (!mounted) return;
      AuthService.showErrorDialog(context, ErrorMessages.unknownError);
    }
  }

  Future<void> _registerWithPhoto() async {
    debugPrint('📸 SignupPhotoVerificationScreen: _registerWithPhoto() called');

    if (_capturedPhoto == null) {
      debugPrint('🔴 SignupPhotoVerificationScreen: No photo captured');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture a live photo to continue.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final photoDataUrl = await _photoToDataUrl();
      debugPrint(
        '📸 SignupPhotoVerificationScreen: Photo encoded, '
        'dataUrl length=${photoDataUrl.length}',
      );

      if (widget.isLoginFlow) {
        debugPrint(
          '📸 SignupPhotoVerificationScreen: Login flow - '
          'pendingOtp=${widget.pendingOtp != null}, uploadOnly=${widget.uploadOnly}',
        );
        if (widget.pendingOtp != null) {
          await _verifyOtpWithPhoto(photoDataUrl);
        } else if (widget.uploadOnly) {
          await _uploadProfilePhoto(photoDataUrl);
        }
        return;
      }

      debugPrint(
        '📸 SignupPhotoVerificationScreen: Registering user - '
        'firstName=${widget.firstName}, lastName=${widget.lastName}, '
        'email=${widget.email}, mobile=${widget.mobileNumber}',
      );

      final response = await _authService.registerUser(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        mobileNumber: widget.mobileNumber,
        photo: photoDataUrl,
        acceptedTerms: widget.acceptedTerms,
      );

      debugPrint(
        '📨 SignupPhotoVerificationScreen: registerUser response - '
        'isSuccess=${response.isSuccess}, message=${response.message}',
      );

      if (response.isSuccess) {
        debugPrint('🟢 SignupPhotoVerificationScreen: Registration successful');
        await _notificationService.showSignupSuccessNotification();
        if (!mounted) return;
        _showSignupSuccessDialog();
      } else {
        debugPrint(
          '🔴 SignupPhotoVerificationScreen: Registration failed - ${response.message}',
        );
        if (_isUserAlreadyExistsError(response.message)) {
          if (!mounted) return;
          _showUserExistsDialog(response.message);
        } else {
          if (!mounted) return;
          AuthService.showErrorDialog(context, response.message);
        }
      }
    } on ApiException catch (e) {
      debugPrint(
        '🔴 SignupPhotoVerificationScreen: registerUser ApiException - '
        '${e.message} (statusCode=${e.statusCode})',
      );
      if (e.message.toLowerCase().contains('success') ||
          e.message.toLowerCase().contains('verify') ||
          e.message.toLowerCase().contains('otp')) {
        debugPrint(
          '🟡 SignupPhotoVerificationScreen: Treating ApiException as success',
        );
        await _notificationService.showSignupSuccessNotification();
        if (!mounted) return;
        _showSignupSuccessDialog();
      } else if (_isUserAlreadyExistsError(e.message)) {
        if (!mounted) return;
        _showUserExistsDialog(e.message);
      } else {
        if (!mounted) return;
        AuthService.showErrorDialog(context, e.message);
      }
    } catch (e) {
      debugPrint(
        '🔴 SignupPhotoVerificationScreen: registerUser unexpected error - $e',
      );
      if (!mounted) return;
      AuthService.showErrorDialog(context, ErrorMessages.unknownError);
    } finally {
      if (mounted) {
        debugPrint('📸 SignupPhotoVerificationScreen: Setting isLoading=false');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSignupSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade600,
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registration Successful!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Your account has been created successfully. Please verify your phone number to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _navigateToOTPScreen();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Verify Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToOTPScreen() {
    debugPrint(
      '📸 SignupPhotoVerificationScreen: Navigating to OTP screen - '
      'phone=${widget.mobileNumber}',
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OTPVerificationScreen(
          phoneNumber: widget.mobileNumber,
          onVerificationSuccess: (_) {},
          isSignupFlow: true,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please verify your phone number'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showUserExistsDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Account Already Exists'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
            ),
            child: const Text(
              'Go to Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📸 SignupPhotoVerificationScreen: build() called');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Photo Verification'),
        automaticallyImplyLeading: !widget.isLoginFlow,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final padding = EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).viewPadding.bottom,
            );

            return SingleChildScrollView(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - padding.vertical,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Take a live photo to complete your registration.',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 260,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                          color: Colors.grey.shade100,
                        ),
                        child: _capturedPhoto == null
                            ? const Center(
                                child: Text(
                                  'No photo captured',
                                  style: TextStyle(color: Colors.black54),
                                ),
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  _capturedPhoto!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _captureLivePhoto,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          _capturedPhoto == null
                              ? 'Capture Live Photo'
                              : 'Retake Photo',
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _registerWithPhoto,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppConstants.primaryColor,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Complete Registration',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
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
