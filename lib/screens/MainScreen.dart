// main_screen.dart
import 'package:flutter/material.dart';
import 'package:yempover_app/models/ProductPost.dart';
import 'package:yempover_app/screens/PostDetailScreen.dart' hide UserItem;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Sample user items
  final List<UserItem> _userItems = [
    UserItem(
      id: '1',
      name: 'iPhone 13 Pro',
      category: 'Electronics',
      imageUrl:
          'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=500&q=80',
      isClubbable: true,
      isFromExistingPost: true,
      price: '\$800',
    ),
    UserItem(
      id: '2',
      name: 'Gaming Laptop',
      category: 'Electronics',
      imageUrl:
          'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=500&q=80',
      isClubbable: true,
      isFromExistingPost: true,
      price: '\$1200',
    ),
    UserItem(
      id: '3',
      name: 'Leather Sofa',
      category: 'Furniture',
      imageUrl:
          'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
      isClubbable: false,
      isFromExistingPost: true,
      price: '\$499',
    ),
    UserItem(
      id: '4',
      name: 'Mountain Bike',
      category: 'Sports',
      imageUrl:
          'https://images.unsplash.com/photo-1485965120184-e220f721d03e?w=500&q=80',
      isClubbable: true,
      isFromExistingPost: false,
      price: '\$350',
    ),
  ];

  // Sample posts
  final List<ProductPost> _posts = [
    ProductPost(
      userName: 'Melia K',
      timeAgo: '2 hr ago',
      category: 'Furniture',
      title: 'Sofa',
      distance: '1.7 Km',
      returnType: '\$299.99 or Television',
      barterStatus: 'Open for barter',
      postType: 'Bartering a product',
      tradeType: 'Barter',
      productLocation: '1862 Clarksburg Park Road',
      postedDate: DateTime(2023, 8, 4),
      wishListCategory: 'Electronics, Home Appliance',
      isFavorite: false,
      isHidden: false,
      images: [
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
        'https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=500&q=80',
        'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=500&q=80',
      ],
      views: 245,
      price: '\$299.99',
      description:
          'Barely used sofa for sale. Mint condition Orange color velvet upholstery. Teak wood base',
      transportationOption: 'This item can be transported to desired location',
      isVerified: true,
      canClubItems: true,
    ),
    ProductPost(
      userName: 'Charlotte Rose',
      timeAgo: '4 hr ago',
      category: 'Plumbing',
      title: 'Tap repairing',
      distance: '1.7 Km',
      returnType: '\$100.00',
      barterStatus: 'No Barter',
      postType: 'Looking for a service',
      tradeType: 'Service',
      productLocation: 'Hollenberg',
      postedDate: DateTime.now().subtract(const Duration(hours: 4)),
      wishListCategory: '',
      isFavorite: false,
      isHidden: false,
      images: [
        'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
      ],
      views: 189,
      price: '\$100.00',
      description:
          'Professional tap repairing service available. Fast and reliable work.',
      transportationOption: 'Service at your location',
      isVerified: true,
      canClubItems: false,
    ),
    ProductPost(
      userName: 'Andrew Danny',
      timeAgo: '5 hr ago',
      category: 'Electronics',
      title: 'Television',
      distance: '1.5 Km',
      returnType: 'Home Appliance',
      barterStatus: 'Open for barter',
      postType: 'Bartering a product',
      tradeType: 'Barter',
      productLocation: 'Kansas City',
      postedDate: DateTime.now().subtract(const Duration(hours: 5)),
      wishListCategory: 'Home Appliance, Furniture',
      isFavorite: false,
      isHidden: false,
      images: [
        'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=500&q=80',
        'https://images.unsplash.com/photo-1622925566273-6a5d3c5d6c3a?w=500&q=80',
      ],
      views: 312,
      price: '',
      description:
          '55" Smart TV with 4K resolution. Excellent condition, includes all accessories.',
      transportationOption: 'Pickup only',
      isVerified: false,
      canClubItems: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yempover'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
        ],
      ),
      body: ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          final post = _posts[index];
          return _buildPostCard(post);
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: 'Trade'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildPostCard(ProductPost post) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          // Navigator.push(
          //   context,
          //   // MaterialPageRoute(
          //   //   builder: (context) =>
          //   //     //  PostDetailScreen(post: post, userItems: _userItems),
          //   // ),
          // );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SizedBox(
              height: 200,
              width: double.infinity,
              child: Image.network(post.images.first, fit: BoxFit.cover),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    post.category,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.userName,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        post.distance,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (post.price.isNotEmpty)
                        Text(
                          post.price,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            fontSize: 16,
                          ),
                        ),
                      Chip(
                        label: Text(post.barterStatus),
                        backgroundColor: post.barterStatus == 'Open for barter'
                            ? Colors.orange.shade100
                            : Colors.grey.shade100,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
