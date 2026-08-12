import 'package:flutter/material.dart';
import 'package:yempover_app/models/ProductPostmain.dart';
import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:yempover_app/screens/OfferDeckScreen.dart';
import 'package:yempover_app/screens/OfferDescriptionScreen.dart';
import 'package:yempover_app/screens/service/ServiceDetailBookingScreen.dart';
import 'package:yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:yempover_app/services/api_service.dart';
import 'package:yempover_app/services/post_action_service.dart';
import 'package:yempover_app/services/resume_state_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/utils/loading_widget.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:yempover_app/utils/wallet_offer_guard.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import 'package:yempover_app/widgets/safe_network_image.dart';
import 'package:yempover_app/widgets/app_text_field.dart';

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
  final TokenService _tokenService = TokenService();
  final PostActionService _postActionService = PostActionService();
  final TradeChatService _tradeChatService = TradeChatService();
  bool _isOpeningExistingChat = false;
  bool _isFetchingExchangeModes = false;

  late Post _post;
  bool _isLoading = false;
  bool _isNoLongerAvailable = false;
  String? _noLongerAvailableMessage;
  bool _isFavorite = false;
  bool _isFavoriteUpdating = false;
  String? _currentUserId;
  Map<String, dynamic>? _otherUserProfile;
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();
  bool _isGuestUser = false;

  bool get _isOwnPost {
    final current = (_currentUserId ?? '').trim();
    if (current.isEmpty) return false;

    final postedById = _post.postedById.trim();
    final postedByNestedId = _post.postedBy.id.trim();
    return current == postedById || current == postedByNestedId;
  }

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadCurrentUser();
    _loadPostDetails();
    _checkIfFavorite(); // Check if post is already favorited
    _loadGuestFlag();
    ResumeStateService.savePost(
      widget.post.id,
      isService: widget.post.type == PostType.service,
    );
  }

  Future<void> _loadGuestFlag() async {
    try {
      final isGuest = await _tokenService.isGuestUser();
      if (!mounted) return;
      setState(() => _isGuestUser = isGuest);
    } catch (_) {}
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUserId = await _tokenService.getUserId();
      debugPrint('👤 Current user ID: $_currentUserId');
    } catch (e) {
      debugPrint('❌ Error loading current user: $e');
    }
  }

  Future<void> _loadPostDetails() async {
    try {
      setState(() => _isLoading = true);
      final response = await _apiService.getPostDetail(
        postId: _post.id,
        type: _post.type,
      );
      if (!mounted) return;
      setState(() {
        _post = response.post;
        _currentImageIndex = 0;
        _isLoading = false;
        _isNoLongerAvailable = false;
        _noLongerAvailableMessage = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 410) {
        setState(() {
          _isLoading = false;
          _isNoLongerAvailable = true;
          _noLongerAvailableMessage = e.message;
        });
        return;
      }

      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load post details: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load post details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    ResumeStateService.clearIfCurrent('post', widget.post.id);
    _imagePageController.dispose();
    super.dispose();
  }

  // Check if post is in user's favorites
  Future<void> _checkIfFavorite() async {
    try {
      final isLoggedIn = await _tokenService.isLoggedIn();
      if (!isLoggedIn) {
        if (!mounted) return;
        setState(() {
          _isFavorite = false;
        });
        return;
      }

      final favoritesResponse = await _postActionService.getFavorites(
        page: 1,
        limit: 100,
      );

      final isFavorited = favoritesResponse.data.favorites.any(
        (favorite) => favorite.actualPostId == _post.id,
      );

      if (!mounted) return;
      setState(() {
        _isFavorite = isFavorited;
      });
    } catch (e) {
      debugPrint('🔴 Error checking favorite status: $e');
    }
  }

  // Feature 1: route into the viewer's existing chat/offer on this listing
  // instead of letting them create a second one.
  Future<void> _navigateToExistingChat() async {
    final chatId = _post.existingOffer?.chatId;
    if (chatId == null || chatId.isEmpty || _isOpeningExistingChat) return;

    setState(() => _isOpeningExistingChat = true);
    try {
      final chat = await _tradeChatService.getChatById(chatId);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chat: chat,
            currentUserId: _currentUserId!,
            onChatUpdated: (_) {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Could not open the chat: $e');
    } finally {
      if (mounted) setState(() => _isOpeningExistingChat = false);
    }
  }

  // Navigate to Offer Deck
  Future<void> _navigateToOfferDeck() async {
    if (_isNoLongerAvailable) return;

    final isGuest = await _tokenService.isGuestUser();
    final isLoggedIn = await _tokenService.isLoggedIn();
    if (!mounted) return;
    if (isGuest || !isLoggedIn || _currentUserId == null) {
      SnackbarUtils.showGuestLoginToast(
        context,
        message:
            'Please login or create an account to make an offer.',
      );
      return;
    }

    if (_post.type == PostType.service) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailBookingScreen(serviceId: _post.id),
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

    // Feature 3: always offer the full exchange-mode picker (backend-driven,
    // includes cross-mode requests like barter on a pure-price listing)
    // instead of a static local list gated on the listing's native mode.
    if (_isFetchingExchangeModes) return;
    setState(() => _isFetchingExchangeModes = true);

    ExchangeModeOptions options;
    try {
      options = await _tradeChatService.getExchangeModeOptions(
        productId: _post.id,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFetchingExchangeModes = false);
      SnackbarUtils.showError(context, 'Could not load offer options: $e');
      return;
    }
    if (!mounted) return;
    setState(() => _isFetchingExchangeModes = false);

    if (!options.canRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot make an offer on this item right now'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedOption = await _showExchangeModeSheet(options);
    if (!mounted || selectedOption == null) return;

    if (selectedOption.isCrossMode) {
      final confirmed = await _confirmCrossModeOption(selectedOption);
      if (!mounted || confirmed != true) return;
    }

    final offerMode = _mapOfferTypeToSubmissionMode(selectedOption.offerType);

    if (!selectedOption.requiresProductSelection) {
      final hasEnoughBalance = await _ensureSufficientWalletBalance();
      if (!mounted || !hasEnoughBalance) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfferDescriptionScreen(
            post: _post,
            selectedItems: const [],
            currentUserId: _currentUserId!,
            offerMode: offerMode,
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDeckScreen(
          post: _post,
          currentUserId: _currentUserId!,
          offerMode: offerMode,
        ),
      ),
    );
  }

  Future<bool> _ensureSufficientWalletBalance({double? offerAmount}) async {
    final required = offerAmount ?? _post.price;
    if (required <= 0) return true;

    return WalletOfferGuard.ensureCanAfford(
      context,
      requiredCoins: required,
      itemName: _post.title,
    );
  }

  OfferSubmissionMode _mapOfferTypeToSubmissionMode(String offerType) {
    switch (offerType) {
      case 'BARTER':
        return OfferSubmissionMode.barter;
      case 'BOTH':
        return OfferSubmissionMode.both;
      default:
        return OfferSubmissionMode.price;
    }
  }

  // "This product is for pure price, but you can request a barter.
  // Continue?" — shown before proceeding with a cross-mode option.
  Future<bool?> _confirmCrossModeOption(ExchangeModeOption option) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(option.label),
        content: Text(option.note),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<ExchangeModeOption?> _showExchangeModeSheet(
    ExchangeModeOptions options,
  ) async {
    return showModalBottomSheet<ExchangeModeOption>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How do you want to exchange?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (options.listingPrice != null && options.listingPrice! > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Listed at \$${options.listingPrice!.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
              const SizedBox(height: 14),
              ...options.options.map(_buildExchangeModeCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExchangeModeCard(ExchangeModeOption option) {
    final isBarterFlavored =
        option.mode == 'PURE_BARTER' || option.mode == 'SERVICE_FOR_BARTER';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: isBarterFlavored
          ? const Icon(Icons.swap_horiz, color: Colors.orange, size: 32)
          : const CoinIcon(size: 32, iconSize: 20),
      title: Row(
        children: [
          Flexible(
            child: Text(
              option.label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (option.isCrossMode) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Request',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        option.note,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      onTap: () => Navigator.pop(context, option),
    );
  }

  // Toggle favorite status
  Future<void> _toggleFavorite() async {
    if (_isFavoriteUpdating) return;

    final previousFavoriteState = _isFavorite;

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
        _isFavoriteUpdating = true;
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
            _isFavoriteUpdating = false;
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
            _isFavoriteUpdating = false;
          });
          SnackbarUtils.showSuccess(context, response.message);
        }
      }
    } catch (e) {
      final errorText = e.toString().toLowerCase();

      if (!mounted) return;

      setState(() {
        _isFavoriteUpdating = false;
      });

      // Keep heart selected if backend says it's already favorited.
      if (errorText.contains('already favorited') ||
          errorText.contains('already in favorites')) {
        setState(() {
          _isFavorite = true;
        });
        SnackbarUtils.showInfo(context, 'Already in favorites');
        return;
      }

      // Keep heart unselected if backend says favorite does not exist.
      if (errorText.contains('not in favorites') ||
          errorText.contains('favorite not found')) {
        setState(() {
          _isFavorite = false;
        });
        return;
      }

      // Revert optimistic state for all other errors.
      setState(() {
        _isFavorite = previousFavoriteState;
      });

      SnackbarUtils.showError(context, e);
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
          builder: (context) {
            final reportId = response.data.report.id.toString();
            return AlertDialog(
              scrollable: true,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF2E5BFF),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Report Submitted',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13.5,
                        height: 1.35,
                      ),
                      children: [
                        const TextSpan(text: 'You reported '),
                        TextSpan(
                          text: '"${_post.title}"',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: ' for '),
                        TextSpan(
                          text: reason,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Our team will review this post within 24 hours.',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Report ID',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SelectableText(
                      reportId,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E5BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            );
          },
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
    if (_isOwnPost) {
      SnackbarUtils.showInfo(context, 'You cannot report your own post');
      return;
    }

    String selectedReason = 'Spam';
    TextEditingController reportController = TextEditingController();
    const reportFieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        String? validationError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final mediaQuery = MediaQuery.of(context);
            final maxContentHeight = (mediaQuery.size.height * 0.5) -
                mediaQuery.viewInsets.bottom -
                120;

            return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Report Post'),
            content: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: maxContentHeight.clamp(160.0, 360.0),
              ),
              child: SingleChildScrollView(
                child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Select reason for reporting this post:'),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
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
                    DropdownMenuItem(
                      value: 'Fake',
                      child: Text('Fake Post'),
                    ),
                    DropdownMenuItem(
                      value: 'Duplicate',
                      child: Text('Duplicate Post'),
                    ),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (value) {
                    selectedReason = value ?? 'Spam';
                  },
                  decoration: const InputDecoration(
                    border: reportFieldBorder,
                    enabledBorder: reportFieldBorder,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                        color: Color(0xFF3B82F6),
                        width: 1.4,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reportController,
                  onChanged: (_) {
                    if (validationError != null) {
                      setDialogState(() => validationError = null);
                    }
                  },
                  decoration: AppInputDecoration.build(
                    label: 'Additional details',
                    hint: 'Required...',
                    errorText: validationError,
                    alignLabelWithHint: true,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  maxLines: 3,
                ),
              ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF334155),
                  side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final description = reportController.text.trim();
                  if (description.isEmpty) {
                    setDialogState(() {
                      validationError =
                          'Additional details are required.';
                    });
                    return;
                  }

                  _reportPost(selectedReason, description);
                  Navigator.pop(dialogContext);
                },
                child: const Text('Submit Report'),
              ),
            ],
          );
          },
        );
      },
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
              onTap: _isFavoriteUpdating
                  ? null
                  : () {
                      _toggleFavorite();
                      Navigator.pop(context);
                    },
            ),
            const Divider(height: 1),
            if (!_isOwnPost)
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
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: _loadOtherUserProfile(forceRefresh: true),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.45,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final data = snapshot.data ?? _fallbackOtherUserProfile();
          final firstName = (data['firstName']?.toString() ?? '').trim();
          final lastName = (data['lastName']?.toString() ?? '').trim();
          final fullName = '$firstName $lastName'.trim().isNotEmpty
              ? '$firstName $lastName'.trim()
              : _post.postedBy.fullName;
          final profileImage = data['profileImage']?.toString();
          final registrationRaw = data['registrationDate']?.toString();
          final registrationDate = registrationRaw != null
              ? DateTime.tryParse(registrationRaw)?.toLocal()
              : null;
          final trades = data['totalTradesCompleted'] is num
              ? (data['totalTradesCompleted'] as num).toInt()
              : int.tryParse(data['totalTradesCompleted']?.toString() ?? '0') ??
                    0;
          final posts = data['totalPosts'] is num
              ? (data['totalPosts'] as num).toInt()
              : int.tryParse(data['totalPosts']?.toString() ?? '0') ?? 0;
          final shareEmail = data['shareEmail'] == true;
          final sharePhone = data['sharePhone'] == true;
          final location =
              (data['homeAddress']?.toString() ?? '').trim().isNotEmpty
              ? data['homeAddress'].toString()
              : _post.location;
          final email = data['email']?.toString();
          final mobileNumber = data['mobileNumber']?.toString();

          return SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade200,
                    child: (profileImage != null && profileImage.isNotEmpty)
                        ? ClipOval(
                            child: SafeNetworkImage(
                              url: profileImage,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              errorWidget: Text(
                                fullName.isNotEmpty
                                    ? fullName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          )
                        : Text(
                            fullName.isNotEmpty
                                ? fullName[0].toUpperCase()
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
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    registrationDate != null
                        ? 'Member since ${_formatDate(registrationDate)}'
                        : 'Member information unavailable',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Posts', '$posts'),
                      _buildStatItem('Rating', '-'),
                      _buildStatItem('Trades', '$trades'),
                    ],
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 20),

                  ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.blue,
                    ),
                    title: const Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(location),
                  ),

                  if (shareEmail && (email ?? '').isNotEmpty)
                    ListTile(
                      leading: const Icon(
                        Icons.email_outlined,
                        color: Colors.blue,
                      ),
                      title: const Text(
                        'Email',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(email!),
                    ),

                  if (sharePhone && (mobileNumber ?? '').isNotEmpty)
                    ListTile(
                      leading: const Icon(
                        Icons.phone_outlined,
                        color: Colors.blue,
                      ),
                      title: const Text(
                        'Phone',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(mobileNumber!),
                    ),

                  if (snapshot.hasError)
                    Padding(padding: const EdgeInsets.only(top: 12)),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _fallbackOtherUserProfile() {
    return {
      'firstName': _post.postedBy.firstName,
      'lastName': _post.postedBy.lastName,
      'profileImage': _post.postedBy.profileImage,
      'homeAddress': _post.postedBy.homeAddress ?? _post.location,
      'registrationDate': _post.postedDate.toIso8601String(),
      'totalPosts': 0,
      'totalTradesCompleted': 0,
      'shareEmail': false,
      'sharePhone': false,
    };
  }

  Future<Map<String, dynamic>> _loadOtherUserProfile({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _otherUserProfile != null) {
      return _otherUserProfile!;
    }

    final targetUserId = _post.postedById.trim().isNotEmpty
        ? _post.postedById.trim()
        : _post.postedBy.id.trim();

    if (targetUserId.isEmpty) {
      throw Exception('Unable to resolve post owner id for profile lookup');
    }

    debugPrint(
      '👤 PostDetailScreen: Loading profile for userId: $targetUserId',
    );

    final profile = await _apiService.getOtherUserProfile(targetUserId);
    _otherUserProfile = profile;
    return profile;
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
    final images = _post.processedImages;

    if (images.isEmpty) {
      return Container(
        height: 300,
        width: double.infinity,
        color: Colors.grey.shade200,
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            controller: _imagePageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return SafeNetworkImage(
                url: images[index],
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              );
            },
          ),
          // Image indicator
          if (images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final isActive = index == _currentImageIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 10 : 8,
                    height: isActive ? 10 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: isActive ? 1.0 : 0.45,
                      ),
                    ),
                  );
                }),
              ),
            ),
          if (images.length > 1)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
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
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
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
    final categoryName = _post.category.name.trim().isNotEmpty
        ? _post.category.name.trim()
        : 'Uncategorized';
    final serviceLocation = _post.location.trim().isNotEmpty
        ? _post.location
        : 'Location not specified';
    final providerArea = (_post.postedBy.homeAddress ?? '').trim();
    final hasCoordinates = _post.latitude != null && _post.longitude != null;

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
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoPill(Icons.category_outlined, categoryName),
              _buildInfoPill(
                Icons.visibility_outlined,
                '${_post.viewCount} views',
              ),
              _buildCoinPricePill(
                _post.price > 0 ? _post.formattedPrice : 'Price on request',
              ),
              _buildInfoPill(
                _post.isListed
                    ? Icons.check_circle_outline
                    : Icons.block_outlined,
                _post.isListed ? 'Listed' : 'Unlisted',
              ),
              if (hasCoordinates)
                _buildInfoPill(Icons.my_location_outlined, 'Geo-tagged'),
            ],
          ),
          const SizedBox(height: 14),
          _buildServiceMetaRow(
            icon: Icons.location_on_outlined,
            label: 'Service location',
            value: serviceLocation,
          ),
          if (providerArea.isNotEmpty)
            _buildServiceMetaRow(
              icon: Icons.home_work_outlined,
              label: 'Provider area',
              value: providerArea,
            ),
          if (hasCoordinates)
            _buildServiceMetaRow(
              icon: Icons.pin_drop_outlined,
              label: 'Coordinates',
              value:
                  '${_post.latitude!.toStringAsFixed(5)}, ${_post.longitude!.toStringAsFixed(5)}',
            ),
          _buildServiceMetaRow(
            icon: Icons.event_outlined,
            label: 'Posted on',
            value: _formatDate(_post.postedDate),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoinPricePill(String text) {
    final label = text == 'Price on request' ? text : '$text coins';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 16, iconSize: 10),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceMetaRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTag({
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
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostStatusTags() {
    final tags = <Widget>[
      _buildStatusTag(
        icon: _post.isListed
            ? Icons.check_circle_outline
            : Icons.block_outlined,
        label: _post.isListed ? 'Open' : 'Unlisted',
        fg: _post.isListed ? const Color(0xFF2E7D32) : const Color(0xFF616161),
        bg: _post.isListed ? const Color(0xFFEAF7ED) : const Color(0xFFEEEEEE),
      ),
      _buildStatusTag(
        icon: _post.type == PostType.service
            ? Icons.handyman_outlined
            : Icons.inventory_2_outlined,
        label: _post.type == PostType.service ? 'Service' : 'Product',
        fg: const Color(0xFF37474F),
        bg: const Color(0xFFECEFF1),
      ),
    ];

    if (_post.isForBarter) {
      tags.add(
        _buildStatusTag(
          icon: Icons.sync_alt,
          label: 'Open for Barter',
          fg: const Color(0xFF3F51B5),
          bg: const Color(0xFFE8EAF6),
        ),
      );
    }

    if (_post.canClubItems) {
      tags.add(
        _buildStatusTag(
          icon: Icons.all_inclusive,
          label: 'Can be Clubbed',
          fg: const Color(0xFF00695C),
          bg: const Color(0xFFE0F2F1),
        ),
      );
    }

    return Wrap(spacing: 8, runSpacing: 8, children: tags);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F9FF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isGuestUser) ...[
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.black,
              ),
              onPressed: _isFavoriteUpdating ? null : _toggleFavorite,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: _showPostOptions,
            ),
          ],
        ],
      ),

      body: _isLoading
          ? const Center(child: LoadingWidget())
          : _isNoLongerAvailable
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Colors.orange,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No longer available',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (_noLongerAvailableMessage ?? '').trim().isNotEmpty
                              ? _noLongerAvailableMessage!
                                  .replaceFirst('Exception: ', '')
                              : 'This item is no longer available.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
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
                          CoinPriceLabel(
                            text: '${_post.formattedPrice} coins',
                            iconSize: 22,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),

                        const SizedBox(height: 12),
                        _buildPostStatusTags(),
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

      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // Feature 1: owners never see "Make an Offer"; a viewer with a prior
  // offer/chat on this listing sees a banner routing into it instead of a
  // fresh offer button, so this stays correct across re-searches/re-logins.
  Widget? _buildBottomActionBar() {
    if (_isNoLongerAvailable || _post.isOwner) return null;

    final existingOffer = _post.existingOffer;
    if (existingOffer != null) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC9DBFF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF2E5BFF),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        existingOffer.displayText,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isOpeningExistingChat
                      ? null
                      : _navigateToExistingChat,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5BFF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isOpeningExistingChat
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Go to Chat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _navigateToOfferDeck(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5BFF),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _post.type == PostType.service
                  ? 'Open Service Booking'
                  : 'Make an Offer',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
