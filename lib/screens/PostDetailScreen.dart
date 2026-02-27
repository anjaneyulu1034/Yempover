// import 'package:flutter/material.dart';
// import 'package:Yempover_app/models/ProductPostmain.dart';
// import 'package:Yempover_app/screens/OfferDeckScreen.dart';
// import 'package:Yempover_app/services/api_service.dart';
// import 'package:Yempover_app/services/token_service.dart';
// import 'package:Yempover_app/services/trade_chat_service/trade_chat_service.dart';
// import 'package:Yempover_app/utils/loading_widget.dart';

// class PostDetailScreen extends StatefulWidget {
//   final Post post;
//   final List<UserItem> userItems;

//   const PostDetailScreen({
//     super.key,
//     required this.post,
//     required this.userItems,
//   });

//   @override
//   State<PostDetailScreen> createState() => _PostDetailScreenState();
// }

// class _PostDetailScreenState extends State<PostDetailScreen> {
//   final ApiService _apiService = ApiService();
//   final TradeChatService _chatService = TradeChatService();
//   final TokenService _tokenService = TokenService();

//   late Post _post;
//   bool _isLoading = false;
//   bool _isFavorite = false;
//   String? _currentUserId;

//   @override
//   void initState() {
//     super.initState();
//     _post = widget.post;
//     _loadCurrentUser();
//     _loadPostDetails();
//   }

//   Future<void> _loadCurrentUser() async {
//     try {
//       _currentUserId = await _tokenService.getUserId();
//       print('👤 Current user ID: $_currentUserId');
//     } catch (e) {
//       print('❌ Error loading current user: $e');
//     }
//   }

//   Future<void> _loadPostDetails() async {
//     try {
//       setState(() => _isLoading = true);
//       final response = await _apiService.getPostDetail(
//         postId: _post.id,
//         type: _post.type,
//       );
//       setState(() {
//         _post = response.post;
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Failed to load post details: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }

//   // New method to navigate to Offer Deck
//   void _navigateToOfferDeck() {
//     if (_currentUserId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please login to make an offer'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     // Don't allow offering on own post
//     if (_currentUserId == _post.postedById) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('You cannot make an offer on your own post'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) =>
//             OfferDeckScreen(post: _post, currentUserId: _currentUserId!),
//       ),
//     );
//   }

//   void _showUserProfile(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         height: MediaQuery.of(context).size.height * 0.6,
//         child: Column(
//           children: [
//             CircleAvatar(
//               radius: 50,
//               backgroundColor: Colors.grey.shade200,
//               child: _post.postedBy.profileImage != null
//                   ? ClipOval(
//                       child: Image.network(
//                         _post.postedBy.profileImage!,
//                         width: 100,
//                         height: 100,
//                         fit: BoxFit.cover,
//                       ),
//                     )
//                   : Text(
//                       _post.postedBy.firstName.isNotEmpty
//                           ? _post.postedBy.firstName[0]
//                           : 'U',
//                       style: const TextStyle(
//                         fontSize: 36,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               _post.postedBy.fullName,
//               style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Member since ${_formatDate(_post.postedDate.subtract(const Duration(days: 365)))}',
//               style: const TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 20),

//             // User Stats
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 _buildStatItem('Posts', '24'),
//                 _buildStatItem('Rating', '4.8'),
//                 _buildStatItem('Trades', '18'),
//               ],
//             ),

//             const SizedBox(height: 30),
//             const Divider(),
//             const SizedBox(height: 20),

//             // Location
//             ListTile(
//               leading: const Icon(
//                 Icons.location_on_outlined,
//                 color: Colors.blue,
//               ),
//               title: const Text(
//                 'Location',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               subtitle: Text(_post.location),
//             ),

//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatItem(String label, String value) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 4),
//         Text(label, style: const TextStyle(color: Colors.grey)),
//       ],
//     );
//   }

