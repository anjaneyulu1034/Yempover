class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String photo;
  final bool acceptedTerms; // ✅ NEW

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    required this.photo,
    required this.acceptedTerms, // ✅ NEW
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobileNumber': mobileNumber,
      'photo': photo,
      'acceptedTerms': acceptedTerms, // ✅ NEW
    };
  }
}

class SendOtpRequest {
  final String mobileNumber;

  SendOtpRequest({required this.mobileNumber});

  Map<String, dynamic> toJson() {
    return {'mobileNumber': mobileNumber};
  }
}

class VerifyOtpRequest {
  final String mobileNumber;
  final String otp;
  final String? photo;

  VerifyOtpRequest({
    required this.mobileNumber,
    required this.otp,
    this.photo,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobileNumber': mobileNumber,
      'otp': otp,
      if (photo != null) 'photo': photo,
    };
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String mobileNumber;
  final String? profileImage;
  final bool verificationPending;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.mobileNumber,
    this.profileImage,
    this.verificationPending = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      mobileNumber: json['mobileNumber'] ?? '',
      profileImage: json['profileImage'],
      verificationPending: json['verificationPending'] == true,
    );
  }

  String get fullName => '$firstName $lastName';
}

class AuthResponse<T> {
  final String status;
  final String message;
  final T? data;
  final bool _isSuccess;

  AuthResponse({
    required this.status,
    required this.message,
    this.data,
    required bool isSuccess,
  }) : _isSuccess = isSuccess;

  factory AuthResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final rawStatus = json['status'];
    final normalizedStatus = rawStatus?.toString() ?? '';
    final lowerStatus = normalizedStatus.toLowerCase();
    final computedIsSuccess =
        json['isSuccess'] == true ||
        json['success'] == true ||
        rawStatus == true ||
        lowerStatus == 'success' ||
        lowerStatus == 'true' ||
        lowerStatus == 'ok';

    return AuthResponse(
      status: normalizedStatus,
      message: json['message'] ?? '',
      data: json['data'] == null
          ? null
          : fromJson != null
          ? fromJson(json['data'])
          : json['data'] as T,
      isSuccess: computedIsSuccess,
    );
  }

  bool get isSuccess => _isSuccess;
}

class RegisterResponseData {
  final User user;

  RegisterResponseData({required this.user});

  factory RegisterResponseData.fromJson(Map<String, dynamic> json) {
    return RegisterResponseData(user: User.fromJson(json['user']));
  }
}

class SendOtpResponseData {
  final bool success;
  final String message;

  SendOtpResponseData({required this.success, required this.message});

  factory SendOtpResponseData.fromJson(Map<String, dynamic> json) {
    return SendOtpResponseData(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class VerifyOtpResponseData {
  final User user;
  final String token;
  final String refreshToken;

  VerifyOtpResponseData({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory VerifyOtpResponseData.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponseData(
      user: User.fromJson(json['user']),
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? '',
    );
  }
}
