class Validators {
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove all non-digit characters except +
    final cleaned = value.replaceAll(RegExp(r'[^\d+]'), '');

    // Check if it starts with + and has country code
    if (value.startsWith('+')) {
      if (cleaned.length < 10 || cleaned.length > 15) {
        return 'Please enter a valid phone number';
      }
    } else {
      // For local numbers without country code
      if (cleaned.length < 10 || cleaned.length > 12) {
        return 'Please enter a valid phone number';
      }
    }

    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email address';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter OTP';
    }
    if (value.length != 6) {
      return 'OTP must be 6 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'OTP must contain only numbers';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (phone.startsWith('+')) {
      return cleaned.length >= 10 && cleaned.length <= 15;
    } else {
      return cleaned.length >= 10 && cleaned.length <= 12;
    }
  }

  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
