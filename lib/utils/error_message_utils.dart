import 'dart:convert';

class ErrorMessageUtils {
  static const String _defaultMessage =
      'Something went wrong. Please try again.';

  static bool isSessionExpired(Object? error) {
    final raw = error?.toString().toLowerCase() ?? '';
    if (raw.contains('session expired') || raw.contains('login again')) {
      return true;
    }

    // Treat generic unauthorized as session expiry only when it is not
    // an auth business error such as unregistered phone or invalid otp.
    if (raw.contains('unauthorized')) {
      final isAuthBusinessError =
          raw.contains('not registered') ||
          raw.contains('register first') ||
          raw.contains('user not found') ||
          raw.contains('invalid otp') ||
          raw.contains('expired otp');
      return !isAuthBusinessError;
    }

    return false;
  }

  static String sanitize(Object? error, {String? fallback}) {
    final safeFallback = fallback ?? _defaultMessage;
    if (error == null) return safeFallback;

    String message = error.toString().trim();
    if (message.isEmpty) return safeFallback;

    message = message.replaceFirst('Exception: ', '').trim();
    message = message.replaceFirst('ApiException: ', '').trim();
    message = message.replaceFirst('Error: ', '').trim();

    final extractedFromJson = _extractMessageFromJson(message);
    if (extractedFromJson != null && extractedFromJson.isNotEmpty) {
      message = extractedFromJson;
    }

    message = message.replaceAll(
      RegExp(r'^Failed to [^:]+:\s*\d+\s*-\s*', caseSensitive: false),
      '',
    );
    message = message.replaceAll(
      RegExp(r'^failed to [^:]+:\s*', caseSensitive: false),
      '',
    );
    message = message.replaceAll(RegExp(r'^(Error|Exception):\s*'), '');
    message = message.replaceAll(
      RegExp(r'\s*\(status\s*code\s*[:=]\s*\d+\)\s*', caseSensitive: false),
      '',
    );
    message = message.replaceAll(
      RegExp(r'\bstatus\s*[:=]\s*\d+\b', caseSensitive: false),
      '',
    );
    message = message.replaceAll(RegExp(r'\s+at\s+.+$'), '');
    message = message.trim();

    final lower = message.toLowerCase();
    if (lower.contains('user not found') ||
        lower.contains('register first') ||
        lower.contains('not registered') ||
        lower.contains('no account')) {
      return 'This mobile number is not registered. Please sign up first.';
    }
    if (lower.contains('subscription expired') ||
        lower.contains('subscription inactive')) {
      return 'Your subscription has expired. Please renew to continue.';
    }
    if (lower.contains('socketconnection') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception')) {
      return 'Network issue. Please check your internet connection and try again.';
    }
    if (lower.contains('session expired') || lower.contains('please login')) {
      return 'Session expired. Please login again.';
    }
    if (lower.contains('network') ||
        lower.contains('socketexception') ||
        lower.contains('timed out')) {
      return 'Network issue. Please check your internet connection and try again.';
    }
    if (lower.contains('not found')) {
      return 'Requested information was not found. Please refresh and try again.';
    }
    if (lower.contains('validation') || lower.contains('invalid')) {
      return 'This mobile number is not registered. Please sign up first.';
    }
    if (lower.contains('internal server error') ||
        lower.contains('unexpected token') ||
        lower.contains('json')) {
      return 'Server encountered an issue. Please try again shortly.';
    }
    if (lower.contains("type 'null' is not a subtype") ||
        lower.contains('type cast') ||
        lower.contains('nosuchmethoderror')) {
      return 'Some profile information is temporarily unavailable. Please retry.';
    }

    // Strip transport-level details if they slipped through.
    message = message.replaceAll(
      RegExp(r'uri\s*[:=]\s*https?://[^\s,]+', caseSensitive: false),
      '',
    );
    message = message.replaceAll(
      RegExp(r'address\s*[:=]\s*[^,]+', caseSensitive: false),
      '',
    );
    message = message.replaceAll(
      RegExp(r'port\s*[:=]\s*\d+', caseSensitive: false),
      '',
    );
    message = message.replaceAll(
      RegExp(r'errno\s*[:=]\s*\d+', caseSensitive: false),
      '',
    );
    message = message.replaceAll(RegExp(r'\s+,\s+'), ', ');
    message = message.trim();

    if (message.isEmpty || message == 'null') return safeFallback;
    return message;
  }

  static String? _extractMessageFromJson(String text) {
    try {
      final direct = jsonDecode(text);
      if (direct is Map<String, dynamic>) {
        final message = direct['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {}

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end <= start) return null;

    try {
      final nested = jsonDecode(text.substring(start, end + 1));
      if (nested is Map<String, dynamic>) {
        final message = nested['message']?.toString().trim();
        if (message != null && message.isNotEmpty) return message;
      }
    } catch (_) {}

    return null;
  }
}
