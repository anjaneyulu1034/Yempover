import 'package:yempover_app/screens/LoginScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yempover_app/models/ProductPostmain.dart';
import 'package:yempover_app/models/my_post_model.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/my_posts_service.dart';
import 'package:yempover_app/screens/OfferDescriptionScreen.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import 'package:yempover_app/screens/AddPostScreen.dart';
import 'package:yempover_app/utils/barter_clubbing.dart';
import 'package:yempover_app/utils/error_message_utils.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:yempover_app/utils/wallet_offer_guard.dart';
import 'package:yempover_app/widgets/app_text_field.dart';

class OfferDeckScreen extends StatefulWidget {
  final Post post;
  final String currentUserId;
  final OfferSubmissionMode offerMode;
  // Explicit "no coins involved" request: the barter item becomes optional
  // (the user may submit with none selected) and no price/value-matching
  // rules apply.
  final bool isZeroCoin;
  // Services only (SERVICE_FOR_BARTER / its +coins variant): lets the
  // requester also pick from their own SERVICES, not just products — the
  // owner simply accepts/rejects, so unlike products there's no
  // value-matching requirement between what's picked and the listing.
  final bool allowServiceSelection;

  const OfferDeckScreen({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.offerMode,
    this.isZeroCoin = false,
    this.allowServiceSelection = false,
  });

  @override
  State<OfferDeckScreen> createState() => _OfferDeckScreenState();
}

class _OfferDeckScreenState extends State<OfferDeckScreen> {
  final MyPostsService _postsService = MyPostsService();
  final TextEditingController _quotedPriceController = TextEditingController();

  List<UserItem> _userItems = [];
  final List<UserItem> _selectedItems = [];
  // Services only — a second, independent selection (no clubbing/value
  // matching rules; services just get toggled on/off like a plain checklist).
  List<UserItem> _userServiceItems = [];
  final List<UserItem> _selectedServiceItems = [];
  bool _showingServicesTab = false;
  String? _quotedPriceError;
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  bool _isPostExpired(MyPost myPost) => myPost.isExpiredOrUnavailable;

  bool get _filtersToBarterPostsOnly =>
      widget.offerMode == OfferSubmissionMode.barter ||
      widget.offerMode == OfferSubmissionMode.both;

  bool _isBarterEligiblePost(MyPost myPost) {
    return myPost.isOpenForBarter ||
        myPost.status.trim().toUpperCase() == 'FOR_BARTER';
  }

