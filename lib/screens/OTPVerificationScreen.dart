// import 'package:flutter/material.dart';

// class OTPVerificationScreen extends StatefulWidget {
//   final String phoneNumber;
//   final VoidCallback onVerificationSuccess;
//   final bool isSignupFlow;

//   const OTPVerificationScreen({
//     super.key,
//     required this.phoneNumber,
//     required this.onVerificationSuccess,
//     this.isSignupFlow = false,
//   });

//   @override
//   State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
// }

// class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
//   final List<TextEditingController> _otpControllers = List.generate(
//     6,
//     (_) => TextEditingController(),
//   );
//   final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
//   Duration _timerDuration = const Duration(seconds: 60);
//   bool _isTimerActive = true;

//   @override
//   void initState() {
//     super.initState();
//     _startTimer();
//   }

//   void _startTimer() {
//     Future.delayed(const Duration(seconds: 1), () {
//       if (_timerDuration.inSeconds > 0) {
//         setState(() {
//           _timerDuration = Duration(seconds: _timerDuration.inSeconds - 1);
//         });
//         _startTimer();
//       } else {
//         setState(() {
//           _isTimerActive = false;
//         });
//       }
//     });
//   }

//   void _resendOTP() {
//     setState(() {
//       _timerDuration = const Duration(seconds: 60);
//       _isTimerActive = true;
//       // Clear all OTP fields
//       for (var controller in _otpControllers) {
//         controller.clear();
//       }
//       // Focus on first field
//       FocusScope.of(context).requestFocus(_otpFocusNodes[0]);
//     });
//     _startTimer();

//     // Show resend confirmation
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('OTP has been resent to your phone number'),
//         backgroundColor: Colors.green,
//       ),
//     );
//   }

//   void _verifyOTP() {
//     // Check if all OTP fields are filled
//     for (var controller in _otpControllers) {
//       if (controller.text.isEmpty) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Please enter the complete OTP'),
//             backgroundColor: Colors.red,
//           ),
//         );
//         return;
//       }
//     }

//     // Simulate API verification
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (_) => const Dialog(
//         child: Padding(
//           padding: EdgeInsets.all(20),
//           child: Row(
//             children: [
//               CircularProgressIndicator(),
//               SizedBox(width: 20),
//               Text('Verifying OTP...'),
//             ],
//           ),
//         ),
//       ),
//     );

//     // Simulate API delay
//     Future.delayed(const Duration(seconds: 2), () {
//       Navigator.pop(context); // Remove loading dialog
//       widget.onVerificationSuccess();
//     });
//   }

//   String _getFormattedPhoneNumber() {
//     final phone = widget.phoneNumber;
//     if (phone.length > 4) {
//       return '******${phone.substring(phone.length - 4)}';
//     }
//     return phone;
//   }

//   @override
//   void dispose() {
//     for (var controller in _otpControllers) {
//       controller.dispose();
//     }
//     for (var focusNode in _otpFocusNodes) {
//       focusNode.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Title
//               Text(
//                 widget.isSignupFlow ? 'Verify your phone' : 'Enter OTP',
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 8),

//               // Description
//               Text(
//                 widget.isSignupFlow
//                     ? 'We sent a 6-digit code to ${_getFormattedPhoneNumber()}. Enter it below to verify your phone.'
//                     : 'Enter the 6-digit code sent to ${_getFormattedPhoneNumber()}',
//                 style: const TextStyle(fontSize: 16, color: Colors.grey),
//               ),

//               const SizedBox(height: 40),

