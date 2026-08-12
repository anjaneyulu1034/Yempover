// 4-digit Deal PIN entry — a 4-box variant of the 6-box OTP input pattern
// in OTPVerificationScreen.dart (auto-advance forward on digit entry,
// auto-back on backspace-from-empty).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yempover_app/constants/api_constants.dart';

class DealPinInput extends StatefulWidget {
  final ValueChanged<String> onChanged;
  final bool hasError;
  final bool enabled;

  const DealPinInput({
    super.key,
    required this.onChanged,
    this.hasError = false,
    this.enabled = true,
  });

  @override
  State<DealPinInput> createState() => DealPinInputState();
}

class DealPinInputState extends State<DealPinInput> {
  final List<TextEditingController> _controllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  String get pin => _controllers.map((c) => c.text).join();

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    if (mounted) {
      FocusScope.of(context).requestFocus(_focusNodes[0]);
    }
    widget.onChanged('');
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }

    if (_controllers[index].text.isNotEmpty && index < 3) {
      FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
    }
    if (_controllers[index].text.isEmpty && index > 0) {
      FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }

    widget.onChanged(pin);
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = widget.hasError
        ? Colors.red.shade400
        : Colors.grey.shade400;
    final focusedBorderColor = widget.hasError
        ? Colors.red.shade400
        : AppConstants.primaryColor;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: SizedBox(
            width: 52,
            height: 60,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              enabled: widget.enabled,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor, width: 1.4),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: borderColor, width: 1.4),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: focusedBorderColor, width: 2.2),
                ),
              ),
              onChanged: (value) => _handleChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