  String get _emptyItemsMessage {
    if (widget.isZeroCoin) {
      return 'Item is optional for a zero-coin request — post items open for '
          'barter if you\'d like to offer one, or continue without one.';
    }
    if (_filtersToBarterPostsOnly) {
      return 'Post items open for barter to make this offer';
    }
    return 'Post items first to make an offer';
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
              !_filtersToBarterPostsOnly || _isBarterEligiblePost(myPost),
        )
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
            isClubbable: myPost.isClubbable,
          );
        })
        .toList();
  }

  // Services offered in the direct barter flow aren't clubbed/value-matched
  // like products, so this doesn't gate on isBarterEligiblePost or
  // isClubbable the way the product mapper does — the owner just accepts or
  // rejects whatever's picked.
  List<UserItem> _mapMyPostsToServiceItems(List<MyPost> posts) {
    return posts
        .where((myPost) => myPost.postedById == widget.currentUserId)
        .where((myPost) => myPost.type.toLowerCase() == 'service')
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
            isClubbable: false,
          );
        })
        .toList();
  }

  Widget _buildTabButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF1FF) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFF2E5BFF) : Colors.grey.shade300,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF2E5BFF) : Colors.grey.shade700,
          ),
        ),
      ),
    );
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

    if (widget.post.price > 0) {
      chips.add(
        _buildMetaChip(
          icon: Icons.monetization_on,
          label: CoinFormat.withLabel(widget.post.price),
          fg: const Color(0xFF1565C0),
          bg: const Color(0xFFE3F2FD),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }

  @override
  void dispose() {
    _quotedPriceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _requiresQuotedPrice => widget.offerMode == OfferSubmissionMode.both;

  double get _selectedBarterItemsCoinTotal =>
      _selectedItems.fold<double>(0, (sum, item) => sum + item.value);

  String? _validateQuotedPrice(String value) {
    if (!_requiresQuotedPrice) return null;

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Quoted price is required for Both offer';
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < 0) {
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
        if (widget.allowServiceSelection) {
          _userServiceItems = _mapMyPostsToServiceItems(response.data.posts);
        }
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = ErrorMessageUtils.sanitize(e);
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
        if (widget.allowServiceSelection) {
          _userServiceItems.addAll(
            _mapMyPostsToServiceItems(response.data.posts),
          );
        }
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
        if (widget.allowServiceSelection) {
          _userServiceItems = _mapMyPostsToServiceItems(response.data.posts);
        }
        _currentPage = response.data.pagination.page;
        _totalPages = response.data.pagination.pages;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to refresh items');
    }
  }

  void _toggleServiceSelection(UserItem item) {
    setState(() {
      final exists = _selectedServiceItems.any((i) => i.id == item.id);
      if (exists) {
        _selectedServiceItems.removeWhere((i) => i.id == item.id);
      } else {
        _selectedServiceItems.add(item);
      }
    });
  }

  void _removeSelectedServiceItem(UserItem item) {
    setState(() {
      _selectedServiceItems.removeWhere((i) => i.id == item.id);
    });
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

  void _revalidateQuotedPrice() {
    if (!_requiresQuotedPrice) return;
    _quotedPriceError = _validateQuotedPrice(_quotedPriceController.text);
  }

  /// Keeps the price field non-empty as the item selection changes, so
  /// picking items doesn't leave the field blank. There's no required
  /// minimum to quote — barter items alone are a valid "Both" offer, so this
  /// only fills in "0" and never overwrites a value the user already typed.
  void _syncQuotedPriceWithMinimum() {
    if (!_requiresQuotedPrice) return;

    if (_quotedPriceController.text.trim().isEmpty) {
      _quotedPriceController.text = '0';
    }
  }

  void _toggleItemSelection(UserItem item) {
    final result = applyClubbingSelection(
      current: _selectedItems,
      tapped: item,
    );
    setState(() {
      _selectedItems
        ..clear()
        ..addAll(result.items);
      _syncQuotedPriceWithMinimum();
      _revalidateQuotedPrice();
    });
    if (result.hint != null) {
      SnackbarUtils.showInfo(context, result.hint!);
    }
  }

  void _removeSelectedItem(UserItem item) {
    setState(() {
      _selectedItems.removeWhere((i) => i.id == item.id);
      _syncQuotedPriceWithMinimum();
      _revalidateQuotedPrice();
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
                        _emptyItemsMessage,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
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

  Future<void> _navigateToDescriptionScreen() async {
    final quotedPriceError = _validateQuotedPrice(_quotedPriceController.text);

    setState(() {
      _quotedPriceError = quotedPriceError;
    });

    if (!widget.isZeroCoin &&
        (widget.offerMode == OfferSubmissionMode.barter ||
            widget.offerMode == OfferSubmissionMode.both) &&
        _selectedItems.isEmpty &&
        _selectedServiceItems.isEmpty) {
      SnackbarUtils.showInfo(
        context,
        widget.allowServiceSelection
            ? 'Please select at least one product or service to continue.'
            : 'Please select at least one item to continue.',
      );
      return;
    }

    if (quotedPriceError != null) {
      SnackbarUtils.showInfo(context, quotedPriceError);
      return;
    }

    // No value-matching of any kind — a barter/both offer may be worth more
    // or less than the listing on either side. The receiver looks at what's
    // on the table and accepts or rejects; there's nothing to warn about.

    if (widget.offerMode == OfferSubmissionMode.both) {
      final quoted = double.tryParse(_quotedPriceController.text.trim());
      if (quoted != null && quoted > 0) {
        final canAfford = await WalletOfferGuard.ensureCanAfford(
          context,
          requiredCoins: quoted.round(),
          itemName: widget.post.title,
        );
        if (!canAfford || !mounted) return;

        await _showCoinDeductionNotice(quoted.round());
        if (!mounted) return;
      }
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
          selectedServiceItems: _selectedServiceItems,
          selectedBundleItems: const [],
          currentUserId: widget.currentUserId,
          isService: isService, // Pass the correct type
          offerMode: widget.offerMode,
          initialQuotedPrice: _quotedPriceController.text.trim(),
          isZeroCoin: widget.isZeroCoin,
        ),
      ),
    );
  }



  /// Purely informational notice so the user knows upfront how many coins
  /// this "Barter + Price" offer will cost them if the other party accepts it.
  Future<void> _showCoinDeductionNotice(int coins) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Coins to be Deducted'),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CoinIcon(size: 22, iconSize: 14),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'If this offer is accepted, ${CoinFormat.amount(coins)} '
                'coins will be deducted from your wallet.',
                style: const TextStyle(fontSize: 14.5, height: 1.35),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Okay'),
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
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //  // onPressed: () => Navigator.pop(context),
        // ),
        title: Text(
          widget.isZeroCoin ? "Zero-Coin Offer" : "Offer Deck",
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              if (widget.isZeroCoin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_box_outlined,
                          color: Colors.teal.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Zero-coin transaction — no coins involved. '
                            'Picking an item below is optional.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.teal.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

              // -------- OFFER DECK ROW ----------
              // Only the target listing goes here now — adding a new post
              // to offer from is already covered by the "Add New" tile in
              // the My Items row below, so the duplicate + card is gone.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 160,
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

              // -------- SELECTED SERVICES (Horizontal deck) ----------
              if (_selectedServiceItems.isNotEmpty)
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _selectedServiceItems.length,
                    itemBuilder: (context, index) {
                      final item = _selectedServiceItems[index];
                      return Container(
                        width: 80,
                        margin: const EdgeInsets.only(right: 10),
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.deepPurple.shade200,
                                ),
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
                                                  child: Icon(Icons.handyman),
                                                ),
                                              );
                                            },
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: Icon(Icons.handyman),
                                        ),
                                      ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () => _removeSelectedServiceItem(item),
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
                        decoration: AppInputDecoration.build(
                          label: 'Price Quote',
                          hint: 'Enter your price quote',
                          prefixIcon: coinInputPrefix(),
                          prefixIconConstraints: coinPrefixIconConstraints,
                          errorText: _quotedPriceError,
                          fillColor: Colors.grey.shade50,
                        ),
                      ),
                      if (_selectedItems.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Your items: ${CoinFormat.withUnit(_selectedBarterItemsCoinTotal)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Purely informational — any selection is valid for a barter
              // offer, so this is never a warning, just a running total.
              if (!widget.isZeroCoin &&
                  widget.offerMode == OfferSubmissionMode.barter &&
                  _selectedItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Your items: ${CoinFormat.withUnit(_selectedBarterItemsCoinTotal)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // -------- PRODUCTS / SERVICES TOGGLE (services flow only) ----------
              if (widget.allowServiceSelection)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTabButton(
                          label: 'My Products',
                          selected: !_showingServicesTab,
                          onTap: () =>
                              setState(() => _showingServicesTab = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildTabButton(
                          label: 'My Services',
                          selected: _showingServicesTab,
                          onTap: () =>
                              setState(() => _showingServicesTab = true),
                        ),
                      ),
                    ],
                  ),
                ),
              if (widget.allowServiceSelection) const SizedBox(height: 12),

              // -------- MY ITEMS TITLE ----------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _showingServicesTab ? "My Services" : "My Items",
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
              Builder(
                builder: (context) {
                  final activeItems = _showingServicesTab
                      ? _userServiceItems
                      : _userItems;
                  final activeSelected = _showingServicesTab
                      ? _selectedServiceItems
                      : _selectedItems;
                  void toggleActive(UserItem item) => _showingServicesTab
                      ? _toggleServiceSelection(item)
                      : _toggleItemSelection(item);

                  if (_isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_errorMessage != null) {
                    return Center(
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
                    );
                  }
                  if (activeItems.isEmpty) {
                    return Center(
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
                            _showingServicesTab
                                ? 'No services to offer'
                                : 'No items to offer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _showingServicesTab
                                ? 'Post a service to offer it here.'
                                : _emptyItemsMessage,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _openAddPostAndRefresh,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add Post'),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox(
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
                              1 + activeItems.length + (_isLoadingMore ? 1 : 0),
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

                            if (itemIndex == activeItems.length) {
                              return Container(
                                width: 80,
                                margin: const EdgeInsets.only(right: 12),
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final item = activeItems[itemIndex];
                            final selected = activeSelected.any(
                              (selectedItem) => selectedItem.id == item.id,
                            );

                            return GestureDetector(
                              onTap: () => toggleActive(item),
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
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (item.value > 0)
                                              Text(
                                                CoinFormat.withLabel(item.value),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 10,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
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
                    );
                },
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