//   Widget _buildImageCarousel() {
//     return SizedBox(
//       height: 300,
//       child: Stack(
//         children: [
//           PageView.builder(
//             itemCount: _post.images.length,
//             itemBuilder: (context, index) {
//               return Image.network(
//                 _post.processedImages[index],
//                 width: double.infinity,
//                 fit: BoxFit.cover,
//                 loadingBuilder: (context, child, loadingProgress) {
//                   if (loadingProgress == null) return child;
//                   return Center(
//                     child: CircularProgressIndicator(
//                       value: loadingProgress.expectedTotalBytes != null
//                           ? loadingProgress.cumulativeBytesLoaded /
//                                 loadingProgress.expectedTotalBytes!
//                           : null,
//                     ),
//                   );
//                 },
//                 errorBuilder: (context, error, stackTrace) {
//                   return Container(
//                     color: Colors.grey.shade200,
//                     child: const Center(
//                       child: Icon(Icons.photo, size: 64, color: Colors.grey),
//                     ),
//                   );
//                 },
//               );
//             },
//           ),
//           Positioned(
//             bottom: 20,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(
//                 _post.images.length,
//                 (index) => Container(
//                   width: 8,
//                   height: 8,
//                   margin: const EdgeInsets.symmetric(horizontal: 4),
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: Colors.white.withOpacity(0.8),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildBarterSection() {
//     if (_post.barterDetails == null) return const SizedBox();

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange.shade100),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Row(
//             children: [
//               Icon(Icons.sync_alt, color: Colors.orange, size: 20),
//               SizedBox(width: 8),
//               Text(
//                 'Barter Details',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.orange,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),

//           if (_post.barterDetails!.barterCategories.isNotEmpty)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Looking for categories:',
//                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
//                 ),
//                 const SizedBox(height: 8),
//                 Wrap(
//                   spacing: 8,
//                   children: _post.barterDetails!.barterCategories.map((
//                     barterCategory,
//                   ) {
//                     return Chip(
//                       label: Text(barterCategory.category.name),
//                       backgroundColor: Colors.white,
//                       side: BorderSide(color: Colors.orange.shade200),
//                     );
//                   }).toList(),
//                 ),
//               ],
//             ),

//           const SizedBox(height: 12),
//           Text(
//             'Barter status: ${_post.barterDetails!.barterCategories.length} categories',
//             style: const TextStyle(fontSize: 14, color: Colors.black87),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildServiceSection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue.shade100),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(
//                 _post.status == PostStatus.PROVIDE_SERVICE
//                     ? Icons.handyman
//                     : Icons.search,
//                 color: Colors.blue,
//                 size: 20,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 _post.statusText,
//                 style: const TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Text(
//             _post.description,
//             style: const TextStyle(fontSize: 14, color: Colors.black87),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.share_outlined, color: Colors.black),
//             onPressed: () {
//               ScaffoldMessenger.of(
//                 context,
//               ).showSnackBar(const SnackBar(content: Text('Sharing post...')));
//             },
//           ),
//           IconButton(
//             icon: Icon(
//               _isFavorite ? Icons.favorite : Icons.favorite_border,
//               color: _isFavorite ? Colors.red : Colors.black,
//             ),
//             onPressed: _toggleFavorite,
//           ),
//         ],
//       ),

//       body: _isLoading
//           ? const LoadingWidget()
//           : SingleChildScrollView(
//               padding: const EdgeInsets.only(bottom: 120), // 👈 Important
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   _buildImageCarousel(),

//                   Padding(
//                     padding: const EdgeInsets.all(20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         // USER INFO
//                         Row(
//                           children: [
//                             GestureDetector(
//                               onTap: () => _showUserProfile(context),
//                               child: CircleAvatar(
//                                 radius: 22,
//                                 backgroundColor: Colors.grey.shade200,
//                                 backgroundImage:
//                                     _post.postedBy.profileImage != null
//                                     ? NetworkImage(_post.postedBy.profileImage!)
//                                     : null,
//                                 child: _post.postedBy.profileImage == null
//                                     ? Text(
//                                         _post.postedBy.firstName.isNotEmpty
//                                             ? _post.postedBy.firstName[0]
//                                             : 'U',
//                                         style: const TextStyle(
//                                           fontSize: 18,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       )
//                                     : null,
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     _post.postedBy.fullName,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 16,
//                                     ),
//                                   ),
//                                   Text(
//                                     _post.location,
//                                     style: const TextStyle(
//                                       color: Colors.grey,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Text(
//                               _formatTimeAgo(_post.postedDate),
//                               style: const TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 20),

//                         // TITLE
//                         Text(
//                           _post.title,
//                           style: const TextStyle(
//                             fontSize: 24,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),

//                         const SizedBox(height: 8),

//                         if (_post.price > 0)
//                           Text(
//                             _post.formattedPrice,
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.green,
//                             ),
//                           ),
//                       ],
//                     ),
//                   ),

//                   const Divider(thickness: 1),

//                   // DESCRIPTION
//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 16,
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Description',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           _post.description,
//                           style: const TextStyle(
//                             fontSize: 14,
//                             color: Colors.black87,
//                             height: 1.5,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   if (_post.isForBarter) _buildBarterSection(),
//                   if (_post.type == PostType.service) _buildServiceSection(),

//                   Padding(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 20,
//                       vertical: 10,
//                     ),
//                     child: Row(
//                       children: [
//                         const Icon(
//                           Icons.calendar_today,
//                           size: 16,
//                           color: Colors.grey,
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Posted: ${_formatDate(_post.postedDate)}',
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//       // ✅ FIXED BUTTON (SAFE FOR VIVO)
//       bottomNavigationBar: SafeArea(
//         top: false,
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
//             ],
//           ),
//           child: SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _navigateToOfferDeck,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF2E5BFF),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               child: const Text(
//                 'Make an Offer',
//                 style: TextStyle(
//                   fontSize: 16,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _toggleFavorite() {
//     setState(() {
//       _isFavorite = !_isFavorite;
//     });
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           _isFavorite ? 'Added to favorites' : 'Removed from favorites',
//         ),
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   String _formatDate(DateTime date) {
//     return '${_getMonth(date.month)} ${date.day}, ${date.year}';
//   }

//   String _formatTimeAgo(DateTime date) {
//     final now = DateTime.now();
//     final difference = now.difference(date);

//     if (difference.inMinutes < 60) {
//       return '${difference.inMinutes}m ago';
//     } else if (difference.inHours < 24) {
//       return '${difference.inHours}h ago';
//     } else {
//       return '${difference.inDays}d ago';
//     }
//   }

//   String _getMonth(int month) {
//     const months = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'May',
//       'Jun',
//       'Jul',
//       'Aug',
//       'Sep',
//       'Oct',
//       'Nov',
//       'Dec',
//     ];
//     return months[month - 1];
//   }
// }

import 'package:flutter/material.dart';
import 'package:Yempover_app/models/ProductPostmain.dart';
import 'package:Yempover_app/screens/OfferDeckScreen.dart';
import 'package:Yempover_app/services/api_service.dart';
import 'package:Yempover_app/services/post_action_service.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:Yempover_app/utils/loading_widget.dart';
import 'package:Yempover_app/utils/snackbar_utils.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  final List<UserItem> userItems;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.userItems,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final ApiService _apiService = ApiService();
  final TradeChatService _chatService = TradeChatService();
  final TokenService _tokenService = TokenService();
  final PostActionService _postActionService = PostActionService();

  late Post _post;
  bool _isLoading = false;
  bool _isFavorite = false;
  String? _favoriteId; // Store favorite ID for removal
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadCurrentUser();
    _loadPostDetails();
    _checkIfFavorite(); // Check if post is already favorited
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUserId = await _tokenService.getUserId();
      print('👤 Current user ID: $_currentUserId');
    } catch (e) {
      print('❌ Error loading current user: $e');
    }
  }

  Future<void> _loadPostDetails() async {
    try {
      setState(() => _isLoading = true);
      final response = await _apiService.getPostDetail(
        postId: _post.id,
        type: _post.type,
      );
      setState(() {
        _post = response.post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load post details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if post is in user's favorites
  Future<void> _checkIfFavorite() async {
    try {
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (!isLoggedIn) return;

      // You might want to fetch user's favorites list from API here
      // For now, we initialize to false and rely on toggleFavorite for updates
      setState(() {
        _isFavorite = false;
      });
    } catch (e) {
      debugPrint('🔴 Error checking favorite status: $e');
    }
  }

  // Navigate to Offer Deck
  void _navigateToOfferDeck() {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to make an offer'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Don't allow offering on own post
    if (_currentUserId == _post.postedById) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot make an offer on your own post'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            OfferDeckScreen(post: _post, currentUserId: _currentUserId!),
      ),
    );
  }

  // Toggle favorite status
  Future<void> _toggleFavorite() async {
    try {
      // Check if user is logged in
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (!isLoggedIn) {
        if (mounted) {
          SnackbarUtils.showLoginDialog(context);
        }
        return;
      }

      final isService = _post.type == PostType.service;

      // Optimistic update
      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (_isFavorite) {
        // Adding to favorites
        final response = await _postActionService.addToFavorites(
          postId: _post.id,
          isService: isService,
        );

        if (mounted) {
          setState(() {
            _favoriteId = response.data.favorite.id;
          });
          SnackbarUtils.showSuccess(context, response.message);
        }
      } else {
        // Removing from favorites
        final response = await _postActionService.removeFromFavorites(
          postId: _post.id,
          isService: isService,
        );

        if (mounted) {
          setState(() {
            _favoriteId = null;
          });
          SnackbarUtils.showSuccess(context, response.message);
        }
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isFavorite = !_isFavorite;
      });

      if (mounted) {
        // Don't show error for "Already favorited" as it's not really an error
        if (e.toString().contains('Already favorited')) {
          SnackbarUtils.showInfo(context, 'Already in favorites');
        } else {
          SnackbarUtils.showError(
            context,
            e.toString().replaceAll('Exception: ', ''),
          );
        }
      }
    }
  }

  // Report post
  Future<void> _reportPost(String reason, [String? description]) async {
    try {
      final response = await _postActionService.reportPost(
        postId: _post.id,
        reason: reason,
        description: description,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Report Submitted'),
            content: Text(
              'You have reported "${_post.title}" for: $reason\n\nOur team will review this post within 24 hours.\n\nReport ID: ${response.data.report.id}',
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
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, e.toString());
      }
    }
  }

  // Show report dialog
  void _showReportDialog() {
    String selectedReason = 'Spam';
    TextEditingController reportController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select reason for reporting this post:'),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedReason,
              items: const [
                DropdownMenuItem(value: 'Spam', child: Text('Spam')),
                DropdownMenuItem(
                  value: 'Inappropriate',
                  child: Text('Inappropriate Content'),
                ),
                DropdownMenuItem(
                  value: 'Wrong Category',
                  child: Text('Wrong Category'),
                ),
                DropdownMenuItem(value: 'Fake', child: Text('Fake Post')),
                DropdownMenuItem(
                  value: 'Duplicate',
                  child: Text('Duplicate Post'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                selectedReason = value ?? 'Spam';
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reportController,
              decoration: const InputDecoration(
                hintText: 'Additional details (optional)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              _reportPost(
                selectedReason,
                reportController.text.isNotEmpty ? reportController.text : null,
              );
              Navigator.pop(context);
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  // Show post options menu
  void _showPostOptions() {
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
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey,
              ),
              title: Text(
                _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () {
                _toggleFavorite();
                Navigator.pop(context);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report Post'),
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
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

  void _showUserProfile(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade200,
              child: _post.postedBy.profileImage != null
                  ? ClipOval(
                      child: Image.network(
                        _post.postedBy.profileImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      _post.postedBy.firstName.isNotEmpty
                          ? _post.postedBy.firstName[0]
                          : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              _post.postedBy.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Member since ${_formatDate(_post.postedDate.subtract(const Duration(days: 365)))}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // User Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem('Posts', '24'),
                _buildStatItem('Rating', '4.8'),
                _buildStatItem('Trades', '18'),
              ],
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),

            // Location
            ListTile(
              leading: const Icon(
                Icons.location_on_outlined,
                color: Colors.blue,
              ),
              title: const Text(
                'Location',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(_post.location),
            ),

            const SizedBox(height: 20),
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: _post.images.length,
            itemBuilder: (context, index) {
              return Image.network(
                _post.processedImages[index],
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: Icon(Icons.photo, size: 64, color: Colors.grey),
                    ),
                  );
                },
              );
            },
          ),
          // Image indicator
          if (_post.images.length > 1)
            Positioned(
              bottom: 20,
              right: 20,
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
                  '1/${_post.images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarterSection() {
    if (_post.barterDetails == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sync_alt, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                'Barter Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_post.barterDetails!.barterCategories.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Looking for categories:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _post.barterDetails!.barterCategories.map((
                    barterCategory,
                  ) {
                    return Chip(
                      label: Text(barterCategory.category.name),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.orange.shade200),
                    );
                  }).toList(),
                ),
              ],
            ),

          const SizedBox(height: 12),
          Text(
            'Barter status: ${_post.barterDetails!.barterCategories.length} categories',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _post.status == PostStatus.PROVIDE_SERVICE
                    ? Icons.handyman
                    : Icons.search,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _post.statusText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _post.description,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : Colors.black,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _showPostOptions,
          ),
        ],
      ),

      body: _isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImageCarousel(),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // USER INFO
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showUserProfile(context),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage:
                                    _post.postedBy.profileImage != null
                                    ? NetworkImage(_post.postedBy.profileImage!)
                                    : null,
                                child: _post.postedBy.profileImage == null
                                    ? Text(
                                        _post.postedBy.firstName.isNotEmpty
                                            ? _post.postedBy.firstName[0]
                                            : 'U',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _post.postedBy.fullName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _post.location,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatTimeAgo(_post.postedDate),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // TITLE
                        Text(
                          _post.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        if (_post.price > 0)
                          Text(
                            _post.formattedPrice,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Divider(thickness: 1),

                  // DESCRIPTION
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _post.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_post.isForBarter) _buildBarterSection(),
                  if (_post.type == PostType.service) _buildServiceSection(),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Posted: ${_formatDate(_post.postedDate)}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToOfferDeck,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E5BFF),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Make an Offer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonth(date.month)} ${date.day}, ${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
