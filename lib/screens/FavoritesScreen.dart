// lib/screens/FavoritesScreen.dart
import 'package:flutter/material.dart';
import 'package:yempover_app/models/favorites_response.dart';
import 'package:yempover_app/services/favorites_service.dart';
import 'package:yempover_app/utils/CustomErrorWidget.dart';
import 'package:yempover_app/utils/loading_overlay.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();

  List<FavoriteItem> _favorites = [];
  PaginationInfo? _pagination;

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (_pagination != null && _pagination!.hasNextPage && !_isLoadingMore) {
        _loadMoreFavorites();
      }
    }
  }

  Future<void> _loadFavorites({int page = 1}) async {
    if (page == 1) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final response = await _favoritesService.getFavorites(
        page: page,
        limit: 20,
      );

      setState(() {
        if (page == 1) {
          _favorites = response.data.favorites;
        } else {
          _favorites.addAll(response.data.favorites);
        }
        _pagination = response.data.pagination;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _loadMoreFavorites() async {
    if (_pagination == null || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _loadFavorites(page: _pagination!.page + 1);
  }

  Future<void> _refreshFavorites() async {
    await _loadFavorites(page: 1);
  }

  Future<void> _removeFromFavorites(String favoriteId) async {
    try {
      final success = await _favoritesService.removeFromFavorites(favoriteId);

      if (success && mounted) {
        setState(() {
          _favorites.removeWhere((item) => item.id == favoriteId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToItemDetail(FavoriteItem item) {
    // Navigate to detail screen based on item type
    if (item.type == 'product') {
      // Navigate to product detail
      Navigator.pushNamed(context, '/product-detail', arguments: item.id);
    } else if (item.type == 'service') {
      // Navigate to service detail
      Navigator.pushNamed(context, '/service-detail', arguments: item.id);
    }
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
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {
                // Implement search
              },
            ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: RefreshIndicator(
          onRefresh: _refreshFavorites,
          color: Colors.blue,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return CustomErrorWidget(
        message: _errorMessage,
        onRetry: _refreshFavorites,
      );
    }

    if (_favorites.isEmpty && !_isLoading) {
      return EmptyStateWidget(
        icon: Icons.favorite_border,
        title: 'No Favorites Yet',
        message: 'Items you mark as favorite will appear here',
        buttonText: 'Browse Items',
        onButtonPressed: () {
          Navigator.pop(context);
          // Navigate to browse screen
        },
      );
    }

    return Column(
      children: [
        // Favorites count
        if (_favorites.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            alignment: Alignment.centerLeft,
            child: Text(
              '${_favorites.length} ${_favorites.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Favorites list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _favorites.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _favorites.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _buildFavoriteItemCard(_favorites[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteItemCard(FavoriteItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToItemDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: item.images != null && item.images!.isNotEmpty
                      ? Image.network(
                          item.images!.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              item.type == 'product'
                                  ? Icons.shopping_bag
                                  : Icons.build,
                              size: 40,
                              color: Colors.grey.shade400,
                            );
                          },
                        )
                      : Icon(
                          item.type == 'product'
                              ? Icons.shopping_bag
                              : Icons.build,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Favorite button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.favorite,
                            color: Colors.red,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _removeFromFavorites(item.id!),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Price
                    if (item.price != null)
                      Text(
                        '${item.currency ?? '\$'}${item.price!.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),

                    const SizedBox(height: 4),

                    // Category and Condition
                    Row(
                      children: [
                        if (item.category != null)
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
                              item.category!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (item.condition != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.condition!,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Seller info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: item.sellerImage != null
                              ? NetworkImage(item.sellerImage!)
                              : null,
                          child: item.sellerImage == null
                              ? Text(
                                  item.sellerName?[0] ?? '?',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.sellerName ?? 'Unknown Seller',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.sellerRating != null) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber.shade600,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            item.sellerRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Location
                    if (item.location != null)
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
                              item.location!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
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
        ),
      ),
    );
  }
}
