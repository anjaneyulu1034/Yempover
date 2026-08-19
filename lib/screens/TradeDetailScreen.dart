import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trade_history_model.dart';
import 'package:yempover_app/services/profile_session_manager.dart';
import 'package:yempover_app/widgets/coin_icon.dart';

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
              _buildBarterSwapCard(trade)
            else
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildUserSection(
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
                    itemImageUrl: trade.product.primaryImage.isNotEmpty
                        ? trade.product.primaryImage
                        : 'https://via.placeholder.com/150',
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
                price != null &&
                actualPrice != null)
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
                            CoinFormat.amount(actualPrice),
                            Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Selling Price',
                            CoinFormat.amount(price),
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Price Difference',
                            _formatPriceDifference(difference),
                            _priceDifferenceColor(difference),
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

  Widget _buildBarterSwapCard(TradeItem trade) {
    final barterImage = trade.barterItemImages.isNotEmpty
        ? trade.barterItemImages.first
        : 'https://via.placeholder.com/150';
    final listedImage = trade.product.primaryImage.isNotEmpty
        ? trade.product.primaryImage
        : 'https://via.placeholder.com/150';

    // isMyBarterItem == true: I made the accepted offer, so the barter
    // snapshot is my item and `product` is the listing they posted.
    // false/null: they made it — `product` is my listing, barter snapshot
    // is their item.
    final theirItemTitle = trade.isMyBarterItem == true
        ? trade.product.title
        : (trade.barterItemTitle ?? trade.product.title);
    final theirItemImage = trade.isMyBarterItem == true
        ? listedImage
        : barterImage;
    final myItemTitle = trade.isMyBarterItem == true
        ? (trade.barterItemTitle ?? trade.product.title)
        : trade.product.title;
    final myItemImage = trade.isMyBarterItem == true
        ? barterImage
        : listedImage;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildUserSection(
              title: trade.otherUser.fullName,
              imageUrl:
                  trade.otherUser.profileImage ??
                  'https://via.placeholder.com/150',
              badgeLabel: 'Their Item',
              itemTitle: theirItemTitle,
              itemImageUrl: theirItemImage,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            _buildUserSection(
              title: 'Me',
              imageUrl: _myProfileImage(),
              badgeLabel: 'My Item',
              itemTitle: myItemTitle,
              itemImageUrl: myItemImage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection({
    required String title,
    required String imageUrl,
    required String itemTitle,
    required String itemImageUrl,
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

        // Item Details
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  image: DecorationImage(
                    image: NetworkImage(itemImageUrl),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      // Handle image error
                    },
                  ),
                ),
                child: itemImageUrl.contains('placeholder')
                    ? const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
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
