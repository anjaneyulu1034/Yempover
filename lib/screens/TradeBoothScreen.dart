// screens/TradeBoothScreen.dart
import 'dart:async';

import 'package:yempover_app/screens/ProductDetailScreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/utils/error_message_utils.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import '../models/my_post_model.dart';
import '../services/my_posts_service.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _countdownTimer;
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _typeFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
    _startCountdownTimer();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    // _postsService.dispose();
    super.dispose();
  }

  // A service is never "sold" — completing a deal on it doesn't take it out
  // of circulation, so COMPLETED only reads as sold for products (where it
  // never actually occurs; SOLD/BARTERED are the real product-sold states).
  bool _isPostSold(MyPost post) {
    final status = post.status.trim().toUpperCase();
    if (post.type.toLowerCase() == 'service') {
      return false;
    }
    return status == 'SOLD' || status == 'BARTERED' || status == 'COMPLETED';
  }

  bool _isPostExpired(MyPost post) {
    if (_isPostSold(post)) return false;
    if (post.hasExpired) return true;
    final validUntil = post.validUntil;
    return validUntil != null && !validUntil.isAfter(DateTime.now());
  }

  List<MyPost> get _visiblePosts {
    return _posts.where((post) {
      switch (_statusFilter) {
        case 'Active':
          if (_isPostSold(post) || _isPostExpired(post)) return false;
          break;
        case 'Expired':
          if (!_isPostExpired(post)) return false;
          break;
        case 'Sold':
          if (!_isPostSold(post)) return false;
          break;
      }

      if (_searchQuery.isEmpty) return true;
      return post.title.toLowerCase().contains(_searchQuery) ||
          post.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  // Products/Services tabs hit the server (Point 3.2) rather than filtering
  // client-side, so pagination stays correct for whichever type is active.
  String? get _typeParam => _typeFilter == 'All' ? null : _typeFilter.toLowerCase();

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

      final response = await _postsService.getMyPosts(
        page: 1,
        limit: 20,
        type: _typeParam,
      );

      if (!mounted) return;

      setState(() {
        _posts = response.data.posts;
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      final errorMessage = ErrorMessageUtils.sanitize(e);

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
        type: _typeParam,
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

      final errorMessage = ErrorMessageUtils.sanitize(e);
      if (errorMessage.contains('Session expired')) {
        _handleSessionExpired();
      } else {
        _showErrorSnackBar('Failed to load more posts');
      }
    }
  }

  Future<void> _refreshPosts() async {
    try {
      final response = await _postsService.getMyPosts(
        page: 1,
        limit: 20,
        type: _typeParam,
      );

      if (!mounted) return;

      setState(() {
        _posts = response.data.posts;
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
      });
    } catch (e) {
      final errorMessage = ErrorMessageUtils.sanitize(e);
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

  static const List<String> _statusFilterOptions = [
    'All',
    'Active',
    'Expired',
    'Sold',
  ];

  // Same blue gradient filter button as Home_screen's search bar.
  Widget _buildStatusFilterButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E5BFF), Color(0xFF4A7AFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _showStatusFilterSheet,
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.tune, color: Colors.white),
          ),
        ),
      ),
    );
  }

  static const List<String> _typeFilterOptions = ['All', 'Product', 'Service'];

  Widget _buildTypeFilterTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: _typeFilterOptions.map((type) {
          final selected = _typeFilter == type;
          final isLast = type == _typeFilterOptions.last;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 8),
              child: Material(
                color: selected ? const Color(0xFF2E5BFF) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    if (_typeFilter == type) return;
                    setState(() => _typeFilter = type);
                    _fetchMyPosts();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(
                      type,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showStatusFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
                child: Text(
                  'Filter by status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              ..._statusFilterOptions.map((filter) {
                final selected = _statusFilter == filter;
                return ListTile(
                  title: Text(
                    filter,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? const Color(0xFF2E5BFF) : Colors.black87,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check, color: Color(0xFF2E5BFF))
                      : null,
                  onTap: () {
                    setState(() {
                      _statusFilter = filter;
                    });
                    Navigator.pop(sheetContext);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  String _formatPrice(MyPost post) {
    // Keep showing the coin value once a product is used to complete a deal
    // (isSold) — it's history at that point, not an active listing, but the
    // price should still be visible instead of disappearing from the card.
    if (post.price != null && post.price! > 0) {
      if (post.isForSale || post.isProvidingService || post.isSold) {
        return CoinFormat.amount(post.price);
      }
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
          if (!_isLoading && _errorMessage == null && _posts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search your posts',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _searchController.clear(),
                              ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildStatusFilterButton(),
                ],
              ),
            ),
            _buildTypeFilterTabs(),
          ],
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
                : _visiblePosts.isEmpty
                ? _buildPullToRefreshState(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts match',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search or filter',
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
                      itemCount:
                          _visiblePosts.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _visiblePosts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        return _buildPostCard(_visiblePosts[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPostThumbnail(MyPost post, {required bool hasImage}) {
    const size = 108.0;
    final borderRadius = BorderRadius.circular(12);
    final placeholderIcon = post.type == 'service'
        ? Icons.build_circle
        : Icons.shopping_bag;

    Widget imageContent;
    if (hasImage) {
      imageContent = Image.network(
        post.images.first,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: Colors.grey[300],
            child: Icon(placeholderIcon, size: 36, color: Colors.grey[500]),
          );
        },
      );
    } else {
      imageContent = Container(
        width: size,
        height: size,
        color: Colors.grey[100],
        child: Icon(placeholderIcon, size: 36, color: Colors.grey[400]),
      );
    }

    return Stack(
      children: [
        ClipRRect(borderRadius: borderRadius, child: imageContent),
        // Sold takes priority over expired (mirrors _isPostExpired, which
        // treats a sold post as never "expired") — one badge, top-left.
        if (post.isSold)
          Positioned(
            top: 6,
            left: 6,
            child: _statusChip(
              'SOLD${post.soldAt != null ? ' · ${DateFormat('MMM d').format(post.soldAt!)}' : ''}',
              Colors.green,
            ),
          )
        else if (_isPostExpired(post))
          Positioned(
            top: 6,
            left: 6,
            child: _statusChip(
              'EXPIRED${post.expiredAt != null ? ' · ${DateFormat('MMM d').format(post.expiredAt!)}' : ''}',
              Colors.red.shade600,
            ),
          ),
        Positioned(
          bottom: 6,
          right: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.remove_red_eye, size: 12, color: Colors.white),
                const SizedBox(width: 3),
                Text(
                  '${post.viewCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaChip({
    required String label,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildPostCard(MyPost post) {
    final hasImage = post.images.isNotEmpty;
    final displayPrice = _formatPrice(post);
    final hasLocation = post.location != null && post.location!.isNotEmpty;

    return GestureDetector(
      onTap: () => _navigateToPostDetail(post),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPostThumbnail(post, hasImage: hasImage),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _buildMetaChip(
                        label: post.category.name,
                        bg: Colors.blue.shade50,
                        fg: Colors.blue.shade700,
                      ),
                      _buildMetaChip(
                        label: post.type == 'service' ? 'Service' : 'Product',
                        bg: post.type == 'service'
                            ? Colors.purple.shade50
                            : Colors.orange.shade50,
                        fg: post.type == 'service'
                            ? Colors.purple.shade700
                            : Colors.orange.shade700,
                      ),
                      _buildMetaChip(
                        label: post.isOpenForBarter
                            ? 'Open for Barter'
                            : 'No Barter',
                        bg: post.isOpenForBarter
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        fg: post.isOpenForBarter
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFC62828),
                      ),
                      if (displayPrice.isNotEmpty)
                        CoinPriceLabel(
                          text: CoinFormat.withLabel(post.price),
                          iconSize: 14,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.green.shade700,
                          ),
                        ),
                    ],
                  ),
                  if (hasLocation) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _truncateLocation(post.location!, maxLength: 40),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    post.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (post.validUntil != null) ...[
                        Icon(
                          Icons.timer_outlined,
                          size: 14,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _getExpiryCountdownLabel(post),
                            style: TextStyle(
                              fontSize: 11,
                              color: _getExpiryCountdownColor(post),
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else
                        const Spacer(),
                      Text(
                        DateFormat('MMM dd, yyyy').format(post.postedDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
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
