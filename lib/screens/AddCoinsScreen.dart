import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:yempover_app/services/coin_service.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:yempover_app/utils/validators.dart';
import 'package:yempover_app/widgets/app_text_field.dart';
import 'package:yempover_app/widgets/coin_icon.dart';

class AddCoinsResult {
  final Map<String, dynamic> transaction;

  const AddCoinsResult({required this.transaction});
}

class _CoinPackage {
  final String name;
  final int coinAmount;

  const _CoinPackage({required this.name, required this.coinAmount});

  factory _CoinPackage.fromMap(Map<String, dynamic> map) {
    return _CoinPackage(
      name: map['name']?.toString() ?? 'Coin Pack',
      coinAmount: CoinService.parseCoinAmount(map['coinAmount']),
    );
  }
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
  static const Color _coinsFieldFill = Color(0xFFFFFBEB);
  static const Color _descriptionFieldFill = Color(0xFFF5F7FF);

  final CoinService _coinService = CoinService();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<_CoinPackage> _packages = [];
  bool _packagesLoading = true;
  String? _packagesError;

  String? _amountError;
  String? _descriptionError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _resolveCountryCode() {
    final localeCode =
        ui.PlatformDispatcher.instance.locale.countryCode?.toUpperCase();
    if (localeCode != null && localeCode.length == 2) {
      return localeCode;
    }
    return 'IN';
  }

  Future<void> _loadPackages() async {
    setState(() {
      _packagesLoading = true;
      _packagesError = null;
    });

    try {
      final raw = await _coinService.getPackages(
        countryCode: _resolveCountryCode(),
      );
      if (!mounted) return;
      setState(() {
        _packages = raw
            .map(_CoinPackage.fromMap)
            .where((p) => p.coinAmount > 0)
            .toList();
        _packagesLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _packagesLoading = false;
        _packagesError = CoinService.friendlyNetworkMessage(e);
      });
    }
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    String? errorText,
    Widget? prefixIcon,
    BoxConstraints? prefixIconConstraints,
    Color? fillColor,
    bool alignLabelWithHint = false,
  }) {
    return AppInputDecoration.build(
      label: label,
      hint: hint,
      errorText: errorText,
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      fillColor: fillColor ?? Colors.grey.shade100,
      alignLabelWithHint: alignLabelWithHint,
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
    } else if (amountText.length > Validators.maxAmountLength) {
      amountError = 'Coins amount is too large';
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
            _buildPackagesSection(),
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
                    inputFormatters: Validators.amountInputFormatters(
                      allowDecimal: false,
                    ),
                    onChanged: (_) {
                      if (_amountError != null) {
                        setState(() => _amountError = null);
                      }
                    },
                    decoration: _fieldDecoration(
                      label: 'Add Coins',
                      errorText: _amountError,
                      prefixIcon: coinInputPrefix(),
                      prefixIconConstraints: coinPrefixIconConstraints,
                      fillColor: _coinsFieldFill,
                    ),
                  ),
                  const SizedBox(height: 22),
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
                      label: 'Description',
                      hint: 'Add description',
                      errorText: _descriptionError,
                      fillColor: _descriptionFieldFill,
                      alignLabelWithHint: true,
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

  Widget _buildPackagesSection() {
    if (_packagesLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_packagesError != null) {
      return _buildPackagesError();
    }

    if (_packages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: _packages.map(_buildPackageTile).toList(),
    );
  }

  Widget _buildPackageTile(_CoinPackage pack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          const CoinIcon(size: 32, iconSize: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pack.coinAmount} Coin${pack.coinAmount == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                Text(
                  pack.name,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        children: [
          Text(
            _packagesError ?? 'Could not load packages',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _loadPackages,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
