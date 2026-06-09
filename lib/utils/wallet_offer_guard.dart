import 'package:flutter/material.dart';
import 'package:yempover_app/screens/AddCoinsScreen.dart';
import 'package:yempover_app/services/coin_service.dart';
import 'package:yempover_app/widgets/coin_icon.dart';

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
    final shortfall = (required - balance).clamp(0, required);
    final progress = required <= 0 ? 0.0 : (balance / required).clamp(0.0, 1.0);
    final shortPercent =
        required <= 0 ? 0 : ((shortfall / required) * 100).round().clamp(0, 100);

    const primary = Color(0xFF2E5BFF);
    const titleColor = Color(0xFF111827);
    const bodyColor = Color(0xFF6B7280);
    const borderColor = Color(0xFFE5E7EB);
    const cardBg = Color(0xFFF7F4EA);

    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.52),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF0EAD8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3EEDC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: CoinIcon(size: 26, iconSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Insufficient balance',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.only(left: 56),
                      child: Text(
                        'Top up to continue your offer',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.25,
                          color: bodyColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${CoinFormat.amount(balance)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          ' / ${CoinFormat.amount(required)} coins',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black.withValues(alpha: 0.55),
                            height: 1.2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$shortPercent% short',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB42318),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        backgroundColor: const Color(0xFFE7DFC8),
                        valueColor: const AlwaysStoppedAnimation(Color(0xFF8A7A3A)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      itemName != null && itemName.isNotEmpty
                          ? 'Add ${CoinFormat.amount(shortfall)} coins to make an offer on "$itemName"'
                          : 'Add ${CoinFormat.amount(shortfall)} coins to continue',
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.25,
                        color: bodyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Add ${CoinFormat.amount(shortfall)} coins',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: const Color(0xFF111827),
                    side: const BorderSide(color: borderColor, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Maybe later',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