//               // OTP Input Fields
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: List.generate(6, (index) {
//                   return SizedBox(
//                     width: 48,
//                     height: 48,
//                     child: TextField(
//                       controller: _otpControllers[index],
//                       focusNode: _otpFocusNodes[index],
//                       textAlign: TextAlign.center,
//                       maxLength: 1,
//                       keyboardType: TextInputType.number,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       decoration: InputDecoration(
//                         counterText: '',
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: Colors.grey.shade300),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(
//                             color: Color(0xFF1A73E8),
//                             width: 2,
//                           ),
//                         ),
//                       ),
//                       onChanged: (value) {
//                         if (value.isNotEmpty && index < 5) {
//                           FocusScope.of(
//                             context,
//                           ).requestFocus(_otpFocusNodes[index + 1]);
//                         }
//                         if (value.isEmpty && index > 0) {
//                           FocusScope.of(
//                             context,
//                           ).requestFocus(_otpFocusNodes[index - 1]);
//                         }
//                       },
//                     ),
//                   );
//                 }),
//               ),

//               const SizedBox(height: 32),

//               // Timer
//               Center(
//                 child: _isTimerActive
//                     ? Text(
//                         'Resend OTP in 00:${_timerDuration.inSeconds.toString().padLeft(2, '0')}',
//                         style: const TextStyle(
//                           fontSize: 16,
//                           color: Colors.grey,
//                         ),
//                       )
//                     : GestureDetector(
//                         onTap: _resendOTP,
//                         child: const Text(
//                           'Resend OTP',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Color(0xFF1A73E8),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//               ),

//               const SizedBox(height: 24),

//               // Verify Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: ElevatedButton(
//                   onPressed: _verifyOTP,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: const Color(0xFF1A73E8),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(28),
//                     ),
//                   ),
//                   child: Text(
//                     widget.isSignupFlow
//                         ? 'Verify & Continue'
//                         : 'Verify & Login',
//                     style: const TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),

//               const Spacer(),

//               // Help text
//               Center(
//                 child: TextButton(
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       builder: (_) => AlertDialog(
//                         title: const Text('Need help?'),
//                         content: const Text(
//                           'If you didn\'t receive the OTP, try the following:\n\n1. Check your phone number\n2. Wait for 60 seconds to resend\n3. Check your SMS inbox\n4. Ensure you have network coverage',
//                         ),
//                         actions: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: const Text('OK'),
//                           ),
//                         ],
//                       ),
//                     );
//                   },
//                   child: const Text(
//                     'Didn\'t receive the code?',
//                     style: TextStyle(
//                       color: Color(0xFF1A73E8),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yempower_app/constants/api_constants.dart';
import 'package:yempower_app/models/auth_models.dart';
import 'package:yempower_app/services/auth_service.dart';
import 'package:yempower_app/utils/validators.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final Function(AuthResponse) onVerificationSuccess;
  final bool isSignupFlow;
  final String? devOtp;

  const OTPVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.onVerificationSuccess,
    this.isSignupFlow = false,
    this.devOtp,
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
  final AuthService _authService = AuthService();

  Duration _timerDuration = AppConstants.otpResendDuration;
  bool _isTimerActive = true;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _devOtp;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _devOtp = widget.devOtp;
    _startTimer();
    // Auto-fill dev OTP if available
    if (_devOtp != null && _devOtp!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < 6; i++) {
          _otpControllers[i].text = _devOtp![i];
        }
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerDuration.inSeconds > 0) {
        setState(() {
          _timerDuration = Duration(seconds: _timerDuration.inSeconds - 1);
        });
      } else {
        setState(() {
          _isTimerActive = false;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendOTP() async {
    if (_isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final otpResponse = await _authService.resendOtp(widget.phoneNumber);

      if (otpResponse.success) {
        setState(() {
          _timerDuration = AppConstants.otpResendDuration;
          _isTimerActive = true;
          _devOtp = otpResponse.devMode ? otpResponse.otp : null;
        });

        // Clear all OTP fields
        for (var controller in _otpControllers) {
          controller.clear();
        }

        // Focus on first field
        FocusScope.of(context).requestFocus(_otpFocusNodes[0]);

        // Auto-fill dev OTP if available
        if (_devOtp != null && _devOtp!.length == 6) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            for (int i = 0; i < 6; i++) {
              _otpControllers[i].text = _devOtp![i];
            }
          });
        }

        // Restart timer
        _timer?.cancel();
        _startTimer();

        // Show resend confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(otpResponse.message),
            backgroundColor: AppConstants.secondaryColor,
            duration: const Duration(seconds: 2),
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
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    // Check if all OTP fields are filled
    final otp = _getOtpFromControllers();
    final validationError = Validators.validateOtp(otp);

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      AuthResponse authResponse;

      if (widget.isSignupFlow) {
        authResponse = await _authService.verifySignupOtp(
          phone: widget.phoneNumber,
          otp: otp,
        );
      } else {
        authResponse = await _authService.verifyLoginOtp(
          phone: widget.phoneNumber,
          otp: otp,
        );
      }

      // Clear OTP phone from storage
      await _authService.clearOtpPhone();

      // Call success callback with auth response
      widget.onVerificationSuccess(authResponse);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  String _getOtpFromControllers() {
    return _otpControllers.map((c) => c.text).join();
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
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.isSignupFlow ? 'Verify your phone' : 'Enter OTP',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
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

              // Error Message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(
                      255,
                      214,
                      51,
                      51,
                    ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppConstants.secondaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: AppConstants.secondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 48,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _otpFocusNodes[index],
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      keyboardType: TextInputType.number,
                      enabled: !_isVerifying,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppConstants.primaryColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 5) {
                          FocusScope.of(
                            context,
                          ).requestFocus(_otpFocusNodes[index + 1]);
                        }
                        if (value.isEmpty && index > 0) {
                          FocusScope.of(
                            context,
                          ).requestFocus(_otpFocusNodes[index - 1]);
                        }

                        // Auto-verify if all fields filled
                        if (index == 5 && value.isNotEmpty) {
                          final otp = _getOtpFromControllers();
                          if (otp.length == 6) {
                            // Small delay to allow last character to be set
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                _verifyOTP();
                              },
                            );
                          }
                        }
                      },
                    ),
                  );
                }),
              ),

              const SizedBox(height: 32),

              // Timer and Resend
              Center(
                child: _isTimerActive
                    ? Text(
                        'Resend OTP in 00:${_timerDuration.inSeconds.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppConstants.greyColor,
                        ),
                      )
                    : GestureDetector(
                        onTap: _isResending ? null : _resendOTP,
                        child: _isResending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppConstants.primaryColor,
                                ),
                              )
                            : Text(
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
                child: _isVerifying
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),

              const Spacer(),

              // Dev mode info
              if (_devOtp != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Dev Mode OTP: $_devOtp',
                      style: TextStyle(
                        color: AppConstants.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

              if (_devOtp != null) const SizedBox(height: 16),

              // Help text
              Center(
                child: TextButton(
                  onPressed: _isVerifying
                      ? null
                      : () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Need help?'),
                              content: const Text(
                                'If you didn\'t receive the OTP, try the following:\n\n1. Check your phone number\n2. Wait for 60 seconds to resend\n3. Check your SMS inbox\n4. Ensure you have network coverage',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        },
                  child: Text(
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
      ),
    );
  }
}
