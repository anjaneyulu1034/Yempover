import 'package:YemPover_app/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:YemPover_app/models/ProductPostmain.dart';
import 'package:YemPover_app/models/my_post_model.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/services/my_posts_service.dart';
import 'package:YemPover_app/screens/OfferDescriptionScreen.dart';
import 'package:YemPover_app/screens/AddPostScreen.dart';
import 'package:YemPover_app/utils/snackbar_utils.dart';

class OfferDeckScreen extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final OfferSubmissionMode offerMode;

  const OfferDeckScreen({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.offerMode,
  });

  @override
  State<OfferDeckScreen> createState() => _OfferDeckScreenState();
}

class _OfferDeckScreenState extends State<OfferDeckScreen> {
  final MyPostsService _postsService = MyPostsService();
  final TextEditingController _quotedPriceController = TextEditingController();

  List<UserItem> _userItems = [];
  final List<UserItem> _selectedItems = [];
  String? _quotedPriceError;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  bool _isPostExpired(MyPost myPost) {
    if (myPost.hasExpired) return true;

    final status = myPost.status.trim().toUpperCase();
    if (status == 'EXPIRED') return true;

    final validUntil = myPost.validUntil;
    if (validUntil != null && !validUntil.isAfter(DateTime.now())) {
      return true;
    }

    final remainingTime = (myPost.remainingTime ?? '').trim().toLowerCase();
    if (remainingTime.contains('expired')) return true;

    return false;
  }

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
    _scrollController.addListener(_onScroll);
  }

  List<UserItem> _mapMyPostsToUserItems(List<MyPost> posts) {
    return posts
        .where((myPost) => myPost.postedById == widget.currentUserId)
        .where((myPost) => myPost.type.toLowerCase() == 'product')
        .where((myPost) => myPost.isListed == true)
        .where((myPost) => !_isPostExpired(myPost))
        .where(
          (myPost) =>
              myPost.status.toUpperCase() != 'SOLD' &&
              myPost.status.toUpperCase() != 'ARCHIVED' &&
              myPost.status.toUpperCase() != 'DELETED',
        )
        .map((myPost) {
          return UserItem(
            id: myPost.id,
            name: myPost.title,
            description: myPost.description,
            imageUrl: myPost.images.isNotEmpty ? myPost.images.first : '',
            category: myPost.category.name,
            price: myPost.price ?? 0.0,
            value: myPost.price ?? 0.0,
          );
        })
        .toList();
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color fg,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPostMetaTags() {
    final List<Widget> chips = [];

    if (widget.post.isListed) {
      chips.add(
        _buildMetaChip(
          icon: Icons.check_circle_outline,
          label: 'Open',
          fg: const Color(0xFF2E7D32),
          bg: const Color(0xFFEAF7ED),
        ),
      );
    }

    if (widget.post.isForBarter) {
      chips.add(
        _buildMetaChip(
          icon: Icons.sync_alt,
          label: 'Open for Barter',
          fg: const Color(0xFF3F51B5),
          bg: const Color(0xFFE8EAF6),
        ),
      );
    }

    if (widget.post.canClubItems) {
      chips.add(
        _buildMetaChip(
          icon: Icons.all_inclusive,
          label: 'Can be Clubbed',
          fg: const Color(0xFF00695C),
          bg: const Color(0xFFE0F2F1),
        ),
      );
    }

    chips.add(
      _buildMetaChip(
        icon: widget.post.type == PostType.service
            ? Icons.handyman_outlined
            : Icons.inventory_2_outlined,
        label: widget.post.type == PostType.service ? 'Service' : 'Product',
        fg: const Color(0xFF37474F),
        bg: const Color(0xFFECEFF1),
      ),
    );

    // Temporarily hidden: coins/price chip is not needed right now.
    // if (widget.post.price > 0) {
    //   chips.add(
    //     _buildMetaChip(
    //       icon: Icons.attach_money,
    //       label: widget.post.formattedPrice,
    //       fg: const Color(0xFF1565C0),
    //       bg: const Color(0xFFE3F2FD),
    //     ),
    //   );
    // }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  @override
  void dispose() {
    _quotedPriceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _requiresQuotedPrice => widget.offerMode == OfferSubmissionMode.both;

  String? _validateQuotedPrice(String value) {
    if (!_requiresQuotedPrice) return null;

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Quoted price is required for Both offer';
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid price';
    }

    if (trimmed.length > 9) {
      return 'Price is too large';
    }

    return null;
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
        _userItems = _mapMyPostsToUserItems(response.data.posts);
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
        final newItems = _mapMyPostsToUserItems(response.data.posts);
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
        _userItems = _mapMyPostsToUserItems(response.data.posts);
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
    SnackbarUtils.showError(context, message);
  }

  void _toggleItemSelection(UserItem item) {
    setState(() {
      final existingIndex = _selectedItems.indexWhere((i) => i.id == item.id);
      if (existingIndex != -1) {
        _selectedItems.removeAt(existingIndex);
      } else {
        _selectedItems.add(item);
      }
    });
  }

  void _removeSelectedItem(UserItem item) {
    setState(() {
      _selectedItems.removeWhere((i) => i.id == item.id);
    });
  }

  Future<void> _openAddPostAndRefresh() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPostScreen(
          onPostAdded: () {
            _refreshPosts();
          },
        ),
      ),
    );

    if (!mounted) return;
    await _refreshPosts();
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
                        child: item.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl,
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
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        item.category,
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
    final quotedPriceError = _validateQuotedPrice(_quotedPriceController.text);

    setState(() {
      _quotedPriceError = quotedPriceError;
    });

    if ((widget.offerMode == OfferSubmissionMode.barter ||
            widget.offerMode == OfferSubmissionMode.both) &&
        _selectedItems.isEmpty) {
      SnackbarUtils.showInfo(
        context,
        'Please select at least one item to continue.',
      );
      return;
    }

    if (quotedPriceError != null) {
      SnackbarUtils.showInfo(context, quotedPriceError);
      return;
    }

    // Determine if the post is a service
    final bool isService = widget.post.type == PostType.service;

    debugPrint(
      '📱 Navigating to OfferDescriptionScreen - isService: $isService',
    );
    debugPrint('📱 Post ID: ${widget.post.id}');
    debugPrint('📱 Post Type: ${widget.post.type}');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDescriptionScreen(
          post: widget.post,
          selectedItems: _selectedItems,
          selectedBundleItems: const [],
          currentUserId: widget.currentUserId,
          isService: isService, // Pass the correct type
          offerMode: widget.offerMode,
          initialQuotedPrice: _quotedPriceController.text.trim(),
        ),
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
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //  // onPressed: () => Navigator.pop(context),
        // ),
        title: const Text(
          "Offer Deck",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // -------- USER NAME ----------
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildTargetPostMetaTags(),
                ),
              ),

              const SizedBox(height: 12),

              if (_requiresQuotedPrice) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quoted Price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _quotedPriceController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                        onChanged: (_) {
                          setState(() {
                            _quotedPriceError = _validateQuotedPrice(
                              _quotedPriceController.text,
                            );
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Enter your price quote',
                          prefixText: '\$ ',
                          errorText: _quotedPriceError,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade400),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide(
                              color: Color(0xFF2E5BFF),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

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
                                      child: const Center(
                                        child: Icon(Icons.image),
                                      ),
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
                        onTap: _openAddPostAndRefresh,
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

              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Tap + to add new post',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
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
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
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
                          Icon(
                            Icons.inbox,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
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
                      height: 150,
                      child: RefreshIndicator(
                        onRefresh: _refreshPosts,
                        color: const Color(0xFF2E5BFF),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        strokeWidth: 2.2,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount:
                              1 + _userItems.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return GestureDetector(
                                onTap: _openAddPostAndRefresh,
                                child: Container(
                                  width: 110,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                      width: 1.2,
                                    ),
                                    color: Colors.blue.shade50,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.add_circle_outline,
                                        color: Colors.blue,
                                        size: 28,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Add New',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final itemIndex = index - 1;

                            if (itemIndex == _userItems.length) {
                              return Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final item = _userItems[itemIndex];
                            final selected = _selectedItems.any(
                              (selectedItem) => selectedItem.id == item.id,
                            );

                            return GestureDetector(
                              onTap: () => _toggleItemSelection(item),
                              child: Container(
                                width: 110,
                                height: 140,
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
                                        child: Container(
                                          color: Colors.grey.shade100,
                                          child: item.imageUrl.isNotEmpty
                                              ? Image.network(
                                                  item.imageUrl,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
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
                                          color: Colors.black.withValues(
                                            alpha: 0.5,
                                          ),
                                        ),
                                        child: Text(
                                          item.name,
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
        ),
      ),

      // -------- BOTTOM BUTTONS ----------
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.only(left: 16, right: 16, top: 10, bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, -4),
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
                    side: const BorderSide(color: Colors.grey),
                  ),
                  child: const Text(
                    "Back",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _navigateToDescriptionScreen,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
