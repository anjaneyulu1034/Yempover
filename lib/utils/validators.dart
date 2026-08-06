// core/utils/validators.dart
import 'package:flutter/services.dart';

class Validators {
  // Matches the digit-count cap already used for offer prices — keeps every
  // amount/price field in the app bounded to the same sane range instead of
  // accepting arbitrarily long numbers.
  static const int maxAmountLength = 9;

  /// Formatters for money/amount fields (price, offer amount, coin top-up,
  /// etc.): digits only (plus up to 2 decimal places when [allowDecimal]),
  /// capped at [maxAmountLength] characters, with leading zeros collapsed so
  /// a field can never fill up with "000000".
  static List<TextInputFormatter> amountInputFormatters({
    bool allowDecimal = true,
  }) {
    return [
      _BoundedNumberFormatter(decimalPlaces: allowDecimal ? 2 : 0),
      LengthLimitingTextInputFormatter(maxAmountLength),
    ];
  }

  /// Formatters for a counter field with a known ceiling — e.g. the "Post
  /// Expiry" value paired with a Minutes/Hours/Days/Months/Years dropdown.
  /// Rejects any edit that would push the value past [max], so the field is
  /// naturally capped without a separate, easy-to-mismatch character-length
  /// limit, and collapses leading zeros the same way [amountInputFormatters]
  /// does. Whole-number fields (`allowDecimal: false`) also refuse to sit at
  /// a bare "0", since that's never a valid final value for them.
  static List<TextInputFormatter> boundedCounterFormatters({
    required int max,
    bool allowDecimal = false,
  }) {
    return [
      _BoundedNumberFormatter(
        max: max.toDouble(),
        decimalPlaces: allowDecimal ? 1 : 0,
      ),
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

/// Strips leading zeros (so a field can't fill up with "000000"), and, when
/// [max] is set, rejects any edit that would leave the field showing a
/// number greater than it. A bare "0" is never accepted as a value in any
/// field this formats — zero minutes, zero years, zero coins, etc. are never
/// meaningful — so the keystroke that would leave the field sitting at "0"
/// is swallowed outright. Fields that allow decimals can still express a
/// fractional value below 1 by leading with the decimal point (typing "."
/// then "5" yields ".5", which parses the same as "0.5") instead of typing a
/// leading zero.
class _BoundedNumberFormatter extends TextInputFormatter {
  _BoundedNumberFormatter({this.max, this.decimalPlaces = 0});

  final double? max;
  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (text.isEmpty) return newValue;

    final shapePattern = decimalPlaces > 0
        ? RegExp(r'^\d*\.?\d{0,' + decimalPlaces.toString() + r'}$')
        : RegExp(r'^\d*$');
    if (!shapePattern.hasMatch(text)) return oldValue;

    if (text.startsWith('0') && text != '0' && !text.startsWith('0.')) {
      final stripped = text.replaceFirst(RegExp(r'^0+'), '');
      text = stripped.isEmpty
          ? '0'
          : (stripped.startsWith('.') ? '0$stripped' : stripped);
    }

    if (text == '0') {
      // A field left showing a bare "0" is never a valid final value —
      // swallow the keystroke rather than let it sit there looking valid.
      // Fields that allow decimals can still reach "0.5" by starting with
      // "." instead of "0".
      return oldValue;
    }

    if (max != null) {
      final parsed = double.tryParse(text);
      if (parsed != null && parsed > max!) return oldValue;
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
