import 'dart:ui';

class ApiConstants {
  static const String baseUrl = 'http://3.208.20.90:3000/api/mobile';

  // Auth Endpoints
  static const String register = '$baseUrl/auth/register';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String posts = '$baseUrl/posts';
  static const String myPosts = '$baseUrl/me/posts';
  static const String products = '$baseUrl/me/posts/products';
  static const String services = '$baseUrl/me/posts/services';
  static const String categories = '$baseUrl/categories';
  static const String me = '$baseUrl/me';
  static const String favorites = '$baseUrl/me/favorites';

  // Subscription endpoints
  static const String subscriptionPlans =
      '$baseUrl/subscription-plans'; // Changed back to original
  static const String currentSubscription =
      '$baseUrl/subscription/current'; // Try with /current

  static String favoritesWithPagination(int page, int limit) =>
      '$favorites?page=$page&limit=$limit';

  static String postDetail(String id) => '$posts/$id';
  static String updatePostStatus(String id) => '$posts/$id/status';

  static const String termsAndConditions = '$baseUrl/content/terms';
  static const String privacyPolicy = '$baseUrl/content/privacy';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class AppConstants {
  static const String appName = 'Yempover';
  static const String appTagline = 'Battery Systems';
  static const int defaultPageSize = 10;
  static const double defaultRadius = 10.0;
  static const double minRadius = 1.0;
  static const double maxRadius = 50.0;

  static const Color primaryColor = Color(0xFF2E5BFF);
  static const Color secondaryColor = Color(0xFF34A853);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFFBBC05);
  static const Color successColor = Color(0xFF4CAF50);
}

class ErrorMessages {
  static const String networkError =
      'Network error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String timeoutError = 'Request timeout. Please try again.';
  static const String unknownError = 'Something went wrong. Please try again.';

  static const String invalidPhoneNumber = 'Please enter a valid phone number';
  static const String invalidEmail = 'Please enter a valid email address';
  static const String invalidName = 'Please enter your full name';
  static const String invalidOtp = 'Please enter a valid 6-digit OTP';

  static const String emptyField = 'This field cannot be empty';
  static const String termsNotAgreed = 'Please agree to the Terms & Conditions';
}

class ValidationRegex {
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');

  static final RegExp nameRegex = RegExp(r'^[a-zA-Z ]{2,}$');
  static final RegExp otpRegex = RegExp(r'^\d{6}$');
}
