import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempower_app/models/TradePost.dart';
import 'package:yempower_app/screens/AddPostScreen.dart';
import 'package:yempower_app/screens/PostDetailScreen.dart'
    hide PostDetailScreen;

class TradeBoothScreen extends StatefulWidget {
  const TradeBoothScreen({super.key});

  @override
  _TradeBoothScreenState createState() => _TradeBoothScreenState();
}

class _TradeBoothScreenState extends State<TradeBoothScreen> {
  final List<TradePost> _tradePosts = [
    TradePost(
      id: '1',
      title: 'Wall Clock',
      category: 'Home Decor',
      location: 'Open Office',
      postedDateTime: DateTime.now().subtract(const Duration(hours: 2)),
      isOpenForBarter: true,
      views: 67,
      openOffers: 3,
      price: '',
      wishListCategory: 'Smart Watch',
      returnDetails: 'In return looking for a Smart Watch',
      transportationFlexibility:
          'This item can be transported to desired location',
      description:
          'Clock Type: Analog\nMake: Time:\nCondition: Never Use\nSize: 50 cm dB',
      images: [
        'https://images.unsplash.com/photo-1560869713-7d0a5a1a0b6f?w=500&q=80',
      ],
      canClubItems: true,
      isSold: false,
      hasAcceptedOffer: false,
    ),
    TradePost(
      id: '2',
      title: 'Sofa',
      category: 'Furniture',
      location: '1862 Clarksburg Park Road',
      postedDateTime: DateTime.now().subtract(const Duration(days: 1)),
      isOpenForBarter: true,
      views: 245,
      openOffers: 5,
      price: '\$299.99',
      wishListCategory: 'Television',
      returnDetails: '\$299.99 or Television',
      transportationFlexibility:
          'This item can be transported to desired location',
      description:
          'Barely used sofa for sale. Mint condition Orange color velvet upholstery. Teak wood base',
      images: [
        'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
      ],
      canClubItems: true,
      isSold: false,
      hasAcceptedOffer: true,
    ),
    TradePost(
      id: '3',
      title: 'iPhone 13 Pro',
      category: 'Electronics',
      location: 'Downtown',
      postedDateTime: DateTime.now().subtract(const Duration(days: 2)),
      isOpenForBarter: true,
      views: 189,
      openOffers: 2,
      price: '\$800',
      wishListCategory: 'Laptop',
      returnDetails: 'Laptop or \$800',
      transportationFlexibility: 'Meetup or shipping available',
      description:
          'iPhone 13 Pro 256GB, excellent condition with original box and accessories.',
      images: [
        'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=500&q=80',
      ],
      canClubItems: true,
      isSold: false,
      hasAcceptedOffer: false,
    ),
    TradePost(
      id: '4',
      title: 'Television',
      category: 'Electronics',
      location: 'Kansas City',
      postedDateTime: DateTime.now().subtract(const Duration(days: 3)),
      isOpenForBarter: true,
      views: 312,
      openOffers: 0,
      price: '',
      wishListCategory: 'Home Appliance',
      returnDetails: 'Home Appliance',
      transportationFlexibility: 'Pickup only',
      description:
          '55" Smart TV with 4K resolution. Excellent condition, includes all accessories.',
      images: [
        'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=500&q=80',
      ],
      canClubItems: true,
      isSold: false,
      hasAcceptedOffer: false,
    ),
    TradePost(
      id: '5',
      title: 'Tap Repairing Service',
      category: 'Plumbing',
      location: 'Hollenberg',
      postedDateTime: DateTime.now().subtract(const Duration(days: 4)),
      isOpenForBarter: false,
      views: 150,
      openOffers: 1,
      price: '\$100.00',
      wishListCategory: '',
      returnDetails: '\$100.00',
      transportationFlexibility: 'Service at your location',
      description:
          'Professional tap repairing service available. Fast and reliable work.',
      images: [
        'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
      ],
      canClubItems: false,
      isSold: false,
      hasAcceptedOffer: false,
    ),
    TradePost(
      id: '6',
      title: 'Gaming Laptop',
      category: 'Electronics',
      location: 'Tech Park',
      postedDateTime: DateTime.now().subtract(const Duration(days: 5)),
      isOpenForBarter: true,
      views: 420,
      openOffers: 8,
      price: '\$1200',
      wishListCategory: 'Camera, Smartphone',
      returnDetails: '\$1200 or Camera/Smartphone',
      transportationFlexibility: 'Can be transported with delivery charge',
      description: 'High-end gaming laptop with RTX 3080, 32GB RAM, 1TB SSD',
      images: [
        'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=500&q=80',
      ],
      canClubItems: true,
      isSold: true,
      hasAcceptedOffer: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trade Booth',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Add Post Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _navigateToAddPost,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Post',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5BFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Posts List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _tradePosts.length,
              itemBuilder: (context, index) {
                return _buildPostCard(_tradePosts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(TradePost post) {
    return GestureDetector(
      onTap: () => _openPostDetails(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: DecorationImage(
                      image: NetworkImage(post.images.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (post.isSold)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'SOLD',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Post Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          post.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        post.location,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Barter Status and Return Details
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: post.isOpenForBarter
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.isOpenForBarter
                              ? 'Open for Barter'
                              : 'No Barter',
                          style: TextStyle(
                            fontSize: 12,
                            color: post.isOpenForBarter
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          post.returnDetails,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Posted Date, Views, and Offers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat(
                          'MMM dd, yyyy - hh:mm a',
                        ).format(post.postedDateTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.remove_red_eye,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${post.views}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () => _navigateToOffersInbox(post),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.local_offer,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.openOffers} Offers',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Transportation Flexibility
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          post.transportationFlexibility,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Three-dot Menu
                  Align(
                    alignment: Alignment.centerRight,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.grey),
                      onSelected: (value) => _handleMenuOption(value, post),
                      itemBuilder: (context) => _buildMenuItems(post),
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

  List<PopupMenuEntry<String>> _buildMenuItems(TradePost post) {
    final items = <PopupMenuEntry<String>>[];

    if (!post.hasAcceptedOffer) {
      items.add(
        const PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit'),
            ],
          ),
        ),
      );
    }

    if (!post.hasAcceptedOffer) {
      items.add(
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete'),
            ],
          ),
        ),
      );
    }

    if (!post.isSold) {
      items.add(
        const PopupMenuItem<String>(
          value: 'mark_sold',
          child: Row(
            children: [
              Icon(Icons.check_circle, size: 20, color: Colors.green),
              SizedBox(width: 8),
              Text('Mark as Sold'),
            ],
          ),
        ),
      );
    }

    return items;
  }

  void _handleMenuOption(String value, TradePost post) {
    switch (value) {
      case 'edit':
        _editPost(post);
        break;
      case 'delete':
        _deletePost(post);
        break;
      case 'mark_sold':
        _markAsSold(post);
        break;
    }
  }

  void _editPost(TradePost post) {
    if (post.openOffers > 0) {
      _showAlertDialog(
        'Cannot Edit',
        'This post has received offers and cannot be edited.',
      );
      return;
    }

    if (post.hasAcceptedOffer) {
      _showAlertDialog(
        'Cannot Edit',
        'This post has an accepted offer and cannot be edited.',
      );
      return;
    }

    // Navigate to edit screen
    _showEditScreen(post);
  }

  void _deletePost(TradePost post) {
    if (post.hasAcceptedOffer) {
      _showAlertDialog(
        'Cannot Delete',
        'This post has an accepted offer and cannot be deleted.',
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? Any open offers will be automatically rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _confirmDelete(post);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(TradePost post) {
    // In a real app, this would call an API
    setState(() {
      _tradePosts.removeWhere((p) => p.id == post.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${post.title} has been deleted'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _markAsSold(TradePost post) {
    if (post.openOffers > 0 && !post.hasAcceptedOffer) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Complete Deal'),
          content: const Text(
            'You will have to complete an open deal, by clicking on "Deal Completed", '
            'to mark this item as sold. Clicking on "Proceed" will redirect you to '
            'the respective chat, if there is an open deal for this item.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _redirectToChat(post);
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
      );
    } else if (!post.hasAcceptedOffer) {
      // No open deals
      _showAlertDialog(
        'No Open Deals',
        'Currently there are no open deals for this post.',
      );
    } else {
      // Has accepted offer - mark as sold
      setState(() {
        post.isSold = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${post.title} marked as sold'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _redirectToChat(TradePost post) {
    // Navigate to chat screen with this post filter
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redirecting to chat for ${post.title}')),
    );
  }

  void _openPostDetails(TradePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PostDetailScreen(post: post, userItems: []),
    );
  }

  void _navigateToAddPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddPostScreen(),
    );
  }

  void _navigateToOffersInbox(TradePost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigating to offers inbox for ${post.title}')),
    );
  }

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEditScreen(TradePost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPostScreen(editPost: post),
    );
  }
}
