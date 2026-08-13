import 'package:flutter/material.dart';
import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:yempover_app/screens/OfferDescriptionScreen.dart';
import 'package:yempover_app/widgets/coin_icon.dart';

// Shared "How do you want to exchange?" flow, backend-driven via
// GET /trade-chat/exchange-modes — including cross-mode requests (e.g.
// requesting a barter on a pure-price listing). Used by both the
// product-detail "Make an Offer" entry point and the in-chat "Make Offer
// Again" entry point so a re-offer always has the exact same options as a
// first-time offer.

OfferSubmissionMode mapOfferTypeToSubmissionMode(String offerType) {
  switch (offerType) {
    case 'BARTER':
      return OfferSubmissionMode.barter;
    case 'BOTH':
      return OfferSubmissionMode.both;
    default:
      return OfferSubmissionMode.price;
  }
}

// "This product is for pure price, but you can request a barter. Continue?"
// — shown before proceeding with a cross-mode option.
Future<bool?> confirmCrossModeOption(
  BuildContext context,
  ExchangeModeOption option,
) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(option.label),
      content: Text(option.note),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}

// Returned by showExchangeModeSheet when the user picks the separate
// "zero-coin transaction" row instead of one of the backend's exchange-mode
// cards — a client-side-only addition (product offers only), not itself an
// ExchangeModeOption.
class ZeroCoinSelected {
  const ZeroCoinSelected();
}

// Returns either an ExchangeModeOption, a ZeroCoinSelected, or null
// (dismissed) — callers should check `is` before using the result.
Future<Object?> showExchangeModeSheet(
  BuildContext context,
  ExchangeModeOptions options,
) async {
  return showModalBottomSheet<Object>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How do you want to exchange?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (options.listingPrice != null && options.listingPrice! > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Listed at \$${options.listingPrice!.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 14),
            ...options.options.map(
              (option) => _buildExchangeModeCard(context, option),
            ),
            if (options.target == 'product') ...[
              const Divider(height: 24),
              _buildZeroCoinOption(context),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _buildZeroCoinOption(BuildContext context) {
  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(
      Icons.check_box_outlined,
      color: Colors.teal,
      size: 32,
    ),
    title: const Text(
      'Request zero-coin transaction',
      style: TextStyle(fontWeight: FontWeight.w600),
    ),
    subtitle: const Text(
      'No coins involved — offer an item in return, or ask for it free.',
      style: TextStyle(fontSize: 12),
    ),
    onTap: () => Navigator.pop(context, const ZeroCoinSelected()),
  );
}

Widget _buildExchangeModeCard(BuildContext context, ExchangeModeOption option) {
  final isBarterFlavored =
      option.mode == 'PURE_BARTER' || option.mode == 'SERVICE_FOR_BARTER';

  return ListTile(
    contentPadding: EdgeInsets.zero,
    leading: isBarterFlavored
        ? const Icon(Icons.swap_horiz, color: Colors.orange, size: 32)
        : const CoinIcon(size: 32, iconSize: 20),
    title: Row(
      children: [
        Flexible(
          child: Text(
            option.label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (option.isCrossMode) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Request',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    ),
    subtitle: Text(
      option.note,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    ),
    onTap: () => Navigator.pop(context, option),
  );
}
