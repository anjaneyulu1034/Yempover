import 'package:Yempover_app/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:Yempover_app/models/ProductPostmain.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/services/my_posts_service.dart';
import 'package:Yempover_app/screens/OfferDescriptionScreen.dart';

class OfferDeckScreen extends StatefulWidget {
  final Post post;
  final String currentUserId;

  const OfferDeckScreen({
    super.key,
    required this.post,
    required this.currentUserId,
  });

  @override
  State<OfferDeckScreen> createState() => _OfferDeckScreenState();
}

class _OfferDeckScreenState extends State<OfferDeckScreen> {
  final MyPostsService _postsService = MyPostsService();
  final TokenService _tokenService = TokenService();

  List<UserItem> _userItems = [];
  List<UserItem> _selectedItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
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
      if (!_isLoadingMore && _currentPage < _totalPages) {
        _fetchMorePosts();
      }
    }
  }

  Future<void> _fetchMyPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isLoggedIn = await TokenService().isLoggedIn();
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
        // Convert MyPost objects to UserItem objects
        _userItems = response.data.posts.map((myPost) {
          return UserItem(
            id: myPost.id,
            name: myPost.title,
            description: myPost.description,
            imageUrl: myPost.images.isNotEmpty
                ? (myPost.images.first ?? '')
                : '',
            category: myPost.category.name,
            price: myPost.price ?? 0.0,
            value: myPost.price ?? 0.0,
          );
        }).toList();
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

      if (_errorMessage!.contains('Session expired') ||
          _errorMessage!.contains('Unauthorized') ||
          _errorMessage!.contains('No authentication token')) {
        if (mounted) {
          _showLoginDialog();
        }
      } else {
        _showErrorSnackBar(_errorMessage!);
      }
    }
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
        final newItems = response.data.posts.map((myPost) {
          return UserItem(
            id: myPost.id,
            name: myPost.title,
            description: myPost.description,
            imageUrl: myPost.images.isNotEmpty
                ? (myPost.images.first ?? '')
                : '',
            category: myPost.category.name,
            price: myPost.price ?? 0.0,
            value: myPost.price ?? 0.0,
          );
        }).toList();
        _userItems.addAll(newItems);
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingMore = false;
      });
      _showErrorSnackBar('Failed to load more items');
    }
  }

  Future<void> _refreshPosts() async {
    try {
      final response = await _postsService.getMyPosts(page: 1, limit: 20);

      if (!mounted) return;

      setState(() {
        _userItems = response.data.posts.map((myPost) {
          return UserItem(
            id: myPost.id,
            name: myPost.title,
            description: myPost.description,
            imageUrl: myPost.images.isNotEmpty
                ? (myPost.images.first ?? '')
                : '',
            category: myPost.category.name,
            price: myPost.price ?? 0.0,
            value: myPost.price ?? 0.0,
          );
        }).toList();
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to refresh items');
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Session Expired'),
          content: const Text('Please login again to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _toggleItemSelection(UserItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _removeSelectedItem(UserItem item) {
    setState(() {
      _selectedItems.remove(item);
    });
  }

  void _showItemsSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Items to Offer'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _userItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No items available',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Post items first to make an offer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _userItems.length,
                  itemBuilder: (context, index) {
                    final item = _userItems[index];
                    final isSelected = _selectedItems.contains(item);

                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (selected) {
                        setState(() {
                          if (selected == true) {
                            _selectedItems.add(item);
                          } else {
                            _selectedItems.remove(item);
                          }
                        });
                        Navigator.pop(context);
                        _showItemsSelectionDialog(); // Reopen to show updated selection
                      },
                      secondary: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child:
                            item.imageUrl != null && item.imageUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.image,
                                      size: 30,
                                      color: Colors.grey,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.image,
                                size: 30,
                                color: Colors.grey,
                              ),
                      ),
                      title: Text(
                        item.name ?? 'Untitled',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item.category ?? 'Uncategorized',
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToDescriptionScreen() {
    // Remove the check for selected items - allow empty selection
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDescriptionScreen(
          post: widget.post,
          selectedItems: _selectedItems,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getMonth(date.month)} ${date.day}, ${date.year}';
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
          "Offer Deck",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // -------- USER NAME ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: widget.post.postedBy.profileImage != null
                      ? NetworkImage(widget.post.postedBy.profileImage!)
                      : null,
                  child: widget.post.postedBy.profileImage == null
                      ? Text(
                          widget.post.postedBy.firstName.isNotEmpty
                              ? widget.post.postedBy.firstName[0]
                              : "U",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  "${widget.post.postedBy.firstName} ${widget.post.postedBy.lastName}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // -------- TEXT ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Add items to the deck make an offer",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // -------- OFFER DECK ROW ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // TARGET ITEM
                Expanded(
                  child: Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: widget.post.images.isNotEmpty
                          ? Image.network(
                              widget.post.images.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.image)),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey.shade200,
                              child: const Center(child: Icon(Icons.image)),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // ADD CARD
                Expanded(
                  child: InkWell(
                    onTap: _showItemsSelectionDialog,
                    child: Container(
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.shade200),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, size: 28),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // -------- SWAP ICON ----------
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.blue.shade200, width: 2),
              color: Colors.white,
            ),
            child: const Icon(Icons.swap_vert, color: Colors.blue),
          ),

          const SizedBox(height: 12),

          // -------- SELECTED ITEMS (Horizontal deck) ----------
          if (_selectedItems.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedItems.length,
                itemBuilder: (context, index) {
                  final item = _selectedItems[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 10),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child:
                                item.imageUrl != null &&
                                    item.imageUrl!.isNotEmpty
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: Icon(Icons.image),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: Icon(Icons.image),
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _removeSelectedItem(item),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // -------- MY ITEMS TITLE ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "My Items",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Tap to select",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // -------- MY ITEMS HORIZONTAL SCROLLING LIST ----------
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchMyPosts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _userItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        'No items to offer',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Post items first to make an offer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : SizedBox(
                  height: 150, // 👈 FIXED HEIGHT (adjust 130–160 if needed)
                  child: RefreshIndicator(
                    onRefresh: _refreshPosts,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _userItems.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _userItems.length) {
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final item = _userItems[index];
                        final selected = _selectedItems.contains(item);

                        return GestureDetector(
                          onTap: () => _toggleItemSelection(item),
                          child: Container(
                            width: 110, // slightly reduced width
                            margin: const EdgeInsets.only(right: 12),
                            child: Stack(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: selected
                                          ? Colors.blue
                                          : Colors.grey.shade200,
                                      width: selected ? 2 : 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child:
                                        item.imageUrl != null &&
                                            item.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            item.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: Colors.grey.shade200,
                                                    child: const Center(
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 30,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : Container(
                                            color: Colors.grey.shade200,
                                            child: const Center(
                                              child: Icon(
                                                Icons.image,
                                                size: 30,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),

                                if (selected)
                                  Positioned(
                                    top: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),

                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(14),
                                        bottomRight: Radius.circular(14),
                                      ),
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                    child: Text(
                                      item.name ?? 'Untitled',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
        ],
      ),

      // -------- BOTTOM BUTTONS ----------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text("Back"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                // Always enabled - no selection required
                onPressed: _navigateToDescriptionScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
