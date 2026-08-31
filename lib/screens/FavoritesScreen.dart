import 'package:yempover_app/models/favorites_response.dart';
import 'package:flutter/material.dart';
import 'package:yempover_app/models/ProductPostmain.dart';
import 'package:yempover_app/services/api_service.dart';
import 'package:yempover_app/services/post_action_service.dart';
import 'package:yempover_app/utils/error_message_utils.dart';
import 'package:yempover_app/utils/post_availability_utils.dart';
import 'package:yempover_app/screens/PostDetailScreen.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import 'package:yempover_app/screens/Home_screen.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:yempover_app/utils/blocked_users_cache.dart';
import 'package:yempover_app/services/token_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final PostActionService _postActionService = PostActionService();
  final ApiService _apiService = ApiService();
  final TokenService _tokenService = TokenService();

  List<FavoriteItem> _favorites = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 20;
  String? _errorMessage;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    BlockedUsersCache.instance.addListener(_onBlockedUsersChanged);
    _loadFavorites();
  }

  @override
  void dispose() {
    BlockedUsersCache.instance.removeListener(_onBlockedUsersChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onBlockedUsersChanged() {
    if (!mounted) return;
    setState(() {
      _favorites = BlockedUsersCache.instance.filterFavorites(_favorites);
    });
  }

  Future<List<FavoriteItem>> _filterFavorites(List<FavoriteItem> items) async {
    final withoutExpired =
        items.where((item) => !item.isExpiredOrUnavailable).toList();
    final available = await _filterByLivePostAvailability(withoutExpired);

    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!isLoggedIn) return available;

    await BlockedUsersCache.instance.ensureLoaded();
    return BlockedUsersCache.instance.filterFavorites(available);
  }

  /// Drop favorites whose post detail API returns 410/404 (expired / unavailable).
  Future<List<FavoriteItem>> _filterByLivePostAvailability(
    List<FavoriteItem> items,
  ) async {
    final available = <FavoriteItem>[];

    for (final item in items) {
      final postId = item.actualPostId;
      if (postId == null || postId.isEmpty) continue;

      try {
        await _apiService.getPostDetail(
          postId: postId,
          type: item.type == 'service' ? PostType.service : PostType.product,
        );
        available.add(item);
      } on ApiException catch (e) {
        if (!PostAvailabilityUtils.isApiUnavailableStatus(e.statusCode)) {
          available.add(item);
        }
      } catch (_) {
        available.add(item);
      }
    }

    return available;
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMoreFavorites();
      }
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
    });

    try {
      final response = await _postActionService.getFavorites(
        page: _currentPage,
        limit: _limit,
      );

      final filtered = await _filterFavorites(response.data.favorites);

      setState(() {
        _favorites = filtered;
        _hasMore =
            response.data.pagination.page < response.data.pagination.pages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorMessageUtils.sanitize(e);
      });

      if (mounted) {
        SnackbarUtils.showError(context, _errorMessage!);
      }
    }
  }

  Future<void> _loadMoreFavorites() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });

    try {
      final response = await _postActionService.getFavorites(
        page: _currentPage,
        limit: _limit,
      );

      final filtered = await _filterFavorites(response.data.favorites);

      setState(() {
        _favorites.addAll(filtered);
        _hasMore =
            response.data.pagination.page < response.data.pagination.pages;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
        _currentPage--;
      });

      if (mounted) {
        SnackbarUtils.showError(context, 'Failed to load more favorites');
      }
    }
  }

  Future<void> _refreshFavorites() async {
    await _loadFavorites();
  }

  Future<void> _removeFromFavorites(FavoriteItem favorite) async {
    try {
      // Optimistic update - remove immediately
      setState(() {
        _favorites.removeWhere((item) => item.id == favorite.id);
      });

      final isService = favorite.type == 'service';

      final response = await _postActionService.removeFromFavorites(
        postId: favorite.actualPostId ?? favorite.id,
        isService: isService,
      );

      if (mounted) {
        SnackbarUtils.showSuccess(context, response.message);
      }
    } catch (e) {
      // Revert on error - add back the item
      setState(() {
        _favorites.insert(0, favorite);
      });

      if (mounted) {
        SnackbarUtils.showError(context, e);
      }
    }
  }

  void _confirmRemove(FavoriteItem favorite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites'),
        content: Text(
          'Are you sure you want to remove "${favorite.title}" from your favorites?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _removeFromFavorites(favorite);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'FOR_SALE':
        return 'For Sale';
      case 'SOLD':
        return 'Sold';
      case 'BARTERED':
        return 'Sold';
      case 'LOOKING_FOR_SERVICE':
        return 'Looking for Service';
      case 'PROVIDE_SERVICE':
        return 'Providing Service';
      case 'FOR_BARTER':
        return 'For Barter';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'FOR_SALE':
        return Colors.green;
      case 'SOLD':
        return Colors.grey;
      case 'LOOKING_FOR_SERVICE':
        return Colors.orange;
      case 'PROVIDE_SERVICE':
        return Colors.blue;
      case 'FOR_BARTER':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Favorites",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorWidget()
          : _favorites.isEmpty
          ? _buildEmptyWidget()
          : RefreshIndicator(
              onRefresh: _refreshFavorites,
              color: const Color(0xFF2E5BFF),
              backgroundColor: Colors.white,
              elevation: 0,
              strokeWidth: 2.2,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _favorites.length + 1,
                itemBuilder: (context, index) {
                  if (index == _favorites.length) {
                    return _buildLoadingMoreIndicator();
                  }

                  final favorite = _favorites[index];
                  return _buildFavoriteCard(favorite);
                },
              ),
            ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadFavorites,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5BFF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Try Again', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 60,
              color: Color(0xFF2E5BFF),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Favorites Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Items you mark as favorite will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5BFF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Browse Marketplace',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    if (!_isLoadingMore) {
      return const SizedBox();
    }

    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildFavoriteCard(FavoriteItem favorite) {
    final statusText = _getStatusText(favorite.status);
    final statusColor = _getStatusColor(favorite.status);
    final dateText = _formatDate(favorite.createdAt);

    // Create a Post object for navigation
    final post = Post(
      id: favorite.actualPostId ?? favorite.id,
      title: favorite.title,
      description: '',
      images: favorite.images,
      status: _mapStatus(favorite.status),
      barterStatus: BarterStatus.NO_BARTER,
      price: favorite.price,
      categoryId: favorite.category.id,
      latitude: null,
      longitude: null,
      location: favorite.location,
      postedById: favorite.postedBy.id,
      postedDate: favorite.createdAt,
      viewCount: 0,
      isListed: true,
      createdAt: favorite.createdAt,
      updatedAt: favorite.createdAt,
      category: favorite.category,
      postedBy: User(
        id: favorite.postedBy.id,
        firstName: favorite.postedBy.firstName,
        lastName: favorite.postedBy.lastName,
        profileImage: favorite.postedBy.profileImage,
      ),
      type: favorite.type == 'service' ? PostType.service : PostType.product,
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailScreen(post: post, userItems: const []),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Image.network(
                    favorite.images.isNotEmpty
                        ? favorite.images.first
                        : 'https://via.placeholder.com/400x200',
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Type Badge
                if (favorite.type == 'service')
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Service',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // Remove Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: InkWell(
                    onTap: () => _confirmRemove(favorite),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              favorite.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            CoinPriceLabel(
                              text: CoinFormat.withLabel(favorite.price),
                              iconSize: 18,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category and Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          favorite.category.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Seller and Location
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: favorite.postedBy.profileImage != null
                            ? NetworkImage(favorite.postedBy.profileImage!)
                            : null,
                        child: favorite.postedBy.profileImage == null
                            ? Text(
                                favorite.postedBy.firstName.isNotEmpty
                                    ? favorite.postedBy.firstName[0]
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              favorite.postedBy.firstName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    favorite.location,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Added Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.favorite,
                        size: 14,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Added $dateText',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade600,
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

  PostStatus _mapStatus(String status) {
    switch (status) {
      case 'FOR_SALE':
        return PostStatus.FOR_SALE;
      case 'SOLD':
        return PostStatus.SOLD;
      case 'BARTERED':
        return PostStatus.BARTERED;
      case 'LOOKING_FOR_SERVICE':
        return PostStatus.LOOKING_FOR_SERVICE;
      case 'PROVIDE_SERVICE':
        return PostStatus.PROVIDE_SERVICE;
      case 'FOR_BARTER':
        return PostStatus.FOR_BARTER;
      default:
        return PostStatus.FOR_SALE;
    }
  }
}
