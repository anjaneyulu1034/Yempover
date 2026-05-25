import 'package:flutter/material.dart';
import 'package:YemPover_app/screens/AddCoinsScreen.dart';
import 'package:YemPover_app/services/coin_service.dart';
import 'package:YemPover_app/widgets/coin_icon.dart';

/// Ensures the user has enough wallet coins before a priced offer.
class WalletOfferGuard {
  WalletOfferGuard._();

  static int _requiredCoinsFromAmount(num amount) {
    if (amount is int) return amount;
    if (amount is double) return amount.round();
    return int.tryParse(amount.toString().trim()) ?? 0;
  }

  /// Returns true when balance is sufficient (or [requiredCoins] is 0).
  /// Otherwise shows a dialog and optionally navigates to [CoinsWalletScreen].
  static Future<bool> ensureCanAfford(
    BuildContext context, {
    required num requiredCoins,
    String? itemName,
  }) async {
    final required = _requiredCoinsFromAmount(requiredCoins);
    if (required <= 0) return true;

    final coinService = CoinService();
    int balance = 0;

    try {
      final wallet = await coinService.getWallet();
      balance = CoinService.parseCoinAmount(wallet?['balance']);
    } catch (_) {
      if (!context.mounted) return false;
      await _showInsufficientDialog(
        context,
        required: required,
        balance: balance,
        itemName: itemName,
      );
      return false;
    }

    if (balance >= required) return true;
    if (!context.mounted) return false;

    final addCoins = await _showInsufficientDialog(
      context,
      required: required,
      balance: balance,
      itemName: itemName,
    );

    if (addCoins != true || !context.mounted) return false;

    await Navigator.of(context).push<AddCoinsResult>(
      MaterialPageRoute(builder: (_) => const AddCoinsScreen()),
    );

    if (!context.mounted) return false;

    try {
      final wallet = await coinService.getWallet();
      balance = CoinService.parseCoinAmount(wallet?['balance']);
      return balance >= required;
    } catch (_) {
      return false;
    }
  }

  static Future<bool?> _showInsufficientDialog(
    BuildContext context, {
    required int required,
    required int balance,
    String? itemName,
  }) {
    const primary = Color(0xFF6549E8);
    const titleColor = Color(0xFF111827);
    const bodyColor = Color(0xFF6B7280);
    const borderColor = Color(0xFFD1D5DB);
    final shortfall = (required - balance).clamp(0, required);

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CoinIcon(size: 28, iconSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Insufficient coins',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                itemName != null && itemName.isNotEmpty
                    ? 'You need more coins to make an offer on "$itemName".'
                    : 'You need more coins in your wallet to make this offer.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Colors.black.withValues(alpha: 0.68),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8FB),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEDEDF2)),
                ),
                child: Column(
                  children: [
                    _coinBalanceRow(
                      label: 'Required',
                      amount: required,
                      valueColor: titleColor,
                    ),
                    const SizedBox(height: 10),
                    _coinBalanceRow(
                      label: 'Your balance',
                      amount: balance,
                      valueColor: const Color(0xFFDC2626),
                    ),
                    if (shortfall > 0) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                      ),
                      _coinBalanceRow(
                        label: 'Short by',
                        amount: shortfall,
                        valueColor: const Color(0xFFB45309),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Add coins to continue with your offer.',
                style: TextStyle(fontSize: 13, height: 1.35, color: bodyColor),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: const Color(0xFF374151),
                        side: const BorderSide(color: borderColor, width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Add Coins',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _coinBalanceRow({
    required String label,
    required int amount,
    required Color valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        CoinPriceLabel(
          text: '${CoinFormat.amount(amount)} coins',
          iconSize: 18,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
