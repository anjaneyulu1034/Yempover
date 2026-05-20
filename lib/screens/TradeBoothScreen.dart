// screens/TradeBoothScreen.dart
import 'dart:async';

import 'package:YemPover_app/screens/ProductDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/utils/snackbar_utils.dart';
import '../models/my_post_model.dart';
import '../services/my_posts_service.dart';
import 'package:YemPover_app/widgets/coin_icon.dart';
import '../screens/AddPostScreen.dart';

class TradeBoothScreen extends StatefulWidget {
  const TradeBoothScreen({super.key});

  @override
  State<TradeBoothScreen> createState() => _TradeBoothScreenState();
}

class _TradeBoothScreenState extends State<TradeBoothScreen> {
  final MyPostsService _postsService = MyPostsService();
  final TokenService _tokenService = TokenService();
  List<MyPost> _posts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
    _startCountdownTimer();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    // _postsService.dispose();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _fetchMorePosts();
      }
    }
  }

  void _handleSessionExpired() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Session Expired'),
          content: const Text(
            'Your session has expired. Please login again to continue.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _fetchMyPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (!isLoggedIn) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Please login to view your posts';
        });
        if (mounted) {
          _showLoginDialog();
        }
        return;
      }

      final response = await _postsService.getMyPosts(page: 1, limit: 20);

      if (!mounted) return;

      setState(() {
        _posts = response.data.posts;
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');

      setState(() {
        _isLoading = false;
        _errorMessage = errorMessage;
      });

      if (errorMessage.contains('Session expired') ||
          errorMessage.contains('Unauthorized') ||
          errorMessage.contains('No authentication token')) {
        _handleSessionExpired();
      } else {
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Text('Please login again to continue.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchMorePosts() async {
    if (_currentPage >= _totalPages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final response = await _postsService.getMyPosts(
        page: _currentPage + 1,
        limit: 20,
      );

      if (!mounted) return;

      setState(() {
        _posts.addAll(response.data.posts);
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
      });

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('Session expired')) {
        _handleSessionExpired();
      } else {
        _showErrorSnackBar('Failed to load more posts');
      }
    }
  }

  Future<void> _refreshPosts() async {
    try {
      final response = await _postsService.getMyPosts(page: 1, limit: 20);

      if (!mounted) return;

      setState(() {
        _posts = response.data.posts;
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
      });
    } catch (e) {
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('Session expired')) {
        _handleSessionExpired();
      } else {
        _showErrorSnackBar('Failed to refresh posts');
      }
    }
  }

  void _navigateToPostDetail(MyPost post) async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostDetailScreen1(post: post, userItems: []),
        ),
      );

      // If post was deleted or updated, refresh the list
      if (result == true) {
        _refreshPosts();
      }
    } catch (e) {
      debugPrint('🔴 Error navigating to post detail: $e');
    }
  }

  void _navigateToAddPost() {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AddPostScreen(
          onPostAdded: () {
            _refreshPosts();
          },
        ),
      );
    } catch (e) {
      debugPrint('🔴 Error opening add post screen: $e');
      _showErrorSnackBar('Failed to open add post screen');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    SnackbarUtils.showError(context, message);
  }

  String _formatPrice(MyPost post) {
    if (post.price != null && post.price! > 0) {
      if (post.isForSale) {
        return CoinFormat.amount(post.price);
      } else if (post.isProvidingService) {
        return CoinFormat.amount(post.price);
      }
    }
    return '';
  }

  String _getReturnDetails(MyPost post) {
    if (post.price != null && post.price! > 0) {
      return _formatPrice(post);
    }
    return '';
  }

  String _getExpiryCountdownLabel(MyPost post) {
    final validUntil = post.validUntil;
    if (validUntil == null) {
      return 'No expiry timeline';
    }

    final now = DateTime.now();
    if (!validUntil.isAfter(now)) {
      return 'Expired';
    }

    final difference = validUntil.difference(now);

    if (difference.inHours < 24) {
      final totalMinutes = difference.inMinutes;
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      final seconds = difference.inSeconds % 60;
      return 'Expires in ${hours}h:${minutes.toString().padLeft(2, '0')}m:${seconds.toString().padLeft(2, '0')}s';
    }

    if (difference.inDays < 30) {
      final days = difference.inDays;
      final remHours = difference.inHours % 24;
      return remHours > 0
          ? 'Expires in ${days}d ${remHours}h'
          : 'Expires in ${days}d';
    }

    final days = difference.inDays;
    final months = (days / 30).floor();
    final remDays = days % 30;
    return remDays > 0
        ? 'Expires in ${months}mo ${remDays}d'
        : 'Expires in ${months}mo';
  }

  Color _getExpiryCountdownColor(MyPost post) {
    final validUntil = post.validUntil;
    if (validUntil == null) {
      return Colors.blueGrey.shade700;
    }

    final now = DateTime.now();
    if (!validUntil.isAfter(now)) {
      return Colors.red.shade700;
    }

    final difference = validUntil.difference(now);
    if (difference.inHours < 1) {
      return Colors.red.shade700;
    }
    if (difference.inHours < 24) {
      return Colors.orange.shade700;
    }
    return Colors.green.shade700;
  }

  String _truncateLocation(String location, {int maxLength = 25}) {
    if (location.length <= maxLength) return location;
    return '${location.substring(0, maxLength)}...';
  }

  Widget _buildPullToRefreshState({required Widget child}) {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: const Color(0xFF2E5BFF),
      backgroundColor: Colors.transparent,
      elevation: 0,
      strokeWidth: 2.2,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [SizedBox(height: 420, child: Center(child: child))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trade Booth',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildPullToRefreshState(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchMyPosts,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E5BFF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  )
                : _posts.isEmpty
                ? _buildPullToRefreshState(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.post_add, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click "Add Post" to create your first post',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshPosts,
                    color: const Color(0xFF2E5BFF),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    strokeWidth: 2.2,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _posts.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _posts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildPostCard(_posts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(MyPost post) {
    final hasImage = post.images.isNotEmpty;
    final displayPrice = _formatPrice(post);
    final returnDetails = _getReturnDetails(post);
    final maxLocationWidth =
        (MediaQuery.of(context).size.width * 0.40).clamp(110.0, 170.0);

    return GestureDetector(
      onTap: () => _navigateToPostDetail(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (hasImage)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      post.images.first,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              post.type == 'service'
                                  ? Icons.build_circle
                                  : Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[500],
                            ),
                          ),
                        );
                      },
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
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.viewCount}',
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
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Center(
                  child: Icon(
                    post.type == 'service'
                        ? Icons.build_circle
                        : Icons.shopping_bag,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                ),
              ),

            // Post Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title, Category and Location
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                post.category.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (post.location != null && post.location!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: maxLocationWidth),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _truncateLocation(post.location!),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: post.type == 'service'
                          ? Colors.purple.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      post.type == 'service' ? 'Service' : 'Product',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: post.type == 'service'
                            ? Colors.purple.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

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
                          maxLines: 1,
                        ),
                      ),
                      if (returnDetails.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            returnDetails,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getExpiryCountdownLabel(post),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getExpiryCountdownColor(post),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description Preview
                  Text(
                    post.description,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 12),

                  // Posted Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMM dd, yyyy').format(post.postedDate),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      if (displayPrice.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: CoinPriceLabel(
                            text: '$displayPrice coins',
                            iconSize: 14,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
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
