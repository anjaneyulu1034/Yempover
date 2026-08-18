import 'package:yempover_app/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared outlined text fields with floating labels (field name on top border).
class AppInputDecoration {
  AppInputDecoration._();

  static const double radius = 12;
  static const Color primaryColor = AppConstants.primaryColor;

  static OutlineInputBorder outlineBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static InputDecoration build({
    required String label,
    String? hint,
    Widget? prefix,
    Widget? prefixIcon,
    Widget? suffixIcon,
    BoxConstraints? prefixIconConstraints,
    String? prefixText,
    String? errorText,
    String? counterText,
    bool filled = true,
    Color? fillColor,
    EdgeInsetsGeometry? contentPadding,
    bool alignLabelWithHint = false,
    InputBorder? border,
    InputBorder? enabledBorder,
    InputBorder? focusedBorder,
    InputBorder? errorBorder,
    InputBorder? focusedErrorBorder,
  }) {
    final defaultEnabled = outlineBorder(Colors.grey.shade300);
    final defaultFocused = outlineBorder(primaryColor, 1.5);
    final defaultError = outlineBorder(Colors.red);
    final defaultFocusedError = outlineBorder(Colors.red, 1.5);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      counterText: counterText,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      alignLabelWithHint: alignLabelWithHint,
      prefix: prefix,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      prefixIconConstraints: prefixIconConstraints,
      prefixText: prefixText,
      filled: filled,
      fillColor: fillColor ?? Colors.grey.shade100,
      contentPadding:
          contentPadding ??
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border ?? defaultEnabled,
      enabledBorder: enabledBorder ?? defaultEnabled,
      focusedBorder: focusedBorder ?? defaultFocused,
      errorBorder: errorBorder ?? defaultError,
      focusedErrorBorder: focusedErrorBorder ?? defaultFocusedError,
      floatingLabelStyle: const TextStyle(
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
      labelStyle: TextStyle(color: Colors.grey.shade600),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    );
  }
}

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? initialValue;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final Widget? prefix;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;
  final Color? fillColor;
  final bool alignLabelWithHint;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.initialValue,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.prefix,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
    this.fillColor,
    this.alignLabelWithHint = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      keyboardType: keyboardType,
      obscureText: obscureText,
      readOnly: readOnly,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      focusNode: focusNode,
      decoration: AppInputDecoration.build(
        label: label,
        hint: hint,
        prefix: prefix,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        fillColor: fillColor,
        alignLabelWithHint: alignLabelWithHint,
      ),
    );
  }
}
