// import 'package:flutter/material.dart';
// import 'package:yempower_app/models/ProductPost.dart';
// import 'package:yempower_app/screens/PostDetailScreen.dart';
// import 'package:yempower_app/screens/tradechatscreen/TradeChatScreen.dart';
// import 'package:yempower_app/screens/TradeBoothScreen.dart';
// import 'package:yempower_app/screens/HamburgerMenuScreen.dart'; // Add this import

// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});

//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> {
//   final List<ProductPost> _posts = [
//     ProductPost(
//       userName: 'Melia K',
//       timeAgo: '2 hr ago',
//       category: 'Furniture',
//       title: 'Sofa',
//       distance: '1.7 Km',
//       returnType: '\$299.99 or Television',
//       barterStatus: 'Open for barter',
//       postType: 'Bartering a product',
//       tradeType: 'Barter',
//       productLocation: '1862 Clarksburg Park Road',
//       postedDate: DateTime(2023, 8, 4),
//       wishListCategory: 'Electronics, Home Appliance',
//       isFavorite: false,
//       isHidden: false,
//       images: [
//         'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
//         'https://images.unsplash.com/photo-1540574163026-643ea20ade25?w=500&q=80',
//         'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?w=500&q=80',
//       ],
//       views: 245,
//       price: '\$299.99',
//       description:
//           'Barely used sofa for sale. Mint condition Orange color velvet upholstery. Teak wood base',
//       transportationOption: 'This item can be transported to desired location',
//       isVerified: true,
//       canClubItems: true,
//     ),
//     ProductPost(
//       userName: 'Charlotte Rose',
//       timeAgo: '4 hr ago',
//       category: 'Plumbing',
//       title: 'Tap repairing',
//       distance: '1.7 Km',
//       returnType: '\$100.00',
//       barterStatus: 'No Barter',
//       postType: 'Looking for a service',
//       tradeType: 'Service',
//       productLocation: 'Hollenberg',
//       postedDate: DateTime.now().subtract(const Duration(hours: 4)),
//       wishListCategory: '',
//       isFavorite: false,
//       isHidden: false,
//       images: [
//         'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
//       ],
//       views: 189,
//       price: '\$100.00',
//       description:
//           'Professional tap repairing service available. Fast and reliable work.',
//       transportationOption: 'Service at your location',
//       isVerified: true,
//       canClubItems: false,
//     ),
//     ProductPost(
//       userName: 'Andrew Danny',
//       timeAgo: '5 hr ago',
//       category: 'Electronics',
//       title: 'Television',
//       distance: '1.5 Km',
//       returnType: 'Home Appliance',
//       barterStatus: 'Open for barter',
//       postType: 'Bartering a product',
//       tradeType: 'Barter',
//       productLocation: 'Kansas City',
//       postedDate: DateTime.now().subtract(const Duration(hours: 5)),
//       wishListCategory: 'Home Appliance, Furniture',
//       isFavorite: false,
//       isHidden: false,
//       images: [
//         'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=500&q=80',
//         'https://images.unsplash.com/photo-1622925566273-6a5d3c5d6c3a?w=500&q=80',
//       ],
//       views: 312,
//       price: '',
//       description:
//           '55" Smart TV with 4K resolution. Excellent condition, includes all accessories.',
//       transportationOption: 'Pickup only',
//       isVerified: false,
//       canClubItems: true,
//     ),
//     ProductPost(
//       userName: 'Sarah Johnson',
//       timeAgo: '1 day ago',
//       category: 'Electronics',
//       title: 'iPhone 13 Pro',
//       distance: '2.3 Km',
//       returnType: 'Laptop or \$800',
//       barterStatus: 'Open for barter',
//       postType: 'Bartering a product',
//       tradeType: 'Barter',
//       productLocation: 'Downtown',
//       postedDate: DateTime.now().subtract(const Duration(days: 1)),
//       wishListCategory: 'Electronics',
//       isFavorite: true,
//       isHidden: false,
//       images: [
//         'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=500&q=80',
//       ],
//       views: 189,
//       price: '',
//       description:
//           'iPhone 13 Pro 256GB, excellent condition with original box and accessories.',
//       transportationOption: 'Meetup or shipping available',
//       isVerified: true,
//       canClubItems: true,
//     ),
//   ];

//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();

//   bool _showPushNotificationDialog = false;
//   bool _pushNotificationGranted = false;
//   String _selectedLocation =
//       '1062 Clarksburg Park Road, Hollenberg, Kansas, 66946';
//   bool _useCurrentLocation = true;
//   int _notificationCount = 3;
//   List<NotificationItem> _notifications = [];

//   // Filter states
//   String? _selectedTradeType;
//   String? _selectedPostType;
//   String? _selectedCategory;
//   String? _selectedWishListCategory;
//   double _selectedRadius = 10.0;

//   List<ProductPost> _filteredPosts = [];

//   @override
//   void initState() {
//     super.initState();
//     _filteredPosts = List.from(_posts);
//     _checkFirstTimeUser();
//     _loadNotifications();
//   }

