// core/utils/validators.dart
import 'package:flutter/services.dart';

class Validators {
  // Matches the digit-count cap already used for offer prices — keeps every
  // amount/price field in the app bounded to the same sane range instead of
  // accepting arbitrarily long numbers.
  static const int maxAmountLength = 9;

  static List<TextInputFormatter> amountInputFormatters({
    bool allowDecimal = true,
  }) {
    return [
      allowDecimal
          ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
          : FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(maxAmountLength),
    ];
  }

  static String? validateAmount(
    String? value, {
    double min = 0.01,
    String emptyMessage = 'Amount is required',
    String invalidMessage = 'Enter a valid amount',
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return emptyMessage;

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < min) return invalidMessage;
    if (trimmed.length > maxAmountLength) return 'Amount is too large';

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}
