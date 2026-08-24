import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trade_history_model.dart';
import 'package:yempover_app/models/ProductPostmain.dart' show PostType;
import 'package:yempover_app/screens/PostDetailScreen.dart';
import 'package:yempover_app/services/api_service.dart';
import 'package:yempover_app/services/profile_session_manager.dart';
import 'package:yempover_app/utils/error_message_utils.dart';
import 'package:yempover_app/widgets/coin_icon.dart';

// A single bartered image paired with the product it belongs to (null
// productId when there's nothing to deep-link to — e.g. no snapshot data
// on older trades).
class _BarterLineItem {
  final String imageUrl;
  final String? productId;

  const _BarterLineItem({required this.imageUrl, required this.productId});
}

class TradeDetailScreen extends StatelessWidget {
  final TradeItem trade;
  final String? currentUserId;

  const TradeDetailScreen({super.key, required this.trade, this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final tradeType = currentUserId != null
        ? trade.getTradeType(currentUserId!)
        : trade.getDisplayTradeType();

    final isBarter = trade.isBarter;
    final price = trade.displayPrice;
    final actualPrice = trade.product.price;
    final difference = (price != null && actualPrice != null)
        ? _calculatePriceDifference(
            tradeType: tradeType,
            actualPrice: actualPrice,
            finalPrice: price,
          )
        : null;

    // Prefer the backend's exchangeSummary for the price block when present
    // — it's computed once, server-side, from the actual transaction record.
    // Falls back to the locally-derived values above for trades that predate
    // this field.
    final summary = trade.exchangeSummary;
    final effectiveActualPrice = summary?.actualPrice ?? actualPrice;
    final effectiveSellingPrice = summary?.coins ?? price;
    final effectiveDifference = summary?.priceDifference ?? difference;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trade Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trade Type and Date
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Trade Type:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getTradeTypeColor(tradeType),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tradeType,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (trade.exchangeSummary != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Exchange Type:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              trade.exchangeSummary!.label,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 5,
                          child: Text(
                            'Deal completed on:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: Text(
                            _formatDateWithSuffix(trade.completedDate),
                            textAlign: TextAlign.right,
                            softWrap: true,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Item Section
            Text(
              trade.hasBarterItemSnapshot ? 'Item Bartered:' : 'Item Details:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // A genuine two-item swap needs a distinct record for each side.
            // This isn't gated on `isBarter` — that flag just says which
            // bucket the backend sorted the trade into (Sold/Bought vs
            // Barter), not whether a barter item was actually part of the
            // deal. A "Barter + Coins" offer accepted on a for-sale listing
            // lands in the Bought/Sold bucket (isBarter == false) but still
            // has a real barterItemTitle/Images snapshot that must be shown.
            // Older trades (before that was tracked) and pure sales never
            // have a snapshot, so they still fall through to the single,
            // honestly-labeled card below instead of fake "Their Item"/"My
            // Item" cards.
            if (trade.hasBarterItemSnapshot)
              _buildBarterSwapCard(context, trade)
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildUserSection(
                    context: context,
                    title: trade.otherUser.fullName,
                    imageUrl:
                        trade.otherUser.profileImage ??
                        'https://via.placeholder.com/150',
                    badgeLabel: tradeType == 'Sold'
                        ? 'Sold to this user'
                        : tradeType == 'Purchased'
                        ? 'Purchased from this user'
                        : 'Bartered with this user',
                    itemTitle: trade.product.title,
                    items: [_listingItem(trade)],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Price Information: shown for Sold/Purchased trades, and also
            // for a Barter + Coins deal that landed in the barter bucket but
            // still had a real coin amount recorded (trade.sellingPrice).
            // Excluded for a pure barter with no price component, since
            // displayPrice would otherwise fall back to the listing's
            // nominal price — a number that was never actually charged.
            if ((!isBarter || trade.sellingPrice != null) &&
                effectiveSellingPrice != null &&
                effectiveActualPrice != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price Information:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPriceRow(
                            'Actual Price',
                            CoinFormat.amount(effectiveActualPrice),
                            Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Selling Price',
                            CoinFormat.amount(effectiveSellingPrice),
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Price Difference',
                            _formatPriceDifference(effectiveDifference),
                            _priceDifferenceColor(effectiveDifference),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Remarks
            if (trade.remarks != null && trade.remarks!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remarks:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        trade.remarks!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            // Participant Remarks (if available)
            if (trade.participantRemarks.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participant Remarks:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        trade.participantRemarks,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Initiator Remarks (if available)
            if (trade.initiatorRemarks != null &&
                trade.initiatorRemarks!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Initiator Remarks:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        trade.initiatorRemarks!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 40),

            // Product Location (if available)
            if (trade.product.location.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        trade.product.location,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _calculatePriceDifference({
    required String tradeType,
    required double actualPrice,
    required double finalPrice,
  }) {
    if (tradeType == 'Purchased') {
      // Positive means user saved money compared to listed price.
      return actualPrice - finalPrice;
    }

    // For sold trades, positive means profit over listed price.
    return finalPrice - actualPrice;
  }

  String _formatPriceDifference(double? difference) {
    if (difference == null) return '--';
    if (difference == 0) return '0';
    final sign = difference > 0 ? '+' : '-';
    return '$sign${CoinFormat.amount(difference.abs())}';
  }

  Color _priceDifferenceColor(double? difference) {
    if (difference == null || difference == 0) return Colors.grey;
    return difference > 0 ? Colors.green : Colors.red;
  }

  // The logged-in user's own profile image — was hardcoded to a placeholder
  // before, unlike "Their Item" which already reads trade.otherUser's real
  // image. Falls back to the same placeholder when no image is set.
  String _myProfileImage() {
    final image = ProfileSessionManager.instance.profile?.profileImage;
    return (image != null && image.trim().isNotEmpty)
        ? image
        : 'https://via.placeholder.com/150';
  }

  // The listing side of the trade is always exactly one product.
  _BarterLineItem _listingItem(TradeItem trade) {
    final image = trade.product.primaryImage.isNotEmpty
        ? trade.product.primaryImage
        : 'https://via.placeholder.com/150';
    return _BarterLineItem(imageUrl: image, productId: trade.product.id);
  }

  // The barter-offer side can hold several clubbed products — pair each
  // image with its product id (same order, see MobileUserService) so every
  // one of them deep-links, not just the first.
  List<_BarterLineItem> _barterSnapshotItems(TradeItem trade) {
    // Prefer the resolved barterProducts — each one already carries its own
    // id + image, so there's no index-pairing to get wrong (and it's robust
    // to a clubbed offer where the images/ids arrays could ever drift).
    if (trade.barterProducts.isNotEmpty) {
      return trade.barterProducts.map((p) {
        final image = p.images.isNotEmpty
            ? p.images.first
            : 'https://via.placeholder.com/150';
        return _BarterLineItem(imageUrl: image, productId: p.id);
      }).toList();
    }
    if (trade.barterItemImages.isEmpty) {
      return const [
        _BarterLineItem(
          imageUrl: 'https://via.placeholder.com/150',
          productId: null,
        ),
      ];
    }
    return List.generate(trade.barterItemImages.length, (i) {
      final productId = i < trade.barterProductIds.length
          ? trade.barterProductIds[i]
          : null;
      return _BarterLineItem(
        imageUrl: trade.barterItemImages[i],
        productId: productId,
      );
    });
  }

  Future<void> _openProductDetail(BuildContext context, String productId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final response = await ApiService().getPostDetail(
        postId: productId,
        type: PostType.product,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PostDetailScreen(post: response.post, userItems: const []),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      final isGone = e is ApiException && (e.statusCode == 410 || e.statusCode == 403);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isGone
                ? 'This item is no longer available.'
                : ErrorMessageUtils.sanitize(e),
          ),
          backgroundColor: isGone ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Widget _buildBarterSwapCard(BuildContext context, TradeItem trade) {
    // isMyBarterItem == true: I made the accepted offer, so the barter
    // snapshot is my item and `product` is the listing they posted.
    // false/null: they made it — `product` is my listing, barter snapshot
    // is their item.
    final theirItems = trade.isMyBarterItem == true
        ? [_listingItem(trade)]
        : _barterSnapshotItems(trade);
    final myItems = trade.isMyBarterItem == true
        ? _barterSnapshotItems(trade)
        : [_listingItem(trade)];

    // Real per-item titles from the resolved barterProducts (handles a
    // clubbed multi-item barter correctly) — falls back to the offerer's
    // single free-text barterItemTitle for older trades.
    final barterSideTitle = trade.barterProducts.isNotEmpty
        ? trade.barterProducts.map((p) => p.title).join(', ')
        : (trade.barterItemTitle ?? trade.product.title);

    final theirItemTitle = trade.isMyBarterItem == true
        ? trade.product.title
        : barterSideTitle;
    final myItemTitle = trade.isMyBarterItem == true
        ? barterSideTitle
        : trade.product.title;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserSection(
              context: context,
              title: trade.otherUser.fullName,
              imageUrl:
                  trade.otherUser.profileImage ??
                  'https://via.placeholder.com/150',
              badgeLabel: 'Their Item',
              itemTitle: theirItemTitle,
              items: theirItems,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildUserSection(
              context: context,
              title: 'Me',
              imageUrl: _myProfileImage(),
              badgeLabel: 'My Item',
              itemTitle: myItemTitle,
              items: myItems,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection({
    required BuildContext context,
    required String title,
    required String imageUrl,
    required String itemTitle,
    required List<_BarterLineItem> items,
    required String badgeLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(imageUrl),
              onBackgroundImageError: (exception, stackTrace) =>
                  const Icon(Icons.person),
              child: imageUrl.contains('placeholder')
                  ? const Icon(Icons.person, size: 24)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Item Details — one thumbnail per bartered product (clubbed offers
        // can hold several); each deep-links when a product id is known.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: items.map((item) {
                  final thumb = Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          // Handle image error
                        },
                      ),
                    ),
                    child: item.imageUrl.contains('placeholder')
                        ? const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          )
                        : null,
                  );
                  return item.productId != null
                      ? InkWell(
                          borderRadius: BorderRadius.circular(6),
                          onTap: () =>
                              _openProductDetail(context, item.productId!),
                          child: thumb,
                        )
                      : thumb;
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text(
                itemTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        CoinPriceLabel(
          text: value,
          iconSize: 18,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  String _formatDateWithSuffix(DateTime date) {
    final day = date.day;
    String suffix = 'th';

    if (day % 10 == 1 && day != 11) {
      suffix = 'st';
    } else if (day % 10 == 2 && day != 12) {
      suffix = 'nd';
    } else if (day % 10 == 3 && day != 13) {
      suffix = 'rd';
    }

    return '$day$suffix ${DateFormat('MMM yyyy').format(date)}';
  }

  Color _getTradeTypeColor(String tradeType) {
    switch (tradeType) {
      case 'Barter':
        return Colors.orange;
      case 'Sold':
        return Colors.green;
      case 'Purchased':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
