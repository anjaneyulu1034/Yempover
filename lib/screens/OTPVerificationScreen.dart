import 'package:flutter/material.dart';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/models/auth_models.dart';
import 'package:YemPover_app/services/api_service.dart';
import 'package:YemPover_app/services/auth_service.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/services/notification1_service.dart';
import 'package:YemPover_app/screens/LoginScreen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final bool isSignupFlow;
  final Function(User?) onVerificationSuccess;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerificationSuccess,
    this.isSignupFlow = false,
  });

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  Duration _timerDuration = const Duration(seconds: 60);
  bool _isTimerActive = true;
  bool _isLoading = false;
  bool _isResending = false;
  final AuthService _authService = AuthService();
  final NotificationService1 _notificationService = NotificationService1();

  @override
  void initState() {
    super.initState();
    debugPrint('🟡 OTPVerificationScreen: initState() called');
    debugPrint('🟡 OTPVerificationScreen: Phone number: ${widget.phoneNumber}');
    debugPrint(
      '🟡 OTPVerificationScreen: isSignupFlow: ${widget.isSignupFlow}',
    );
    _startTimer();
    _getAndPrintFCMToken();
  }

  Future<void> _getAndPrintFCMToken() async {
    String? token = await NotificationService1.getToken();
    debugPrint('📱 OTPVerificationScreen FCM Token: $token');
  }

  void _startTimer() {
    debugPrint(
      '🟡 OTPVerificationScreen: _startTimer() called, current duration: ${_timerDuration.inSeconds}s',
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _timerDuration.inSeconds > 0) {
        setState(() {
          _timerDuration = Duration(seconds: _timerDuration.inSeconds - 1);
        });
        debugPrint(
          '🟡 OTPVerificationScreen: Timer tick: ${_timerDuration.inSeconds}s remaining',
        );
        _startTimer();
      } else if (mounted) {
        debugPrint('🟡 OTPVerificationScreen: Timer expired');
        setState(() {
          _isTimerActive = false;
        });
      }
    });
  }

  Future<void> _resendOTP() async {
    debugPrint('🟡 OTPVerificationScreen: _resendOTP() called');

    if (_isResending) {
      debugPrint('🔴 OTPVerificationScreen: Already resending OTP');
      return;
    }

    debugPrint('🔄 OTPVerificationScreen: Starting OTP resend process');
    setState(() {
      _isResending = true;
    });

    try {
      debugPrint('🔄 OTPVerificationScreen: Calling sendOtp API...');
      final response = await _authService.sendOtp(
        mobileNumber: widget.phoneNumber,
      );
      if (!mounted) return;

      debugPrint(
        '📨 OTPVerificationScreen: Resend API Response - Success: ${response.isSuccess}, Message: ${response.message}',
      );

      if (response.isSuccess) {
        debugPrint('🟢 OTPVerificationScreen: OTP resent successfully');
        setState(() {
          _timerDuration = const Duration(seconds: 60);
          _isTimerActive = true;
          // Clear all OTP fields
          for (var controller in _otpControllers) {
            controller.clear();
          }
          // Focus on first field
          FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
        });
        _startTimer();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP has been resent to your phone number'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        debugPrint(
          '🔴 OTPVerificationScreen: OTP resend failed: ${response.message}',
        );
        AuthService.showErrorDialog(context, response.message);
      }
    } on ApiException catch (e) {
      debugPrint(
        '🔴 OTPVerificationScreen: ApiException during resend: ${e.message}',
      );
      if (!mounted) return;
      AuthService.showErrorDialog(context, e.message);
    } catch (e) {
      debugPrint(
        '🔴 OTPVerificationScreen: General exception during resend: $e',
      );
      if (!mounted) return;
      AuthService.showErrorDialog(context, ErrorMessages.unknownError);
    } finally {
      if (mounted) {
        debugPrint('🟡 OTPVerificationScreen: Setting _isResending to false');
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyOTP() async {
    debugPrint('🟡 OTPVerificationScreen: _verifyOTP() called');

    // Check if all OTP fields are filled
    String otp = '';
    for (int i = 0; i < _otpControllers.length; i++) {
      debugPrint(
        '🟡 OTPVerificationScreen: OTP field $i: "${_otpControllers[i].text}"',
      );
      if (_otpControllers[i].text.isEmpty) {
        debugPrint('🔴 OTPVerificationScreen: OTP field $i is empty');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the complete OTP'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      otp += _otpControllers[i].text;
    }

    debugPrint('🟡 OTPVerificationScreen: Complete OTP entered: $otp');

    if (!ValidationRegex.otpRegex.hasMatch(otp)) {
      debugPrint('🔴 OTPVerificationScreen: Invalid OTP format: $otp');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(ErrorMessages.invalidOtp),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔄 OTPVerificationScreen: Calling verifyOtp API...');
      debugPrint(
        '📱 OTPVerificationScreen: Phone: ${widget.phoneNumber}, OTP: $otp',
      );

      final response = await _authService.verifyOtp(
        mobileNumber: widget.phoneNumber,
        otp: otp,
      );

      debugPrint(
        '📨 OTPVerificationScreen: Verify API Response - Success: ${response.isSuccess}, Message: ${response.message} otp:::: $otp',
      );

      if (response.isSuccess) {
        debugPrint('🟢 OTPVerificationScreen: OTP verification successful');
        debugPrint('🟢 User data received: ${response.data}');

        // Save tokens
        if (response.data != null) {
          final userId = response.data!.user.id;
          final token = response.data!.token;
          final refreshToken = response.data!.refreshToken;

          debugPrint('👤 User ID from response: $userId');
          debugPrint('🔑 Token from response: ${token.substring(0, 20)}...');

          await TokenService().saveTokens(
            token: token,
            refreshToken: refreshToken,
            userId: userId,
          );

          // Ensure device FCM token is registered with backend after auth is available.
          await NotificationService1.syncTokenWithBackend();

          debugPrint('✅ Tokens and user ID saved successfully');

          final savedUserId = await TokenService().getUserId();
          debugPrint('✅ Verified saved userId: $savedUserId');
        }

        // Show push notification based on flow
        if (widget.isSignupFlow) {
          // Show OTP verification success notification (same style as signup)
          await _notificationService.showOTPVerificationSuccessNotification();
          debugPrint('✅ OTP verification success notification shown');

          // Show success dialog (same style as signup)
          _showVerificationSuccessDialog();
        } else {
          // Show login success notification
          await _notificationService.showLoginSuccessNotification();
          debugPrint('✅ Login success notification shown');

          // Show success dialog for login (similar style)
          _showLoginSuccessDialog(response.data?.user);
        }
      } else {
        debugPrint(
          '🔴 OTPVerificationScreen: OTP verification failed: ${response.message}',
        );
        if (!mounted) return;
        AuthService.showErrorDialog(context, response.message);
      }
    } on ApiException catch (e) {
      debugPrint(
        '🔴 OTPVerificationScreen: ApiException during verification: ${e.message}',
      );
      if (!mounted) return;
      AuthService.showErrorDialog(context, e.message);
    } catch (e) {
      debugPrint(
        '🔴 OTPVerificationScreen: General exception during verification: $e',
      );
      if (!mounted) return;
      AuthService.showErrorDialog(context, ErrorMessages.unknownError);
    } finally {
      if (mounted) {
        debugPrint('🟡 OTPVerificationScreen: Setting isLoading to false');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Success dialog for OTP verification (same style as signup)
  void _showVerificationSuccessDialog() {
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
                  Icons.verified,
                  color: Colors.green.shade600,
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Phone Verified Successfully!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Your phone number has been verified successfully. Please log in to continue.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(this.context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to Login',
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

  // Success dialog for login (similar style)
  void _showLoginSuccessDialog(User? user) {
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
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.login, color: Colors.blue.shade600, size: 60),
              ),
              const SizedBox(height: 16),
              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'You have successfully logged in${user != null ? ' as ${user.firstName}' : ''}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                  widget.onVerificationSuccess(user); // Pass user data
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
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

  String _getFormattedPhoneNumber() {
    final phone = widget.phoneNumber;
    if (phone.length > 4) {
      return '******${phone.substring(phone.length - 4)}';
    }
    return phone;
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    debugPrint('🟡 OTPVerificationScreen: dispose() called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🟡 OTPVerificationScreen: build() called');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            debugPrint('🟡 OTPVerificationScreen: Back button pressed');
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      widget.isSignupFlow ? 'Verify your phone' : 'Enter OTP',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      widget.isSignupFlow
                          ? 'We sent a 6-digit code to ${_getFormattedPhoneNumber()}. Enter it below to verify your phone.'
                          : 'Enter the 6-digit code sent to ${_getFormattedPhoneNumber()}',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                    const SizedBox(height: 40),

                    // OTP Input Fields
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final computed =
                            (constraints.maxWidth - (spacing * 5)) / 6;
                        final boxWidth = computed.clamp(40.0, 48.0);

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: boxWidth,
                              height: 60,
                              child: TextField(
                                controller: _otpControllers[index],
                                focusNode: _otpFocusNodes[index],
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFF),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.4,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade400,
                                      width: 1.4,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppConstants.primaryColor,
                                      width: 2.2,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  // Keep only one digit in each box.
                                  if (value.length > 1) {
                                    _otpControllers[index].text = value
                                        .substring(value.length - 1);
                                    _otpControllers[index].selection =
                                        const TextSelection.collapsed(
                                          offset: 1,
                                        );
                                  }

                                  debugPrint(
                                    '🟡 OTPVerificationScreen: OTP field $index changed to: "$value"',
                                  );
                                  if (_otpControllers[index].text.isNotEmpty &&
                                      index < 5) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_otpFocusNodes[index + 1]);
                                  }
                                  if (_otpControllers[index].text.isEmpty &&
                                      index > 0) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(_otpFocusNodes[index - 1]);
                                  }
                                },
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Timer/Resend Button
                    Center(
                      child: _isTimerActive
                          ? Text(
                              'Resend OTP in 00:${_timerDuration.inSeconds.toString().padLeft(2, '0')}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            )
                          : _isResending
                          ? const CircularProgressIndicator()
                          : GestureDetector(
                              onTap: _resendOTP,
                              child: const Text(
                                'Resend OTP',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Verify Button
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
                              onPressed: _verifyOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Text(
                                widget.isSignupFlow
                                    ? 'Verify & Continue'
                                    : 'Verify & Login',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Help text
                    Center(
                      child: TextButton(
                        onPressed: () {
                          debugPrint(
                            '🟡 OTPVerificationScreen: Help button pressed',
                          );
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Need help?'),
                              content: const Text(
                                'If you didn\'t receive the OTP, try the following:\n\n1. Check your phone number\n2. Wait for 60 seconds to resend\n3. Check your SMS inbox\n4. Ensure you have network coverage',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    debugPrint(
                                      '🟡 OTPVerificationScreen: Help dialog closed',
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                        child: const Text(
                          'Didn\'t receive the code?',
                          style: TextStyle(
                            color: AppConstants.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
