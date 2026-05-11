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
  static const String mePrivacy = '$baseUrl/me/privacy';
  static const String mePushToken = '$baseUrl/me/push-token';
  static const String logout = '$baseUrl/auth/logout'; // Add this line

  // Favorites
  static const String favorites = '$baseUrl/me/favorites';

  // Hidden posts
  static const String hiddenPosts = '$baseUrl/me/hidden-posts';

  // Reports
  static const String reports = '$baseUrl/reports';

  // Subscription endpoints
  static const String subscriptionPlans = '$baseUrl/subscription-plans';
  static const String currentSubscription = '$baseUrl/me/subscription';
  static const String subscribe = '$baseUrl/me/subscribe';

  // Coin endpoints
  static const String coinPackages = '$baseUrl/coins/packages';
  static const String coinWallet = '$baseUrl/me/coins/wallet';
  static const String coinTransactions = '$baseUrl/me/coins/transactions';
  static const String coinPurchase = '$baseUrl/me/coins/purchase';

  // Trade Chat endpoints
  static const String tradeChats = '$baseUrl/trade-chat/all';
  static String tradeChatDetail(String id) => '$baseUrl/trade-chat/$id';
  static String tradeChatMessages(String id) =>
      '$baseUrl/trade-chat/$id/message';
  static String tradeChatUploadImage(String id) =>
      '$baseUrl/trade-chat/$id/upload-image';
  static String tradeChatOffer(String id) => '$baseUrl/trade-chat/$id/offer';
  static String tradeChatMarkRead(String id) =>
      '$baseUrl/trade-chat/$id/messages/read';
  static String tradeChatComplete(String id) =>
      '$baseUrl/trade-chat/$id/complete';
  static String tradeChatCancel(String id) => '$baseUrl/trade-chat/$id/cancel';
  static String tradeChatArchive(String id) =>
      '$baseUrl/trade-chat/$id/archive';
  static String tradeChatBlockUser(String id) =>
      '$baseUrl/trade-chat/$id/block-user';
  static String tradeChatDealCompleted(String id) =>
      '$baseUrl/trade-chat/$id/deal-completed';
  static const String tradeChatBlockedUsers =
      '$baseUrl/trade-chat/blocked-users';
  static String tradeChatUnblockUser(String blockedUserId) =>
      '$baseUrl/trade-chat/blocked-users/$blockedUserId';

  // Inbox/Outbox endpoints
  static const String tradeChatInbox = '$baseUrl/trade-chat/inbox';
  static const String tradeChatOutbox = '$baseUrl/trade-chat/outbox';

  // Offer actions - FIXED ENDPOINTS
  static String acceptOffer(String chatId, String offerId) =>
      '$baseUrl/trade-chat/$chatId/offer/accept?offerId=$offerId';
  static String rejectOffer(String chatId, String offerId) =>
      '$baseUrl/trade-chat/$chatId/offer/reject?offerId=$offerId';
  static String counterOffer(String chatId, String offerId) =>
      '$baseUrl/trade-chat/$chatId/counteroffer?offerId=$offerId';
  static String withdrawOffer(String offerId) =>
      '$baseUrl/trade-chat/offer/$offerId/withdraw';

  // Notification endpoints
  static const String notifications = '$baseUrl/notifications';
  static const String unreadCount = '$baseUrl/notifications/unread-count';
  static String markAsRead(String id) => '$baseUrl/notifications/$id/read';
  static const String readAll = '$baseUrl/notifications/read-all';
  static const String preferences = '$baseUrl/notifications/preferences';
  static String deleteNotification(String id) => '$baseUrl/notifications/$id';
  static const String deleteAll = '$baseUrl/notifications/all';
  static const String batchDelete = '$baseUrl/notifications/batch-delete';

  // Content endpoints
  static const String termsAndConditions = '$baseUrl/content/terms';
  static const String privacyPolicy = '$baseUrl/content/privacy';

  // Helper methods
  static String favoritesWithPagination(int page, int limit) =>
      '$favorites?page=$page&limit=$limit';
  static String favoriteDetail(String id) => '$favorites/$id';
  static String hiddenPostDetail(String id) => '$hiddenPosts/$id';
  static String postDetail(String id) => '$posts/$id';
  static String updatePostStatus(String id) => '$posts/$id/status';
  static const String uploadAvatarBase64 = '$baseUrl/me/avatar/base64';

  static const String userStats = '$baseUrl/me/stats';
  static String otherUserProfile(String id) => '$baseUrl/users/$id';

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}

class AppConstants {
  static const String appName = 'YemPover';
  static const String appTagline = 'Barter System';
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

  static final RegExp phoneRegex = RegExp(r'^\+?\d{10,15}$');

  static final RegExp nameRegex = RegExp(r'^[a-zA-Z ]{2,}$');
  static final RegExp otpRegex = RegExp(r'^\d{6}$');
}