//   void _checkFirstTimeUser() {
//     // Simulating first-time user check
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) {
//         setState(() {
//           _showPushNotificationDialog = true;
//         });
//       }
//     });
//   }

//   void _loadNotifications() {
//     _notifications = [
//       NotificationItem(
//         message: 'New message from Andrew Danny regarding Television',
//         date: DateTime.now().subtract(const Duration(minutes: 30)),
//         type: 'message',
//       ),
//       NotificationItem(
//         message: 'Your subscription will expire in 3 days',
//         date: DateTime.now().subtract(const Duration(hours: 2)),
//         type: 'subscription',
//       ),
//       NotificationItem(
//         message: 'Sarah Johnson liked your post',
//         date: DateTime.now().subtract(const Duration(hours: 5)),
//         type: 'like',
//       ),
//       NotificationItem(
//         message: 'New product matching your wishlist: Gaming Laptop',
//         date: DateTime.now().subtract(const Duration(days: 1)),
//         type: 'wishlist',
//       ),
//     ];
//   }

//   void _handlePushNotificationPermission(bool granted) {
//     setState(() {
//       _pushNotificationGranted = granted;
//       _showPushNotificationDialog = false;
//     });

//     if (granted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Notifications enabled! You will now receive alerts for all activities.',
//           ),
//           duration: Duration(seconds: 3),
//         ),
//       );
//     }
//   }

//   void _applyFilters() {
//     setState(() {
//       _filteredPosts = _posts.where((post) {
//         // Filter by trade type
//         if (_selectedTradeType != null) {
//           if (_selectedTradeType == 'Barter' && post.tradeType != 'Barter') {
//             return false;
//           }
//           if (_selectedTradeType == 'Sales' &&
//               post.tradeType != 'Service' &&
//               post.price.isEmpty) {
//             return false;
//           }
//         }

//         // Filter by post type
//         if (_selectedPostType != null) {
//           if (_selectedPostType == 'Looking for a product/service' &&
//               !post.postType.contains('Looking for')) {
//             return false;
//           }
//           if (_selectedPostType == 'Barter/selling a product/service' &&
//               !post.postType.contains('Barter') &&
//               !post.postType.contains('Selling')) {
//             return false;
//           }
//         }

//         // Filter by category
//         if (_selectedCategory != null && post.category != _selectedCategory) {
//           return false;
//         }

//         // Filter by wishlist category (only for barter)
//         if (_selectedTradeType == 'Barter' &&
//             _selectedWishListCategory != null &&
//             post.wishListCategory.isNotEmpty) {
//           if (!post.wishListCategory.contains(_selectedWishListCategory!)) {
//             return false;
//           }
//         }

//         // Filter by distance (simplified)
//         final distance = double.tryParse(post.distance.split(' ')[0]) ?? 0;
//         if (distance > _selectedRadius) {
//           return false;
//         }

//         // Filter out hidden posts
//         if (post.isHidden) {
//           return false;
//         }

//         return true;
//       }).toList();
//     });
//   }

//   void _clearAllFilters() {
//     setState(() {
//       _selectedTradeType = null;
//       _selectedPostType = null;
//       _selectedCategory = null;
//       _selectedWishListCategory = null;
//       _selectedRadius = 10.0;
//       _filteredPosts = List.from(_posts);
//     });
//   }

//   void _toggleFavorite(ProductPost post) {
//     setState(() {
//       final index = _posts.indexWhere((p) => p.title == post.title);
//       if (index != -1) {
//         _posts[index].isFavorite = !_posts[index].isFavorite;
//         _filteredPosts = List.from(_posts);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               _posts[index].isFavorite
//                   ? '${post.title} added to favorites'
//                   : '${post.title} removed from favorites',
//             ),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     });
//   }

//   void _hidePost(ProductPost post) {
//     setState(() {
//       final index = _posts.indexWhere((p) => p.title == post.title);
//       if (index != -1) {
//         _posts[index].isHidden = true;
//         _filteredPosts.removeWhere((p) => p.title == post.title);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('${post.title} has been hidden from your feed'),
//             duration: const Duration(seconds: 2),
//           ),
//         );
//       }
//     });
//   }

//   void _reportPost(ProductPost post, String reason) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Report Submitted'),
//         content: Text(
//           'You have reported "${post.title}" for: $reason\n\nOur team will review this post within 24 hours.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showLocationOptions() {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.my_location, color: Colors.blue),
//               title: const Text('Use My Current Location'),
//               subtitle: const Text(
//                 'Browse posts based on your current location',
//               ),
//               onTap: () {
//                 setState(() {
//                   _useCurrentLocation = true;
//                   _selectedLocation = 'Current Location';
//                 });
//                 Navigator.pop(context);

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Using your current location'),
//                     duration: const Duration(seconds: 2),
//                   ),
//                 );
//               },
//             ),
//             const Divider(),
//             ListTile(
//               leading: const Icon(Icons.search, color: Colors.green),
//               title: const Text('Search Location'),
//               subtitle: const Text('Search for any location'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showLocationSearch();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showLocationSearch() {
//     _locationController.clear();
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Search Location'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: _locationController,
//               decoration: const InputDecoration(
//                 hintText: 'Enter city, state, or address...',
//                 border: OutlineInputBorder(),
//                 prefixIcon: Icon(Icons.search),
//               ),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Popular Locations:',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             Wrap(
//               spacing: 8,
//               children: [
//                 Chip(
//                   label: const Text('New York'),
//                   onDeleted: () {
//                     setState(() {
//                       _selectedLocation = 'New York, NY';
//                       _useCurrentLocation = false;
//                     });
//                     Navigator.pop(context);
//                   },
//                 ),
//                 Chip(
//                   label: const Text('Los Angeles'),
//                   onDeleted: () {
//                     setState(() {
//                       _selectedLocation = 'Los Angeles, CA';
//                       _useCurrentLocation = false;
//                     });
//                     Navigator.pop(context);
//                   },
//                 ),
//                 Chip(
//                   label: const Text('Chicago'),
//                   onDeleted: () {
//                     setState(() {
//                       _selectedLocation = 'Chicago, IL';
//                       _useCurrentLocation = false;
//                     });
//                     Navigator.pop(context);
//                   },
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (_locationController.text.isNotEmpty) {
//                 setState(() {
//                   _selectedLocation = _locationController.text;
//                   _useCurrentLocation = false;
//                 });
//                 Navigator.pop(context);

//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                       'Location set to: ${_locationController.text}',
//                     ),
//                     duration: const Duration(seconds: 2),
//                   ),
//                 );
//               }
//             },
//             child: const Text('Apply'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showNotificationScreen() {
//     // Reset notification count when viewing notifications
//     setState(() {
//       _notificationCount = 0;
//     });

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) => NotificationScreen(
//         notifications: _notifications,
//         onSubscribe: () {
//           Navigator.pop(context);
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Redirecting to subscription screen...'),
//               duration: const Duration(seconds: 2),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   void _showFilterDialog() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) => FilterScreen(
//         selectedTradeType: _selectedTradeType,
//         selectedPostType: _selectedPostType,
//         selectedCategory: _selectedCategory,
//         selectedWishListCategory: _selectedWishListCategory,
//         selectedRadius: _selectedRadius,
//         onApply: (tradeType, postType, category, wishListCategory, radius) {
//           setState(() {
//             _selectedTradeType = tradeType;
//             _selectedPostType = postType;
//             _selectedCategory = category;
//             _selectedWishListCategory = wishListCategory;
//             _selectedRadius = radius;
//           });
//           _applyFilters();
//           Navigator.pop(context);
//         },
//         onClear: () {
//           _clearAllFilters();
//           Navigator.pop(context);
//         },
//       ),
//     );
//   }

//   void _showPostOptions(ProductPost post) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: Icon(
//                 post.isFavorite ? Icons.favorite : Icons.favorite_border,
//                 color: post.isFavorite ? Colors.red : Colors.grey,
//               ),
//               title: Text(
//                 post.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
//               ),
//               onTap: () {
//                 _toggleFavorite(post);
//                 Navigator.pop(context);
//               },
//             ),
//             const Divider(height: 1),
//             ListTile(
//               leading: const Icon(Icons.visibility_off, color: Colors.grey),
//               title: const Text('Hide Post'),
//               onTap: () {
//                 _hidePost(post);
//                 Navigator.pop(context);
//               },
//             ),
//             const Divider(height: 1),
//             ListTile(
//               leading: const Icon(Icons.report, color: Colors.orange),
//               title: const Text('Report Post'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _showReportDialog(post);
//               },
//             ),
//             const SizedBox(height: 20),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.grey[200],
//                   foregroundColor: Colors.black,
//                 ),
//                 child: const Text('Cancel'),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showReportDialog(ProductPost post) {
//     TextEditingController reportController = TextEditingController();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Report Post'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('Please provide reason for reporting this post:'),
//             const SizedBox(height: 10),
//             TextField(
//               controller: reportController,
//               decoration: const InputDecoration(
//                 hintText: 'Enter reason...',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               'Common reasons:',
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),
//             Wrap(
//               spacing: 8,
//               children: [
//                 FilterChip(
//                   label: const Text('Spam'),
//                   onSelected: (_) => reportController.text = 'Spam',
//                 ),
//                 FilterChip(
//                   label: const Text('Inappropriate'),
//                   onSelected: (_) =>
//                       reportController.text = 'Inappropriate content',
//                 ),
//                 FilterChip(
//                   label: const Text('Wrong category'),
//                   onSelected: (_) => reportController.text = 'Wrong category',
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (reportController.text.isNotEmpty) {
//                 _reportPost(post, reportController.text);
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text('Submit Report'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _performSearch(String query) {
//     if (query.isEmpty) {
//       setState(() {
//         _filteredPosts = List.from(_posts);
//       });
//       return;
//     }

//     setState(() {
//       _filteredPosts = _posts.where((post) {
//         return post.title.toLowerCase().contains(query.toLowerCase()) ||
//             post.category.toLowerCase().contains(query.toLowerCase()) ||
//             post.userName.toLowerCase().contains(query.toLowerCase()) ||
//             post.postType.toLowerCase().contains(query.toLowerCase());
//       }).toList();
//     });
//   }

//   String _formatDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inMinutes < 60) {
//       return '${difference.inMinutes} minutes ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours} hours ago';
//     } else {
//       return '${difference.inDays} days ago';
//     }
//   }

//   // Navigate to Hamburger Menu
//   void _navigateToHamburgerMenu() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const HamburgerMenuScreen()),
//     );
//   }

//   // Navigate to Trade Chat Screen
//   void _navigateToTradeChat() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const TradeChatScreen()),
//     );
//   }

//   // Navigate to Trade Booth Screen
//   void _navigateToTradeBooth() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => const TradeBoothScreen()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF7F8FF),
//       body: SafeArea(
//         child: Stack(
//           children: [
//             Column(
//               children: [
//                 _buildHeader(),
//                 _buildLocationRow(),
//                 _buildSearchBar(),
//                 Expanded(
//                   child: _filteredPosts.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               const Icon(
//                                 Icons.search_off,
//                                 size: 64,
//                                 color: Colors.grey,
//                               ),
//                               const SizedBox(height: 16),
//                               const Text(
//                                 'No posts found',
//                                 style: TextStyle(
//                                   color: Colors.grey,
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               const Text(
//                                 'Try changing your filters or search terms',
//                                 style: TextStyle(color: Colors.grey),
//                               ),
//                               const SizedBox(height: 16),
//                               ElevatedButton(
//                                 onPressed: _clearAllFilters,
//                                 child: const Text('Clear All Filters'),
//                               ),
//                             ],
//                           ),
//                         )
//                       : ListView.builder(
//                           padding: const EdgeInsets.symmetric(horizontal: 16),
//                           itemCount: _filteredPosts.length + 1,
//                           itemBuilder: (context, index) {
//                             if (index == 0) {
//                               return Padding(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 16,
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment:
//                                       MainAxisAlignment.spaceBetween,
//                                   children: [
//                                     const Text(
//                                       'Near You',
//                                       style: TextStyle(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     if (_selectedTradeType != null ||
//                                         _selectedPostType != null ||
//                                         _selectedCategory != null)
//                                       Chip(
//                                         label: const Text('Filters Active'),
//                                         backgroundColor: Colors.blue[50],
//                                         deleteIcon: const Icon(
//                                           Icons.close,
//                                           size: 16,
//                                         ),
//                                         onDeleted: _clearAllFilters,
//                                       ),
//                                   ],
//                                 ),
//                               );
//                             }
//                             return _buildProductCard(_filteredPosts[index - 1]);
//                           },
//                         ),
//                 ),
//               ],
//             ),

//             // Push Notification Permission Dialog
//             if (_showPushNotificationDialog) _buildPushNotificationDialog(),
//           ],
//         ),
//       ),
//       bottomNavigationBar: _buildBottomNav(),
//     );
//   }

//   Widget _buildPushNotificationDialog() {
//     return Container(
//       color: Colors.black54,
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(20),
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 20,
//                 offset: const Offset(0, 10),
//               ),
//             ],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.notifications_active,
//                 size: 60,
//                 color: Colors.blue,
//               ),
//               const SizedBox(height: 20),
//               const Text(
//                 'Enable Push Notifications',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 10),
//                 child: Text(
//                   'Receive alerts for all platform activities including messages, trades, and updates.',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(color: Colors.grey, fontSize: 14),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => _handlePushNotificationPermission(false),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text('Not Now'),
//                     ),
//                   ),
//                   const SizedBox(width: 10),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () => _handlePushNotificationPermission(true),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                       ),
//                       child: const Text(
//                         'Allow',
//                         style: TextStyle(color: Colors.white),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildHeader() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: _navigateToHamburgerMenu,
//             child: Container(
//               width: 44,
//               height: 44,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.blue, width: 2),
//               ),
//               child: const CircleAvatar(
//                 radius: 20,
//                 backgroundImage: NetworkImage(
//                   'https://i.pravatar.cc/150?img=11',
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           const Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Hello James',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//                 ),
//                 Text(
//                   'Welcome to YemPower',
//                   style: TextStyle(color: Colors.grey, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           Stack(
//             children: [
//               IconButton(
//                 icon: Container(
//                   padding: const EdgeInsets.all(8),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade50,
//                     shape: BoxShape.circle,
//                   ),
//                   child: const Icon(
//                     Icons.notifications_none_outlined,
//                     color: Colors.blue,
//                     size: 24,
//                   ),
//                 ),
//                 onPressed: _showNotificationScreen,
//               ),
//               if (_notificationCount > 0)
//                 Positioned(
//                   right: 10,
//                   top: 10,
//                   child: Container(
//                     padding: const EdgeInsets.all(4),
//                     decoration: const BoxDecoration(
//                       color: Colors.red,
//                       shape: BoxShape.circle,
//                     ),
//                     constraints: const BoxConstraints(
//                       minWidth: 18,
//                       minHeight: 18,
//                     ),
//                     child: Text(
//                       '$_notificationCount',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//           const SizedBox(width: 8),
//           GestureDetector(
//             onTap: _navigateToHamburgerMenu,
//             child: Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: const Icon(Icons.menu, size: 24, color: Colors.grey),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLocationRow() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: InkWell(
//         onTap: _showLocationOptions,
//         borderRadius: BorderRadius.circular(10),
//         child: Container(
//           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: Colors.grey.shade200),
//           ),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.location_on_outlined,
//                 size: 18,
//                 color: Colors.blue.shade700,
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   _selectedLocation,
//                   style: const TextStyle(fontSize: 14, color: Colors.black87),
//                   overflow: TextOverflow.ellipsis,
//                   maxLines: 1,
//                 ),
//               ),
//               Icon(
//                 Icons.keyboard_arrow_down,
//                 size: 20,
//                 color: Colors.grey.shade600,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           Expanded(
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 10,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 onChanged: _performSearch,
//                 decoration: InputDecoration(
//                   hintText: 'Search products, services, categories...',
//                   hintStyle: const TextStyle(color: Colors.grey),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 14,
//                   ),
//                   prefixIcon: const Icon(Icons.search, color: Colors.grey),
//                   suffixIcon: _searchController.text.isNotEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.close, color: Colors.grey),
//                           onPressed: () {
//                             _searchController.clear();
//                             _performSearch('');
//                           },
//                         )
//                       : null,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(15),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.05),
//                   blurRadius: 10,
//                   offset: const Offset(0, 4),
//                 ),
//               ],
//             ),
//             child: IconButton(
//               icon: const Icon(Icons.tune, color: Colors.grey),
//               onPressed: _showFilterDialog,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductCard(ProductPost post) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => PostDetailScreen(post: post, userItems: []),
//           ),
//         );
//       },
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 20),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.04),
//               blurRadius: 15,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Stack(
//               children: [
//                 // Image carousel
//                 SizedBox(
//                   height: 200,
//                   child: Stack(
//                     children: [
//                       PageView.builder(
//                         itemCount: post.images.length,
//                         itemBuilder: (context, index) {
//                           return ClipRRect(
//                             borderRadius: const BorderRadius.vertical(
//                               top: Radius.circular(24),
//                             ),
//                             child: Image.network(
//                               post.images[index],
//                               height: 200,
//                               width: double.infinity,
//                               fit: BoxFit.cover,
//                               loadingBuilder:
//                                   (context, child, loadingProgress) {
//                                     if (loadingProgress == null) return child;
//                                     return Container(
//                                       height: 200,
//                                       width: double.infinity,
//                                       color: Colors.grey[200],
//                                       child: const Center(
//                                         child: CircularProgressIndicator(),
//                                       ),
//                                     );
//                                   },
//                             ),
//                           );
//                         },
//                       ),

//                       // Image indicator
//                       if (post.images.length > 1)
//                         Positioned(
//                           bottom: 10,
//                           right: 10,
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 12,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: Colors.black.withOpacity(0.6),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Text(
//                               '1/${post.images.length}',
//                               style: const TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                 ),

//                 // Post Type Badge
//                 if (post.postType.contains('Looking for'))
//                   Positioned(
//                     top: 15,
//                     left: 0,
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 16,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFD32F2F),
//                         borderRadius: const BorderRadius.only(
//                           topRight: Radius.circular(12),
//                           bottomRight: Radius.circular(12),
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.2),
//                             blurRadius: 4,
//                             offset: const Offset(2, 0),
//                           ),
//                         ],
//                       ),
//                       child: Text(
//                         post.postType,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 12,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                   ),

//                 // 3Dot Menu Button
//                 Positioned(
//                   top: 15,
//                   right: 15,
//                   child: InkWell(
//                     onTap: () => _showPostOptions(post),
//                     borderRadius: BorderRadius.circular(20),
//                     child: Container(
//                       width: 36,
//                       height: 36,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         shape: BoxShape.circle,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.1),
//                             blurRadius: 8,
//                             offset: const Offset(0, 2),
//                           ),
//                         ],
//                       ),
//                       child: const Icon(Icons.more_horiz, color: Colors.grey),
//                     ),
//                   ),
//                 ),

//                 // User info overlay
//                 Positioned(
//                   bottom: 12,
//                   left: 12,
//                   right: 12,
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.black.withOpacity(0.5),
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Row(
//                       children: [
//                         CircleAvatar(
//                           radius: 18,
//                           backgroundImage: NetworkImage(
//                             'https://i.pravatar.cc/150?img=${post.userName.hashCode % 70}',
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 post.userName,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 14,
//                                 ),
//                               ),
//                               Text(
//                                 _formatDate(post.postedDate),
//                                 style: const TextStyle(
//                                   color: Colors.white70,
//                                   fontSize: 11,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         if (post.isFavorite)
//                           const Icon(
//                             Icons.favorite,
//                             color: Colors.red,
//                             size: 20,
//                           ),
//                         const SizedBox(width: 8),
//                         Text(
//                           post.timeAgo,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             // Post details
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 12,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: Colors.blue.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Text(
//                           post.category,
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.blue.shade800,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 6,
//                         ),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFE8EAF6),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Row(
//                           children: [
//                             const Icon(
//                               Icons.sync_alt,
//                               size: 14,
//                               color: Color(0xFF3F51B5),
//                             ),
//                             const SizedBox(width: 4),
//                             Text(
//                               post.barterStatus,
//                               style: const TextStyle(
//                                 fontSize: 11,
//                                 color: Color(0xFF3F51B5),
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 12),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         post.title,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       if (_useCurrentLocation || _selectedLocation.isNotEmpty)
//                         Text(
//                           post.distance,
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                           ),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 6),
//                   Text(
//                     'In Return: ${post.returnType}',
//                     style: const TextStyle(
//                       color: Colors.black87,
//                       fontSize: 14,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (post.wishListCategory.isNotEmpty)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 4),
//                       child: Text(
//                         'Wish List: ${post.wishListCategory}',
//                         style: const TextStyle(
//                           color: Colors.green,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildBottomNav() {
//     return Container(
//       height: 85,
//       padding: const EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
//         ],
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         clipBehavior: Clip.none,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceAround,
//             children: [
//               _navItem(Icons.home_filled, 'Marketplace', true),
//               const SizedBox(width: 60),
//               // Chat navigation item
//               GestureDetector(
//                 onTap: _navigateToTradeChat,
//                 child: _navItem(
//                   Icons.chat_bubble_outline,
//                   'Chat',
//                   false,
//                   badge: 1,
//                 ),
//               ),
//             ],
//           ),
//           Positioned(
//             top: -20,
//             child: GestureDetector(
//               onTap: _navigateToTradeBooth,
//               child: Column(
//                 children: [
//                   Container(
//                     height: 55,
//                     width: 55,
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF2E5BFF),
//                       borderRadius: BorderRadius.circular(18),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.blue.withOpacity(0.4),
//                           blurRadius: 12,
//                           offset: const Offset(0, 6),
//                         ),
//                       ],
//                     ),
//                     child: const Icon(
//                       Icons.swap_horiz,
//                       color: Colors.white,
//                       size: 32,
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Trade booth',
//                     style: TextStyle(
//                       fontSize: 11,
//                       color: Colors.grey,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _navItem(IconData icon, String label, bool isActive, {int badge = 0}) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Stack(
//           clipBehavior: Clip.none,
//           children: [
//             Icon(
//               icon,
//               color: isActive ? Colors.black : Colors.grey.shade400,
//               size: 28,
//             ),
//             if (badge > 0)
//               Positioned(
//                 right: -4,
//                 top: -4,
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: const BoxDecoration(
//                     color: Color(0xFF2E5BFF),
//                     shape: BoxShape.circle,
//                   ),
//                   child: Text(
//                     '$badge',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 9,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//         const SizedBox(height: 4),
//         Text(
//           label,
//           style: TextStyle(
//             color: isActive ? Colors.black : Colors.grey.shade400,
//             fontSize: 11,
//             fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ],
//     );
//   }
// }

// class FilterScreen extends StatefulWidget {
//   final String? selectedTradeType;
//   final String? selectedPostType;
//   final String? selectedCategory;
//   final String? selectedWishListCategory;
//   final double selectedRadius;
//   final Function(String?, String?, String?, String?, double) onApply;
//   final VoidCallback onClear;

//   const FilterScreen({
//     Key? key,
//     required this.selectedTradeType,
//     required this.selectedPostType,
//     required this.selectedCategory,
//     required this.selectedWishListCategory,
//     required this.selectedRadius,
//     required this.onApply,
//     required this.onClear,
//   }) : super(key: key);

//   @override
//   _FilterScreenState createState() => _FilterScreenState();
// }

// class _FilterScreenState extends State<FilterScreen> {
//   late String? _selectedTradeType;
//   late String? _selectedPostType;
//   late String? _selectedCategory;
//   late String? _selectedWishListCategory;
//   late double _selectedRadius;

//   final List<String> _tradeTypes = ['Barter', 'Sales'];
//   final List<String> _postTypes = [
//     'Looking for a product/service',
//     'Barter/selling a product/service',
//   ];
//   final List<String> _categories = ['Furniture', 'Plumbing', 'Electronics'];
//   final List<String> _wishListCategories = [
//     'Electronics',
//     'Home Appliance',
//     'Furniture',
//     'Home Appliance, Furniture',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _selectedTradeType = widget.selectedTradeType;
//     _selectedPostType = widget.selectedPostType;
//     _selectedCategory = widget.selectedCategory;
//     _selectedWishListCategory = widget.selectedWishListCategory;
//     _selectedRadius = widget.selectedRadius;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       height: MediaQuery.of(context).size.height * 0.8,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Filters',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           Expanded(
//             child: ListView(
//               children: [
//                 // Trade Type Filter
//                 _buildFilterSection(
//                   title: 'Trade Type',
//                   options: _tradeTypes,
//                   selectedValue: _selectedTradeType,
//                   onChanged: (value) {
//                     setState(() {
//                       _selectedTradeType = value;
//                       if (value != 'Barter') {
//                         _selectedWishListCategory = null;
//                       }
//                     });
//                   },
//                 ),

//                 // Post Type Filter
//                 _buildFilterSection(
//                   title: 'Post Type',
//                   options: _postTypes,
//                   selectedValue: _selectedPostType,
//                   onChanged: (value) {
//                     setState(() {
//                       _selectedPostType = value;
//                     });
//                   },
//                 ),

//                 // Category Filter
//                 _buildFilterSection(
//                   title: 'Category',
//                   options: _categories,
//                   selectedValue: _selectedCategory,
//                   onChanged: (value) {
//                     setState(() {
//                       _selectedCategory = value;
//                     });
//                   },
//                 ),

//                 // Wish List Filter (only shown when Barter is selected)
//                 if (_selectedTradeType == 'Barter')
//                   _buildFilterSection(
//                     title: 'Wish List Category',
//                     options: _wishListCategories,
//                     selectedValue: _selectedWishListCategory,
//                     onChanged: (value) {
//                       setState(() {
//                         _selectedWishListCategory = value;
//                       });
//                     },
//                   ),

//                 // Location Radius Filter
//                 _buildRadiusFilter(),
//               ],
//             ),
//           ),

//           // Action Buttons
//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () {
//                     widget.onClear();
//                     Navigator.pop(context);
//                   },
//                   child: const Text('Clear All'),
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () {
//                     widget.onApply(
//                       _selectedTradeType,
//                       _selectedPostType,
//                       _selectedCategory,
//                       _selectedWishListCategory,
//                       _selectedRadius,
//                     );
//                   },
//                   child: const Text('Apply'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildFilterSection({
//     required String title,
//     required List<String> options,
//     required String? selectedValue,
//     required ValueChanged<String?> onChanged,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 10),
//         Wrap(
//           spacing: 8,
//           children: options.map((option) {
//             final isSelected = selectedValue == option;
//             return FilterChip(
//               label: Text(option),
//               selected: isSelected,
//               onSelected: (selected) {
//                 onChanged(selected ? option : null);
//               },
//               selectedColor: Colors.blue.shade100,
//               checkmarkColor: Colors.blue,
//             );
//           }).toList(),
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }

//   Widget _buildRadiusFilter() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text(
//           'Location Range',
//           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 10),
//         Text('Within ${_selectedRadius.toStringAsFixed(0)} km'),
//         Slider(
//           value: _selectedRadius,
//           min: 1,
//           max: 50,
//           divisions: 49,
//           onChanged: (value) {
//             setState(() {
//               _selectedRadius = value;
//             });
//           },
//           label: '${_selectedRadius.toStringAsFixed(0)} km',
//         ),
//         const SizedBox(height: 20),
//       ],
//     );
//   }
// }

// class NotificationScreen extends StatelessWidget {
//   final List<NotificationItem> notifications;
//   final VoidCallback onSubscribe;

//   const NotificationScreen({
//     Key? key,
//     required this.notifications,
//     required this.onSubscribe,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       height: MediaQuery.of(context).size.height * 0.8,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Notifications',
//             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 20),
//           Expanded(
//             child: notifications.isEmpty
//                 ? const Center(
//                     child: Text(
//                       'No notifications',
//                       style: TextStyle(color: Colors.grey, fontSize: 16),
//                     ),
//                   )
//                 : ListView.builder(
//                     itemCount: notifications.length,
//                     itemBuilder: (context, index) {
//                       final notification = notifications[index];
//                       return _buildNotificationItem(notification, index == 0);
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildNotificationItem(NotificationItem notification, bool isLatest) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: isLatest ? Colors.blue.shade50 : Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade200),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             _getNotificationIcon(notification.type),
//             color: _getNotificationColor(notification.type),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   notification.message,
//                   style: const TextStyle(fontSize: 14),
//                 ),
//                 const SizedBox(height: 5),
//                 Text(
//                   _formatNotificationDate(notification.date),
//                   style: const TextStyle(fontSize: 12, color: Colors.grey),
//                 ),
//                 if (notification.type == 'subscription')
//                   Padding(
//                     padding: const EdgeInsets.only(top: 10),
//                     child: ElevatedButton(
//                       onPressed: onSubscribe,
//                       child: const Text('Subscribe Now'),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   IconData _getNotificationIcon(String type) {
//     switch (type) {
//       case 'message':
//         return Icons.message;
//       case 'subscription':
//         return Icons.payment;
//       case 'like':
//         return Icons.favorite;
//       case 'wishlist':
//         return Icons.card_giftcard;
//       default:
//         return Icons.notifications;
//     }
//   }

