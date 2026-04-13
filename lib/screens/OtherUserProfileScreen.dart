import 'package:flutter/material.dart';
import 'package:Yempover_app/models/ProductPost.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userId;

  const OtherUserProfileScreen({super.key, required this.userId});

  @override
  _OtherUserProfileScreenState createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  bool _isBlocked = false;
  bool _hasOpenDeal = false;
  bool _shareEmail = true;
  bool _sharePhoneNumber = true;

  final List<ProductPost> _userPosts = [
    ProductPost(
      userName: 'Meliya K',
      timeAgo: '5 hr ago',
      category: 'Electronics',
      title: 'Television',
      distance: '2.1 Km',
      returnType: 'Home Appliance',
      barterStatus: 'Open for barter',
      postType: 'Bartering a product',
      tradeType: 'Barter',
      productLocation: 'Philadelphia, PA',
      postedDate: DateTime.now().subtract(const Duration(hours: 5)),
      wishListCategory: 'Home Appliance',
      isFavorite: false,
      isHidden: false,
      images: [
        'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=500&q=80',
      ],
      views: 156,
      price: '',
      description: '55" Smart TV in excellent condition',
      transportationOption: 'Pickup only',
      isVerified: true,
      canClubItems: true,
    ),
    ProductPost(
      userName: 'Meliya K',
      timeAgo: '2 days ago',
      category: 'Furniture',
      title: 'Sofa',
      distance: '2.1 Km',
      returnType: '\$299.99 or Electronics',
      barterStatus: 'Open for barter',
      postType: 'Bartering a product',
      tradeType: 'Barter',
      productLocation: 'Philadelphia, PA',
      postedDate: DateTime.now().subtract(const Duration(days: 2)),
      wishListCategory: 'Electronics',
      isFavorite: false,
      isHidden: false,
      images: [
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
      ],
      views: 89,
      price: '\$299.99',
      description: 'Comfortable velvet sofa',
      transportationOption: 'Transport available',
      isVerified: true,
      canClubItems: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'block',
                child: Row(
                  children: [
                    Icon(Icons.block, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Block User'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            _buildProfileHeader(),

            const SizedBox(height: 24),

            // Contact Information (only if shared)
            if (_shareEmail || _sharePhoneNumber) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_shareEmail)
                        _buildContactItem(
                          Icons.email,
                          'meliyak.test@gmail.com',
                          Colors.blue,
                        ),
                      if (_shareEmail && _sharePhoneNumber)
                        const SizedBox(height: 8),
                      if (_sharePhoneNumber)
                        _buildContactItem(
                          Icons.phone,
                          '(415) 555-0132',
                          Colors.green,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // User's Posts
            const Text(
              'Current Posts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Posts List
            Column(
              children: _userPosts.map((post) => _buildPostCard(post)).toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Image and Name
            Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=32',
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Meliya K',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text(
                      'Philadelphia, PA',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: const Text(
                        'Verified',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Joining', '10 May 2023'),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                _buildStatItem('Completed Trades', '12'),
              ],
            ),

            const SizedBox(height: 16),

            // Block Status
            if (_isBlocked)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'This user is blocked',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
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

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.black87)),
      ],
    );
  }

  Widget _buildPostCard(ProductPost post) {
    return GestureDetector(
      // onTap: () {
      //   Navigator.push(
      //   //  context,
      //     // MaterialPageRoute(
      //     // //  builder: (context) => PostDetailScreen(post: post, userItems: []),
      //     // ),
      //  // );
      // },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '${post.timeAgo} • ',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
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
                    post.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    post.barterStatus,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'In Return: ${post.returnType}',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog() {
    if (_hasOpenDeal) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Block User'),
          content: const Text(
            'You have an open deal with this user. Please complete or cancel the deal before blocking.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          _isBlocked
              ? 'Are you sure you want to unblock this user?'
              : 'Are you sure you want to block this user? You will no longer see their posts or be able to interact with them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isBlocked = !_isBlocked;
              });
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isBlocked
                        ? 'User has been blocked'
                        : 'User has been unblocked',
                  ),
                  backgroundColor: _isBlocked ? Colors.red : Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isBlocked ? Colors.green : Colors.red,
            ),
            child: Text(_isBlocked ? 'Unblock' : 'Block'),
          ),
        ],
      ),
    );
  }
}
