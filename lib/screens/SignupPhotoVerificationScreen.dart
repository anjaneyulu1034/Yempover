import 'dart:convert';
import 'dart:io';

import 'package:Yempover_app/constants/api_constants.dart';
import 'package:Yempover_app/screens/LoginScreen.dart';
import 'package:Yempover_app/screens/OTPVerificationScreen.dart';
import 'package:Yempover_app/services/api_service.dart';
import 'package:Yempover_app/services/auth_service.dart';
import 'package:Yempover_app/services/notification1_service.dart';
import 'package:Yempover_app/utils/image_picker_utils.dart';
import 'package:flutter/material.dart';

class SignupPhotoVerificationScreen extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final bool acceptedTerms;

  const SignupPhotoVerificationScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.acceptedTerms,
  });

  @override
  State<SignupPhotoVerificationScreen> createState() =>
      _SignupPhotoVerificationScreenState();
}

class _SignupPhotoVerificationScreenState
    extends State<SignupPhotoVerificationScreen> {
  final AuthService _authService = AuthService();
  final NotificationService1 _notificationService = NotificationService1();

  File? _capturedPhoto;
  bool _isLoading = false;

  Future<void> _captureLivePhoto() async {
    final photo = await ImagePickerUtils.takePhotoWithCamera();
    if (!mounted) return;

    if (photo != null) {
      setState(() {
        _capturedPhoto = photo;
      });
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

  Future<void> _registerWithPhoto() async {
    if (_capturedPhoto == null) {
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
      final photoBytes = await _capturedPhoto!.readAsBytes();
      final photoBase64 = base64Encode(photoBytes);
      final photoDataUrl = 'data:image/jpeg;base64,$photoBase64';

      final response = await _authService.registerUser(
        firstName: widget.firstName,
        lastName: widget.lastName,
        email: widget.email,
        mobileNumber: widget.mobileNumber,
        photo: photoDataUrl,
        acceptedTerms: widget.acceptedTerms,
      );

      if (response.isSuccess) {
        await _notificationService.showSignupSuccessNotification();
        if (!mounted) return;
        _showSignupSuccessDialog();
      } else {
        if (_isUserAlreadyExistsError(response.message)) {
          if (!mounted) return;
          _showUserExistsDialog(response.message);
        } else {
          if (!mounted) return;
          AuthService.showErrorDialog(context, response.message);
        }
      }
    } on ApiException catch (e) {
      if (e.message.toLowerCase().contains('success') ||
          e.message.toLowerCase().contains('verify') ||
          e.message.toLowerCase().contains('otp')) {
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
    } catch (_) {
      if (!mounted) return;
      AuthService.showErrorDialog(context, ErrorMessages.unknownError);
    } finally {
      if (mounted) {
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
    return Scaffold(
      appBar: AppBar(title: const Text('Live Photo Verification')),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).viewPadding.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Take a live photo to complete your registration.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                        child: Image.file(_capturedPhoto!, fit: BoxFit.cover),
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
  }
}
