import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempower_app/screens/TradeHistoryScreen.dart';

class TradeDetailScreen extends StatelessWidget {
  final TradeHistoryItem trade;

  const TradeDetailScreen({super.key, required this.trade});

  @override
  Widget build(BuildContext context) {
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
              elevation: 2,
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
                            color: _getTradeTypeColor(trade.tradeType),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            trade.tradeType,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Deal completed on:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          _formatDateWithSuffix(trade.date),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Items Swapped Section
            Text(
              'Items Swapped:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // User Profile and Items
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Other User
                    _buildUserSection(
                      title: trade.otherPartyName,
                      imageUrl: trade.otherPartyImage,
                      itemTitle: trade.tradeType == 'Barter'
                          ? trade.swappedItemTitle!
                          : trade.title,
                      itemImageUrl: trade.tradeType == 'Barter'
                          ? trade.swappedItemImage!
                          : trade.imageUrl,
                      isOtherUser: true,
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Current User
                    _buildUserSection(
                      title: 'Me',
                      imageUrl: 'https://i.pravatar.cc/150?img=11',
                      itemTitle: trade.title,
                      itemImageUrl: trade.imageUrl,
                      isOtherUser: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Price Information (for Sold/Purchased)
            if (trade.tradeType == 'Sold' || trade.tradeType == 'Purchased')
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
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildPriceRow(
                            'Actual Price',
                            '\$${trade.actualPrice!.toStringAsFixed(2)}',
                            Colors.grey,
                          ),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Selling Price',
                            '\$${trade.sellingPrice!.toStringAsFixed(2)}',
                            Colors.green,
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          _buildPriceRow(
                            'Price Difference',
                            '\$${(trade.actualPrice! - trade.sellingPrice!).abs().toStringAsFixed(2)}',
                            trade.actualPrice! > trade.sellingPrice!
                                ? Colors.red
                                : Colors.green,
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
                    elevation: 2,
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

            const SizedBox(height: 40),
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
    required bool isOtherUser,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 24, backgroundImage: NetworkImage(imageUrl)),
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
                      color: isOtherUser
                          ? Colors.blue.shade50
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOtherUser ? 'Their Item' : 'My Item',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOtherUser ? Colors.blue : Colors.grey,
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
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  itemTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
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
        Text(
          value,
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

    return '${day}$suffix ${DateFormat('MMM yyyy').format(date)}';
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