//   Color _getNotificationColor(String type) {
//     switch (type) {
//       case 'message':
//         return Colors.blue;
//       case 'subscription':
//         return Colors.orange;
//       case 'like':
//         return Colors.red;
//       case 'wishlist':
//         return Colors.green;
//       default:
//         return Colors.grey;
//     }
//   }

//   String _formatNotificationDate(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inMinutes < 60) {
//       return '${difference.inMinutes} min ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours} hours ago';
//     } else {
//       return '${difference.inDays} days ago';
//     }
//   }
// }

// class NotificationItem {
//   final String message;
//   final DateTime date;
//   final String type;

//   NotificationItem({
//     required this.message,
//     required this.date,
//     required this.type,
//   });
// }

import 'package:flutter/material.dart';
import 'package:yempower_app/models/ProductPost.dart';
import 'package:yempower_app/payment/SubscriptionScreen.dart';
import 'package:yempower_app/screens/PostDetailScreen.dart';
import 'package:yempower_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:yempower_app/screens/TradeBoothScreen.dart';
import 'package:yempower_app/screens/HamburgerMenuScreen.dart';
import 'package:yempower_app/screens/TradeHistoryScreen.dart';
import 'package:yempower_app/screens/NotificationsScreen.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    ProductPost(
      userName: 'Sarah Johnson',
      timeAgo: '1 day ago',
      category: 'Electronics',
      title: 'iPhone 13 Pro',
      distance: '2.3 Km',
      returnType: 'Laptop or \$800',
      barterStatus: 'Open for barter',
      postType: 'Bartering a product',
      tradeType: 'Barter',
      productLocation: 'Downtown',
      postedDate: DateTime.now().subtract(const Duration(days: 1)),
      wishListCategory: 'Electronics',
      isFavorite: true,
      isHidden: false,
      images: [
        'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=500&q=80',
      ],
      views: 189,
      price: '',
      description:
          'iPhone 13 Pro 256GB, excellent condition with original box and accessories.',
      transportationOption: 'Meetup or shipping available',
      isVerified: true,
      canClubItems: true,
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  bool _showPushNotificationDialog = false;
  bool _pushNotificationGranted = false;
  String _selectedLocation =
      '1062 Clarksburg Park Road, Hollenberg, Kansas, 66946';
  bool _useCurrentLocation = true;
  int _notificationCount = 3;
  List<AppNotification> _notifications = [];

  // Filter states
  String? _selectedTradeType;
  String? _selectedPostType;
  String? _selectedCategory;
  String? _selectedWishListCategory;
  double _selectedRadius = 10.0;

  List<ProductPost> _filteredPosts = [];

  @override
  void initState() {
    super.initState();
    _filteredPosts = List.from(_posts);
    _checkFirstTimeUser();
    _loadNotifications();
  }

  void _checkFirstTimeUser() {
    // Simulating first-time user check
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showPushNotificationDialog = true;
        });
      }
    });
  }

  void _loadNotifications() {
    _notifications = [
      AppNotification(
        id: '1',
        type: 'message',
        title: 'New Message',
        message: 'Andrew Danny sent you a new message regarding Television',
        date: DateTime.now().subtract(const Duration(minutes: 30)),
        read: false,
        action: 'view_chat',
        data: {'userId': 'andrew123', 'postId': 'television456'},
      ),
      AppNotification(
        id: '2',
        type: 'subscription',
        title: 'Subscription Reminder',
        message:
            'Your subscription will expire in 3 days. Renew now to continue enjoying premium features.',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        read: false,
        action: 'subscribe',
      ),
      AppNotification(
        id: '3',
        type: 'like',
        title: 'Post Liked',
        message: 'Sarah Johnson liked your post "iPhone 13 Pro"',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        read: true,
        action: 'view_post',
        data: {'postId': 'iphone789'},
      ),
      AppNotification(
        id: '4',
        type: 'wishlist',
        title: 'Wishlist Match',
        message: 'New product matching your wishlist: Gaming Laptop',
        date: DateTime.now().subtract(const Duration(days: 1)),
        read: true,
        action: 'view_product',
        data: {'productId': 'gaming_laptop123'},
      ),
      AppNotification(
        id: '5',
        type: 'deal_completed',
        title: 'Deal Completed',
        message: 'Your trade for "Books" has been successfully completed',
        date: DateTime.now().subtract(const Duration(days: 2)),
        read: true,
        action: 'view_trade',
        data: {'tradeId': 'trade123'},
      ),
      AppNotification(
        id: '6',
        type: 'offer_accepted',
        title: 'Offer Accepted',
        message: 'Your offer for "Sofa" has been accepted by Melia K',
        date: DateTime.now().subtract(const Duration(days: 3)),
        read: true,
        action: 'view_chat',
        data: {'userId': 'melia456', 'offerId': 'offer789'},
      ),
      AppNotification(
        id: '7',
        type: 'subscription_expired',
        title: 'Subscription Expired',
        message:
            'Your subscription has expired. Subscribe now to regain access to all features.',
        date: DateTime.now().subtract(const Duration(days: 5)),
        read: true,
        action: 'subscribe',
      ),
    ];
  }

  void _handlePushNotificationPermission(bool granted) {
    setState(() {
      _pushNotificationGranted = granted;
      _showPushNotificationDialog = false;
    });

    if (granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Notifications enabled! You will now receive alerts for all activities.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPosts = _posts.where((post) {
        // Filter by trade type
        if (_selectedTradeType != null) {
          if (_selectedTradeType == 'Barter' && post.tradeType != 'Barter') {
            return false;
          }
          if (_selectedTradeType == 'Sales' &&
              post.tradeType != 'Service' &&
              post.price.isEmpty) {
            return false;
          }
        }

        // Filter by post type
        if (_selectedPostType != null) {
          if (_selectedPostType == 'Looking for a product/service' &&
              !post.postType.contains('Looking for')) {
            return false;
          }
          if (_selectedPostType == 'Barter/selling a product/service' &&
              !post.postType.contains('Barter') &&
              !post.postType.contains('Selling')) {
            return false;
          }
        }

        // Filter by category
        if (_selectedCategory != null && post.category != _selectedCategory) {
          return false;
        }

        // Filter by wishlist category (only for barter)
        if (_selectedTradeType == 'Barter' &&
            _selectedWishListCategory != null &&
            post.wishListCategory.isNotEmpty) {
          if (!post.wishListCategory.contains(_selectedWishListCategory!)) {
            return false;
          }
        }

        // Filter by distance (simplified)
        final distance = double.tryParse(post.distance.split(' ')[0]) ?? 0;
        if (distance > _selectedRadius) {
          return false;
        }

        // Filter out hidden posts
        if (post.isHidden) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedTradeType = null;
      _selectedPostType = null;
      _selectedCategory = null;
      _selectedWishListCategory = null;
      _selectedRadius = 10.0;
      _filteredPosts = List.from(_posts);
    });
  }

  void _toggleFavorite(ProductPost post) {
    setState(() {
      final index = _posts.indexWhere((p) => p.title == post.title);
      if (index != -1) {
        _posts[index].isFavorite = !_posts[index].isFavorite;
        _filteredPosts = List.from(_posts);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _posts[index].isFavorite
                  ? '${post.title} added to favorites'
                  : '${post.title} removed from favorites',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _hidePost(ProductPost post) {
    setState(() {
      final index = _posts.indexWhere((p) => p.title == post.title);
      if (index != -1) {
        _posts[index].isHidden = true;
        _filteredPosts.removeWhere((p) => p.title == post.title);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${post.title} has been hidden from your feed'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _reportPost(ProductPost post, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Submitted'),
        content: Text(
          'You have reported "${post.title}" for: $reason\n\nOur team will review this post within 24 hours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.my_location, color: Colors.blue),
              title: const Text('Use My Current Location'),
              subtitle: const Text(
                'Browse posts based on your current location',
              ),
              onTap: () {
                setState(() {
                  _useCurrentLocation = true;
                  _selectedLocation = 'Current Location';
                });
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Using your current location'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.green),
              title: const Text('Search Location'),
              subtitle: const Text('Search for any location'),
              onTap: () {
                Navigator.pop(context);
                _showLocationSearch();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationSearch() {
    _locationController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'Enter city, state, or address...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Popular Locations:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: const Text('New York'),
                  onDeleted: () {
                    setState(() {
                      _selectedLocation = 'New York, NY';
                      _useCurrentLocation = false;
                    });
                    Navigator.pop(context);
                  },
                ),
                Chip(
                  label: const Text('Los Angeles'),
                  onDeleted: () {
                    setState(() {
                      _selectedLocation = 'Los Angeles, CA';
                      _useCurrentLocation = false;
                    });
                    Navigator.pop(context);
                  },
                ),
                Chip(
                  label: const Text('Chicago'),
                  onDeleted: () {
                    setState(() {
                      _selectedLocation = 'Chicago, IL';
                      _useCurrentLocation = false;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_locationController.text.isNotEmpty) {
                setState(() {
                  _selectedLocation = _locationController.text;
                  _useCurrentLocation = false;
                });
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Location set to: ${_locationController.text}',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showNotificationScreen() {
    // Reset notification count when viewing notifications
    setState(() {
      _notificationCount = 0;
      // Mark all as read
      for (var notification in _notifications) {
        notification.read = true;
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationsScreen(
          notifications: _notifications,
          onNotificationTap: _handleNotificationTap,
        ),
      ),
    ).then((value) {
      // Refresh notification count when returning from notifications screen
      setState(() {
        _notificationCount = _notifications.where((n) => !n.read).length;
      });
    });
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => FilterScreen(
        selectedTradeType: _selectedTradeType,
        selectedPostType: _selectedPostType,
        selectedCategory: _selectedCategory,
        selectedWishListCategory: _selectedWishListCategory,
        selectedRadius: _selectedRadius,
        onApply: (tradeType, postType, category, wishListCategory, radius) {
          setState(() {
            _selectedTradeType = tradeType;
            _selectedPostType = postType;
            _selectedCategory = category;
            _selectedWishListCategory = wishListCategory;
            _selectedRadius = radius;
          });
          _applyFilters();
          Navigator.pop(context);
        },
        onClear: () {
          _clearAllFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showPostOptions(ProductPost post) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                post.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: post.isFavorite ? Colors.red : Colors.grey,
              ),
              title: Text(
                post.isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () {
                _toggleFavorite(post);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.grey),
              title: const Text('Hide Post'),
              onTap: () {
                _hidePost(post);
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(post);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                ),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(ProductPost post) {
    TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide reason for reporting this post:'),
            const SizedBox(height: 10),
            TextField(
              controller: reportController,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            const Text(
              'Common reasons:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Spam'),
                  onSelected: (_) => reportController.text = 'Spam',
                ),
                FilterChip(
                  label: const Text('Inappropriate'),
                  onSelected: (_) =>
                      reportController.text = 'Inappropriate content',
                ),
                FilterChip(
                  label: const Text('Wrong category'),
                  onSelected: (_) => reportController.text = 'Wrong category',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reportController.text.isNotEmpty) {
                _reportPost(post, reportController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredPosts = List.from(_posts);
      });
      return;
    }

    setState(() {
      _filteredPosts = _posts.where((post) {
        return post.title.toLowerCase().contains(query.toLowerCase()) ||
            post.category.toLowerCase().contains(query.toLowerCase()) ||
            post.userName.toLowerCase().contains(query.toLowerCase()) ||
            post.postType.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  // Navigate to Hamburger Menu
  void _navigateToHamburgerMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HamburgerMenuScreen()),
    );
  }

  // Navigate to Trade Chat Screen
  void _navigateToTradeChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TradeChatScreen()),
    );
  }

  // Navigate to Trade Booth Screen
  void _navigateToTradeBooth() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TradeBoothScreen()),
    );
  }

  // Handle notification tap
  void _handleNotificationTap(AppNotification notification) {
    // Mark as read
    setState(() {
      notification.read = true;
      _notificationCount = _notifications.where((n) => !n.read).length;
    });

    // Navigate based on action
    switch (notification.action) {
      case 'view_chat':
        _navigateToTradeChat();
        break;

      case 'subscribe':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
        );
        break;

      case 'view_post':
        // Find the post and navigate to detail
        final post = _posts.firstWhere(
          (p) =>
              p.title.contains("iPhone") || p.title.contains("iPhone 13 Pro"),
          orElse: () => _posts.first,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post, userItems: []),
          ),
        );
        break;

      case 'view_product':
        // Navigate to specific product
        final post = _posts.firstWhere(
          (p) => p.category == "Electronics",
          orElse: () => _posts.first,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post, userItems: []),
          ),
        );
        break;

      case 'view_trade':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TradeHistoryScreen()),
        );
        break;

      default:
        // Default action - show notification screen
        _showNotificationScreen();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                _buildLocationRow(),
                _buildSearchBar(),
                Expanded(
                  child: _filteredPosts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No posts found',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Try changing your filters or search terms',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _clearAllFilters,
                                child: const Text('Clear All Filters'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredPosts.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Near You',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_selectedTradeType != null ||
                                        _selectedPostType != null ||
                                        _selectedCategory != null)
                                      Chip(
                                        label: const Text('Filters Active'),
                                        backgroundColor: Colors.blue[50],
                                        deleteIcon: const Icon(
                                          Icons.close,
                                          size: 16,
                                        ),
                                        onDeleted: _clearAllFilters,
                                      ),
                                  ],
                                ),
                              );
                            }
                            return _buildProductCard(_filteredPosts[index - 1]);
                          },
                        ),
                ),
              ],
            ),

            // Push Notification Permission Dialog
            if (_showPushNotificationDialog) _buildPushNotificationDialog(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPushNotificationDialog() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 60,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Enable Push Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'Receive alerts for all platform activities including messages, trades, and updates.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _handlePushNotificationPermission(false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Not Now'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handlePushNotificationPermission(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Allow',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: _navigateToHamburgerMenu,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue, width: 2),
              ),
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=11',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello James',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Welcome to YemPower',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_none_outlined,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                onPressed: _showNotificationScreen,
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _navigateToHamburgerMenu,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.menu, size: 24, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: _showLocationOptions,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedLocation,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _performSearch,
                decoration: InputDecoration(
                  hintText: 'Search products, services, categories...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _performSearch('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.tune, color: Colors.grey),
              onPressed: _showFilterDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: post, userItems: []),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Image carousel
                SizedBox(
                  height: 200,
                  child: Stack(
                    children: [
                      PageView.builder(
                        itemCount: post.images.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                            child: Image.network(
                              post.images[index],
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 200,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  },
                            ),
                          );
                        },
                      ),

                      // Image indicator
                      if (post.images.length > 1)
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '1/${post.images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Post Type Badge
                if (post.postType.contains('Looking for'))
                  Positioned(
                    top: 15,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: Text(
                        post.postType,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // 3Dot Menu Button
                Positioned(
                  top: 15,
                  right: 15,
                  child: InkWell(
                    onTap: () => _showPostOptions(post),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.grey),
                    ),
                  ),
                ),

                // User info overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(
                            'https://i.pravatar.cc/150?img=${post.userName.hashCode % 70}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.userName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                _formatDate(post.postedDate),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (post.isFavorite)
                          const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          post.timeAgo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Post details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EAF6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sync_alt,
                              size: 14,
                              color: Color(0xFF3F51B5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              post.barterStatus,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF3F51B5),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_useCurrentLocation || _selectedLocation.isNotEmpty)
                        Text(
                          post.distance,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'In Return: ${post.returnType}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (post.wishListCategory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Wish List: ${post.wishListCategory}',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
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

  Widget _buildBottomNav() {
    return Container(
      height: 85,
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_filled, 'Marketplace', true),
              const SizedBox(width: 60),
              // Chat navigation item
              GestureDetector(
                onTap: _navigateToTradeChat,
                child: _navItem(
                  Icons.chat_bubble_outline,
                  'Chat',
                  false,
                  badge: 1,
                ),
              ),
            ],
          ),
          Positioned(
            top: -20,
            child: GestureDetector(
              onTap: _navigateToTradeBooth,
              child: Column(
                children: [
                  Container(
                    height: 55,
                    width: 55,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E5BFF),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Trade booth',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isActive, {int badge = 0}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.black : Colors.grey.shade400,
              size: 28,
            ),
            if (badge > 0)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E5BFF),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.grey.shade400,
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class FilterScreen extends StatefulWidget {
  final String? selectedTradeType;
  final String? selectedPostType;
  final String? selectedCategory;
  final String? selectedWishListCategory;
  final double selectedRadius;
  final Function(String?, String?, String?, String?, double) onApply;
  final VoidCallback onClear;

  const FilterScreen({
    Key? key,
    required this.selectedTradeType,
    required this.selectedPostType,
    required this.selectedCategory,
    required this.selectedWishListCategory,
    required this.selectedRadius,
    required this.onApply,
    required this.onClear,
  }) : super(key: key);

  @override
  _FilterScreenState createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late String? _selectedTradeType;
  late String? _selectedPostType;
  late String? _selectedCategory;
  late String? _selectedWishListCategory;
  late double _selectedRadius;

  final List<String> _tradeTypes = ['Barter', 'Sales'];
  final List<String> _postTypes = [
    'Looking for a product/service',
    'Barter/selling a product/service',
  ];
  final List<String> _categories = ['Furniture', 'Plumbing', 'Electronics'];
  final List<String> _wishListCategories = [
    'Electronics',
    'Home Appliance',
    'Furniture',
    'Home Appliance, Furniture',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTradeType = widget.selectedTradeType;
    _selectedPostType = widget.selectedPostType;
    _selectedCategory = widget.selectedCategory;
    _selectedWishListCategory = widget.selectedWishListCategory;
    _selectedRadius = widget.selectedRadius;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                // Trade Type Filter
                _buildFilterSection(
                  title: 'Trade Type',
                  options: _tradeTypes,
                  selectedValue: _selectedTradeType,
                  onChanged: (value) {
                    setState(() {
                      _selectedTradeType = value;
                      if (value != 'Barter') {
                        _selectedWishListCategory = null;
                      }
                    });
                  },
                ),

                // Post Type Filter
                _buildFilterSection(
                  title: 'Post Type',
                  options: _postTypes,
                  selectedValue: _selectedPostType,
                  onChanged: (value) {
                    setState(() {
                      _selectedPostType = value;
                    });
                  },
                ),

                // Category Filter
                _buildFilterSection(
                  title: 'Category',
                  options: _categories,
                  selectedValue: _selectedCategory,
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),

                // Wish List Filter (only shown when Barter is selected)
                if (_selectedTradeType == 'Barter')
                  _buildFilterSection(
                    title: 'Wish List Category',
                    options: _wishListCategories,
                    selectedValue: _selectedWishListCategory,
                    onChanged: (value) {
                      setState(() {
                        _selectedWishListCategory = value;
                      });
                    },
                  ),

                // Location Radius Filter
                _buildRadiusFilter(),
              ],
            ),
          ),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear All'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _selectedTradeType,
                      _selectedPostType,
                      _selectedCategory,
                      _selectedWishListCategory,
                      _selectedRadius,
                    );
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                onChanged(selected ? option : null);
              },
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue,
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildRadiusFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location Range',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text('Within ${_selectedRadius.toStringAsFixed(0)} km'),
        Slider(
          value: _selectedRadius,
          min: 1,
          max: 50,
          divisions: 49,
          onChanged: (value) {
            setState(() {
              _selectedRadius = value;
            });
          },
          label: '${_selectedRadius.toStringAsFixed(0)} km',
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final List<AppNotification> notifications;
  final VoidCallback onSubscribe;

  const NotificationScreen({
    Key? key,
    required this.notifications,
    required this.onSubscribe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: notifications.isEmpty
                ? const Center(
                    child: Text(
                      'No notifications',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return _buildNotificationItem(notification, index == 0);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification, bool isLatest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isLatest ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.message,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatNotificationDate(notification.date),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (notification.type == 'subscription')
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      onPressed: onSubscribe,
                      child: const Text('Subscribe Now'),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'subscription':
        return Icons.payment;
      case 'like':
        return Icons.favorite;
      case 'wishlist':
        return Icons.card_giftcard;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return Colors.blue;
      case 'subscription':
        return Colors.orange;
      case 'like':
        return Colors.red;
      case 'wishlist':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatNotificationDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime date;
  bool read;
  final String action;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    required this.read,
    required this.action,
    this.data,
  });
}
