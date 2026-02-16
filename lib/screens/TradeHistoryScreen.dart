import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/screens/TradeDetailScreen.dart';

class TradeHistoryScreen extends StatefulWidget {
  const TradeHistoryScreen({super.key});

  @override
  _TradeHistoryScreenState createState() => _TradeHistoryScreenState();
}

class _TradeHistoryScreenState extends State<TradeHistoryScreen> {
  final List<TradeHistoryItem> _tradeHistory = [
    TradeHistoryItem(
      id: '1',
      title: 'Books',
      imageUrl:
          'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=400&q=80',
      tradeType: 'Barter',
      date: DateTime(2023, 11, 28),
      otherPartyName: 'Clara Ari',
      otherPartyImage: 'https://i.pravatar.cc/150?img=32',
      actualPrice: null,
      sellingPrice: null,
      swappedItemTitle: 'Backpack',
      swappedItemImage:
          'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=400&q=80',
      remarks:
          'Deal was completed on-time. Additional expenses 20 dollars transportation',
    ),
    TradeHistoryItem(
      id: '2',
      title: 'Armchair',
      imageUrl:
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=400&q=80',
      tradeType: 'Purchased',
      date: DateTime(2023, 11, 27),
      price: 25.00,
      otherPartyName: 'Michael Chen',
      otherPartyImage: 'https://i.pravatar.cc/150?img=45',
      actualPrice: 30.00,
      sellingPrice: 25.00,
    ),
    TradeHistoryItem(
      id: '3',
      title: 'Bicycle',
      imageUrl:
          'https://images.unsplash.com/photo-1532298229144-0ec0c57515c7?w=400&q=80',
      tradeType: 'Purchased',
      date: DateTime(2023, 11, 27),
      price: 132.49,
      otherPartyName: 'Sarah Johnson',
      otherPartyImage: 'https://i.pravatar.cc/150?img=22',
      actualPrice: 150.00,
      sellingPrice: 132.49,
    ),
    TradeHistoryItem(
      id: '4',
      title: 'Sofa',
      imageUrl:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=400&q=80',
      tradeType: 'Sold',
      date: DateTime(2023, 10, 11),
      price: 145.49,
      otherPartyName: 'Robert Wilson',
      otherPartyImage: 'https://i.pravatar.cc/150?img=15',
      actualPrice: 160.00,
      sellingPrice: 145.49,
    ),
    TradeHistoryItem(
      id: '5',
      title: 'Smart Speaker',
      imageUrl:
          'https://images.unsplash.com/photo-1543512214-318c7553f230?w=400&q=80',
      tradeType: 'Sold',
      date: DateTime(2023, 10, 5),
      price: 99.99,
      otherPartyName: 'Emma Davis',
      otherPartyImage: 'https://i.pravatar.cc/150?img=28',
      actualPrice: 120.00,
      sellingPrice: 99.99,
    ),
    TradeHistoryItem(
      id: '6',
      title: 'Water Bottle',
      imageUrl:
          'https://images.unsplash.com/photo-1523362628745-0c100150b504?w=400&q=80',
      tradeType: 'Barter',
      date: DateTime(2023, 10, 2),
      otherPartyName: 'David Lee',
      otherPartyImage: 'https://i.pravatar.cc/150?img=19',
      actualPrice: null,
      sellingPrice: null,
      swappedItemTitle: 'Coffee Mug',
      swappedItemImage:
          'https://images.unsplash.com/photo-1514228742587-6b1558fcf93a?w=400&q=80',
    ),
    TradeHistoryItem(
      id: '7',
      title: 'Sweatshirt',
      imageUrl:
          'https://images.unsplash.com/photo-1556821840-3a63f95609a7?w=400&q=80',
      tradeType: 'Sold',
      date: DateTime(2023, 8, 26),
      price: 29.99,
      otherPartyName: 'Lisa Brown',
      otherPartyImage: 'https://i.pravatar.cc/150?img=34',
      actualPrice: 35.00,
      sellingPrice: 29.99,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trade History',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tradeHistory.length,
        itemBuilder: (context, index) {
          final trade = _tradeHistory[index];
          return _buildTradeItem(trade);
        },
      ),
    );
  }

  Widget _buildTradeItem(TradeHistoryItem trade) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TradeDetailScreen(trade: trade),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(trade.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trade.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Trade Type and Price/Barter
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTradeTypeColor(trade.tradeType),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          trade.tradeType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (trade.tradeType == 'Sold' ||
                          trade.tradeType == 'Purchased')
                        Text(
                          '\$${trade.price!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: trade.tradeType == 'Sold'
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Date
                  Text(
                    DateFormat('dd MMM yyyy').format(trade.date),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // Chevron Icon
            const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
          ],
        ),
      ),
    );
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

class TradeHistoryItem {
  final String id;
  final String title;
  final String imageUrl;
  final String tradeType;
  final DateTime date;
  final double? price;
  final String otherPartyName;
  final String otherPartyImage;
  final double? actualPrice;
  final double? sellingPrice;
  final String? swappedItemTitle;
  final String? swappedItemImage;
  final String? remarks;

  TradeHistoryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.tradeType,
    required this.date,
    this.price,
    required this.otherPartyName,
    required this.otherPartyImage,
    this.actualPrice,
    this.sellingPrice,
    this.swappedItemTitle,
    this.swappedItemImage,
    this.remarks,
  });
}
