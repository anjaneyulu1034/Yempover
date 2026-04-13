import 'package:Yempover_app/screens/EditProductScreen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:Yempover_app/services/my_posts2_service.dart';
import 'package:Yempover_app/utils/snackbar_utils.dart';
import '../models/my_post_model.dart';

class PostDetailScreen1 extends StatefulWidget {
  final MyPost post;

  const PostDetailScreen1({
    super.key,
    required this.post,
    required List<dynamic> userItems,
  });

  @override
  State<PostDetailScreen1> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen1> {
  final MyPostsService _postsService = MyPostsService();
  late MyPost _post;
  bool _isLoading = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _postsService.dispose();
    super.dispose();
  }

  Future<void> _refreshPost() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _postsService.getPostById(_post.id);
      if (response.data != null && response.data!['post'] != null) {
        setState(() {
          _post = MyPost.fromJson(response.data!['post']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to refresh post');
    }
  }

  Future<void> _editPost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          post: _post,
          onProductUpdated: () {
            _refreshPost();
          },
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deletePost() async {
    if (_post.hasAcceptedOffer) {
      _showAlertDialog(
        'Cannot Delete',
        'This post has an accepted offer and cannot be deleted.',
      );
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
          'Are you sure you want to delete this post? Any open offers will be automatically rejected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _postsService.deletePost(_post.id, type: _post.type);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate deletion
        SnackbarUtils.showSuccess(context, '${_post.title} has been deleted');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to delete post: ${e.toString()}');
    }
  }

  Future<void> _markAsSold() async {
    if (_post.openOffersCount > 0 && !_post.hasAcceptedOffer) {
      _showAlertDialog(
        'Complete Deal',
        'You will have to complete an open deal, by clicking on "Deal Completed", '
            'to mark this item as sold. Clicking on "Proceed" will redirect you to '
            'the respective chat, if there is an open deal for this item.',
      );
    } else if (!_post.hasAcceptedOffer) {
      _showAlertDialog(
        'No Open Deals',
        'Currently there are no open deals for this post.',
      );
    } else {
      try {
        setState(() {
          _isLoading = true;
        });

        await _postsService.updatePostStatus(_post.id, 'SOLD');

        if (!mounted) return;

        await _refreshPost();
        if (!mounted) return;

        SnackbarUtils.showSuccess(context, '${_post.title} marked as sold');
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to mark post as sold: ${e.toString()}');
      }
    }
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

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    SnackbarUtils.showError(context, message);
  }

  String _formatPrice() {
    if (_post.price != null && _post.price! > 0) {
      if (_post.isForSale) {
        return '\$${_post.price!.toStringAsFixed(2)}';
      } else if (_post.isProvidingService) {
        return '\$${_post.price!.toStringAsFixed(2)}';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Post Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        actions: [
          if (!_post.isSold)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editPost,
              tooltip: 'Edit Post',
            ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deletePost,
            tooltip: 'Delete Post',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshPost,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Gallery
                    if (_post.images.isNotEmpty)
                      _buildImageGallery()
                    else
                      Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: Center(
                          child: Icon(
                            _post.type == 'service'
                                ? Icons.build_circle
                                : Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),

                    // Post Details
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title and Status
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _post.title,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (_post.isSold)
                                Container(
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
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Category and Type
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _post.category.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _post.type == 'service'
                                      ? Colors.purple.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _post.type == 'service'
                                      ? 'Service'
                                      : 'Product',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _post.type == 'service'
                                        ? Colors.purple.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Location
                          if (_post.location != null &&
                              _post.location!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _post.location!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 16),

                          // Barter Status and Price
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Barter Status',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _post.isOpenForBarter
                                              ? const Color(0xFFE8F5E9)
                                              : const Color(0xFFFFEBEE),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          _post.isOpenForBarter
                                              ? 'Open for Barter'
                                              : 'No Barter',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: _post.isOpenForBarter
                                                ? const Color(0xFF2E7D32)
                                                : const Color(0xFFC62828),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_formatPrice().isNotEmpty)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        const Text(
                                          'Price',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _formatPrice(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2E5BFF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Description
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
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
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _post.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Stats
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatItem(
                                  icon: Icons.remove_red_eye,
                                  value: '${_post.viewCount}',
                                  label: 'Views',
                                ),
                                _buildStatItem(
                                  icon: Icons.local_offer,
                                  value: '${_post.openOffersCount}',
                                  label: 'Offers',
                                ),
                                _buildStatItem(
                                  icon: Icons.calendar_today,
                                  value: DateFormat(
                                    'MMM dd',
                                  ).format(_post.postedDate),
                                  label: 'Posted',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Action Buttons
                          if (!_post.isSold)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _editPost,
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit Post'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _markAsSold,
                                      icon: const Icon(Icons.check_circle),
                                      label: const Text('Mark as Sold'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildImageGallery() {
    return Stack(
      children: [
        SizedBox(
          height: 300,
          width: double.infinity,
          child: PageView.builder(
            itemCount: _post.images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Image.network(
                _post.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.grey[500],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // Image counter
        if (_post.images.length > 1)
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentImageIndex + 1}/${_post.images.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
