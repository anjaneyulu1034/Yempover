import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:YemPover_app/services/coin_service.dart';
import 'package:YemPover_app/utils/snackbar_utils.dart';
import 'package:YemPover_app/widgets/coin_icon.dart';

class AddCoinsResult {
  final Map<String, dynamic> transaction;

  const AddCoinsResult({required this.transaction});
}

class AddCoinsScreen extends StatefulWidget {
  const AddCoinsScreen({super.key});

  @override
  State<AddCoinsScreen> createState() => _AddCoinsScreenState();
}

class _AddCoinsScreenState extends State<AddCoinsScreen> {
  static const Color _primary = Color(0xFF6549E8);
  static const Color _surfaceBg = Color(0xFFF8F8FB);
  static const Color _labelColor = Color(0xFF374151);
  static const Color _borderColor = Color(0xFFEDEDF2);
  static const Color _coinsFieldBorder = Color(0xFFFFD966);
  static const Color _coinsFieldFill = Color(0xFFFFFBEB);
  static const Color _descriptionFieldBorder = Color(0xFFC7D2FE);
  static const Color _descriptionFieldFill = Color(0xFFF5F7FF);

  final CoinService _coinService = CoinService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _amountError;
  String? _descriptionError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({
    String? hintText,
    String? errorText,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    required Color enabledBorderColor,
    required Color fillColor,
  }) {
    final borderRadius = BorderRadius.circular(12);
    final hasError = errorText != null && errorText.isNotEmpty;

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      filled: true,
      fillColor: fillColor,
      errorText: errorText,
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: hasError ? Colors.red.shade300 : enabledBorderColor,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: hasError ? Colors.red.shade300 : enabledBorderColor,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: hasError ? Colors.red.shade400 : _primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.red.shade500, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  bool _validate() {
    final amountText = _amountController.text.trim();
    final description = _descriptionController.text.trim();

    String? amountError;
    String? descriptionError;

    final amount = int.tryParse(amountText);
    if (amountText.isEmpty) {
      amountError = 'Coins is required';
    } else if (amount == null || amount <= 0) {
      amountError = 'Enter a valid number of coins greater than 0';
    }

    if (description.isEmpty) {
      descriptionError = 'Description is required';
    }

    setState(() {
      _amountError = amountError;
      _descriptionError = descriptionError;
    });

    return amountError == null && descriptionError == null;
  }

  Future<void> _submit() async {
    if (!_validate()) return;

    final amount = int.parse(_amountController.text.trim());
    final description = _descriptionController.text.trim();

    setState(() => _isSubmitting = true);

    try {
      final transaction = await _coinService.addCoins(
        amount: amount,
        description: description,
      );

      if (!mounted) return;

      SnackbarUtils.showSuccess(context, 'Coins added successfully');
      Navigator.pop(context, AddCoinsResult(transaction: transaction));
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        e,
        fallback: 'Failed to add coins. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceBg,
      appBar: AppBar(
        backgroundColor: _surfaceBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: const Color(0xFF111827),
        ),
        title: const Text(
          'Add Coins',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6F51FF), Color(0xFF5341DB)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.monetization_on, color: Color(0xFFFFC62B), size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Top up your barter coins',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Coins',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) {
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                    decoration: _fieldDecoration(
                      hintText: 'Add Coins',
                      errorText: _amountError,
                      prefixIcon: coinInputPrefix(),
                      prefixIconConstraints: coinPrefixIconConstraints,
                      enabledBorderColor: _coinsFieldBorder,
                      fillColor: _coinsFieldFill,
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _labelColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) {
                      if (_descriptionError != null) {
                        setState(() => _descriptionError = null);
                      }
                    },
                    decoration: _fieldDecoration(
                      hintText: 'Add Description',
                      errorText: _descriptionError,
                      enabledBorderColor: _descriptionFieldBorder,
                      fillColor: _descriptionFieldFill,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.notes_outlined, color: _primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Add Coins',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
