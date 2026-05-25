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

/// Formats barter coin amounts without a dollar sign.
class CoinFormat {
  static String amount(num? value) {
    if (value == null || value <= 0) return 'Free';
    final d = value.toDouble();
    if (d == d.roundToDouble()) return d.toInt().toString();
    return d.toStringAsFixed(2);
  }

  static String withLabel(num? value) {
    final a = amount(value);
    return a == 'Free' ? a : '$a coins';
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
