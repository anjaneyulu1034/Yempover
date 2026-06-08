import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/widgets/app_text_field.dart';

/// Phone input with a searchable country-code picker (name + dial code).
class PhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final String? hint;
  final String initialCountryCode;
  final ValueChanged<CountryCode>? onCountryChanged;

  const PhoneNumberField({
    super.key,
    required this.controller,
    this.validator,
    this.label = 'Phone Number',
    this.hint,
    this.initialCountryCode = 'US',
    this.onCountryChanged,
  });

  @override
  State<PhoneNumberField> createState() => PhoneNumberFieldState();
}

class PhoneNumberFieldState extends State<PhoneNumberField> {
  CountryCode _selectedCountry = CountryCode.fromCountryCode('US');

  @override
  void initState() {
    super.initState();
    _selectedCountry = CountryCode.fromCountryCode(widget.initialCountryCode);
  }

  /// Full E.164-style number with leading + for API calls.
  String get fullPhoneNumber {
    final dialDigits = (_selectedCountry.dialCode ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    final localDigits = widget.controller.text.replaceAll(RegExp(r'\D'), '');
    return '+$dialDigits$localDigits';
  }

  CountryCode get selectedCountry => _selectedCountry;

  String _dialCodeDigits(CountryCode? country) {
    final dialCode = country?.dialCode ?? '+1';
    return dialCode.replaceAll(RegExp(r'\D'), '');
  }

  static const TextStyle _dialCodeStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static String? validateLocalNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.emptyField;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 6) {
      return 'Phone number is too short';
    }
    if (digits.length > 12) {
      return 'Phone number is too long';
    }
    return null;
  }

  static String? validateFullNumber(String fullDigits) {
    if (!ValidationRegex.phoneRegex.hasMatch(fullDigits)) {
      return ErrorMessages.invalidPhoneNumber;
    }
    return null;
  }

  String? _validate(String? value) {
    final localError = widget.validator?.call(value) ??
        PhoneNumberFieldState.validateLocalNumber(value);
    if (localError != null) return localError;
    return PhoneNumberFieldState.validateFullNumber(fullPhoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: TextInputType.phone,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: _validate,
      decoration: AppInputDecoration.build(
        label: widget.label,
        hint: widget.hint ?? 'Enter phone number',
        prefixIcon: CountryCodePicker(
          onChanged: (country) {
            setState(() => _selectedCountry = country);
            widget.onCountryChanged?.call(country);
          },
          initialSelection: widget.initialCountryCode,
          favorite: const ['+1', 'US', '+91', 'IN', '+44', 'GB'],
          showCountryOnly: false,
          showOnlyCountryWhenClosed: false,
          alignLeft: false,
          showFlag: true,
          showDropDownButton: true,
          padding: EdgeInsets.zero,
          textStyle: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          dialogTextStyle: const TextStyle(fontSize: 15),
          searchDecoration: InputDecoration(
            hintText: 'Search country',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          dialogBackgroundColor: Colors.white,
          barrierColor: Colors.black54,
          boxDecoration: const BoxDecoration(),
          builder: (country) {
            return Padding(
              padding: const EdgeInsets.only(left: 12, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (country?.flagUri != null)
                    Image.asset(
                      country!.flagUri!,
                      package: 'country_code_picker',
                      width: 24,
                      height: 18,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(width: 6),
                  const Text('+', style: _dialCodeStyle),
                  Text(
                    _dialCodeDigits(country),
                    style: _dialCodeStyle,
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            );
          },
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
    );
  }
}
