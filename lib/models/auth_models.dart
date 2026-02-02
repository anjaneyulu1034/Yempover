import 'dart:convert';

class SignupRequest {
  final String name;
  final String phone;
  final String email;
  final bool termsAccepted;

  SignupRequest({
    required this.name,
    required this.phone,
    required this.email,
    required this.termsAccepted,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'termsAccepted': termsAccepted,
    };
  }
}

class LoginRequest {
  final String phone;

  LoginRequest({required this.phone});

  Map<String, dynamic> toJson() {
    return {'phone': phone};
  }
}

class LoginOtpRequest {
  final String phone;
  final String otp;

  LoginOtpRequest({required this.phone, required this.otp});

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'otp': otp};
  }
}

class OtpRequest {
  final String phone;

  OtpRequest({required this.phone});

  Map<String, dynamic> toJson() {
    return {'phone': phone};
  }
}

class VerifyOtpRequest {
  final String phone;
  final String otp;

  VerifyOtpRequest({required this.phone, required this.otp});

  Map<String, dynamic> toJson() {
    return {'phone': phone, 'otp': otp};
  }
}

class OtpResponse {
  final bool success;
  final String message;
  final String otp;
  final bool devMode;
  final String phoneUsed;

  OtpResponse({
    required this.success,
    required this.message,
    required this.otp,
    required this.devMode,
    required this.phoneUsed,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      otp: json['otp'] ?? '',
      devMode: json['devMode'] ?? false,
      phoneUsed: json['phoneUsed'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'otp': otp,
      'devMode': devMode,
      'phoneUsed': phoneUsed,
    };
  }
}

class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String subscriptionStatus;
  final DateTime subscriptionValidUntil;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subscriptionStatus,
    required this.subscriptionValidUntil,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      subscriptionStatus: json['subscriptionStatus'] ?? 'TRIAL',
      subscriptionValidUntil: DateTime.parse(json['subscriptionValidUntil']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'subscriptionStatus': subscriptionStatus,
      'subscriptionValidUntil': subscriptionValidUntil.toIso8601String(),
    };
  }
}

class AuthResponse {
  final User user;
  final String token;

  AuthResponse({required this.user, required this.token});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user']),
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'user': user.toJson(), 'token': token};
  }
}
