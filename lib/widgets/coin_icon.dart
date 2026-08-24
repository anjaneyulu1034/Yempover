import 'package:flutter/material.dart';

/// Gold barter-coin badge used across the app (matches wallet UI).
class CoinIcon extends StatelessWidget {
  final double size;
  final double iconSize;
  final bool filled;

  const CoinIcon({
    super.key,
    this.size = 28,
    this.iconSize = 18,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!filled) {
      return Icon(
        Icons.monetization_on,
        color: const Color(0xFFFFC62B),
        size: size,
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFFFC62B),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        Icons.monetization_on,
        color: Colors.white,
        size: iconSize,
      ),
    );
  }
}

/// Formats barter coin amounts without a dollar sign. The app's currency is
/// in-app "coins", never fiat — nothing here should ever emit a $ or USD.
class CoinFormat {
  // Plain number, no unit word: whole numbers with no decimals (130), up to
  // 2 decimals only when fractional (135.5). Returns 'Free' for null/<=0 —
  // used for LISTING prices, where an unset/zero price conventionally means
  // the item is free, not "0 coins".
  static String amount(num? value) {
    if (value == null || value <= 0) return 'Free';
    return _formatNumber(value);
  }

  static String _formatNumber(num value) {
    final d = value.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }

  // Number + singular/plural unit ("1 coin" / "2 coins"), still 'Free' for
  // null/<=0 — use for LISTING/item prices displayed with the word "coins"
  // instead of a CoinIcon.
  static String withLabel(num? value) {
    if (value == null || value <= 0) return 'Free';
    return _withUnitUnchecked(value);
  }

  // Number + singular/plural unit, but WITHOUT the 'Free' fallback — 0 reads
  // as "0 coins". Use for offer amounts, totals, balances, and shortfalls,
  // where zero is a real value rather than "no price set".
  static String withUnit(num? value) => _withUnitUnchecked(value ?? 0);

  static String _withUnitUnchecked(num value) {
    final formatted = _formatNumber(value);
    final isSingular = value == 1 || value == -1;
    return '$formatted ${isSingular ? 'coin' : 'coins'}';
  }
}

/// Leading coin badge for amount text fields. Prefer [InputDecoration.prefix]
/// or pair with [coinPrefixIconConstraints] when using [prefixIcon].
Widget coinInputPrefix({double size = 20}) {
  return Padding(
    padding: const EdgeInsets.only(left: 4, right: 4),
    child: SizedBox(
      width: size,
      height: size,
      child: Center(
        child: CoinIcon(size: size, iconSize: size * 0.55),
      ),
    ),
  );
}

/// Keeps the coin round inside Material [prefixIcon] slots (avoids vertical stretch).
const BoxConstraints coinPrefixIconConstraints = BoxConstraints(
  minWidth: 44,
  maxWidth: 44,
  minHeight: 44,
  maxHeight: 44,
);

/// Price text with a leading coin icon.
class CoinPriceLabel extends StatelessWidget {
  final String text;
  final double iconSize;
  final TextStyle? style;
  final double spacing;

  const CoinPriceLabel({
    super.key,
    required this.text,
    this.iconSize = 16,
    this.style,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CoinIcon(size: iconSize, iconSize: iconSize * 0.64),
        SizedBox(width: spacing),
        Text(text, style: style),
      ],
    );
  }
}
