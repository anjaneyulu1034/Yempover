import 'dart:async';

import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yempover_app/models/ProductPostmain.dart';
import 'package:yempover_app/payment/SubscriptionScreen.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import 'package:yempover_app/utils/error_message_utils.dart';
import 'package:yempover_app/utils/wallet_offer_guard.dart';
import 'package:yempover_app/widgets/app_text_field.dart';
import 'package:yempover_app/services/socket_io/socket_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/widgets/safe_network_image.dart';

enum OfferSubmissionMode { price, barter, both }

class OfferDescriptionScreen extends StatefulWidget {
  final Post post;
  final List<UserItem> selectedItems;
  // Services offered in exchange (service-for-barter direct flow) —
  // alongside or instead of selectedItems (products).
  final List<UserItem> selectedServiceItems;
  final List<UserItem> selectedBundleItems;
  final String currentUserId;
  final bool isService;
  final OfferSubmissionMode offerMode;
  final String? initialQuotedPrice;
  // Explicit "no coins involved" request — the barter item is optional and
  // no price is ever sent, regardless of offerMode.
  final bool isZeroCoin;

  const OfferDescriptionScreen({
    super.key,
    required this.post,
    required this.selectedItems,
    this.selectedServiceItems = const [],
    this.selectedBundleItems = const [],
    required this.currentUserId,
    this.isService = false,
    required this.offerMode,
    this.initialQuotedPrice,
    this.isZeroCoin = false,
  });

  @override
  State<OfferDescriptionScreen> createState() => _OfferDescriptionScreenState();
}

class _OfferDescriptionScreenState extends State<OfferDescriptionScreen> {
  final TradeChatService _chatService = TradeChatService();
  final SocketService _socketService = SocketService();
  final TokenService _tokenService = TokenService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _isSubmitting = false;
  String? _priceError;
  String? _descriptionError;

  bool get _requiresPrice =>
      widget.offerMode == OfferSubmissionMode.price ||
      widget.offerMode == OfferSubmissionMode.both;

  bool get _requiresBarterItems =>
      widget.offerMode == OfferSubmissionMode.barter ||
      widget.offerMode == OfferSubmissionMode.both;

  @override
  void initState() {
    super.initState();

    // Only pre-fill from a quote already entered on the previous screen
    // (the "Both" barter + price flow). Don't default to the listing's
    // price here — that's not an offer, it's just paying full price, and
    // it's too easy to submit without noticing. The user should always
    // type the amount they actually want to offer.
    final initialQuotedPrice = widget.initialQuotedPrice?.trim() ?? '';
    if (initialQuotedPrice.isNotEmpty) {
      _priceController.text = initialQuotedPrice;
    }
  }

  // "+N more" in the Offer Summary card only shows the first 2 selected
  // items inline — this lists every selected item (image, name, value) so
  // the rest aren't hidden with no way to see what they are.
  void _showAllSelectedItemsDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Items you\'re offering'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _allSelectedItems.length,
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final item = _allSelectedItems[index];
              return Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: item.imageUrl.isNotEmpty
                        ? SafeNetworkImage(
                            url: item.imageUrl,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 36,
                            height: 36,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 13)),
                        if (item.value > 0)
                          Text(
                            CoinFormat.withLabel(item.value),
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Products + services together, in that order, for the free-text
  // title/images snapshot — barterProducts/barterServices (resolved
  // server-side from the id lists) are what's actually rendered in the
  // chat, this is just the legacy fallback text/images.
  List<UserItem> get _allSelectedItems => [
    ...widget.selectedItems,
    ...widget.selectedServiceItems,
  ];

  String _buildOfferTitle() {
    final items = _allSelectedItems;
    if (items.isEmpty) {
      return 'Offer for ${widget.post.title}';
    }

    if (items.length == 1) {
      return items.first.name;
    }

    final firstTwo = items.take(2).map((item) => item.name).join(', ');
    final remaining = items.length - 2;
    return remaining > 0 ? '$firstTwo +$remaining more' : firstTwo;
  }

  List<String> _buildOfferImages() {
    return _allSelectedItems
        .map((item) => item.imageUrl)
        .where((url) => url.trim().isNotEmpty)
        .toList();
  }

  // The item names themselves are already shown separately (offer summary
  // card, barter exchange preview, "You are offering: X" line) — this field
  // should only ever carry the offerer's own free-text note, not a
  // duplicate, unlabeled restatement of the item name.
  String _buildOfferDescription() => _descriptionController.text.trim();

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _showSubscriptionExpiredDialog() async {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Subscription Expired'),
        content: const Text(
          'Your subscription has expired or is inactive. Please renew to continue sending offers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SubscriptionScreen(),
                ),
              );
            },
            child: const Text('Renew Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAcceptedOfferConflictAndRedirect(String message) async {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const TradeChatScreen()),
      (route) => false,
    );
  }

  // This screen is reachable straight from a post listing, so the chat
  // socket may never have connected yet (unlike ChatDetailScreen, which
  // always connects on open). Best-effort: connect if needed, then relay —
  // never throws, never blocks the caller's success flow.
  Future<void> _relayOfferCreated(String chatId, TradeOffer offer) async {
    try {
      if (!_socketService.isConnected) {
        final token = await _tokenService.getToken();
        if (token == null || token.isEmpty) return;
        _socketService.init(token: token);

        final start = DateTime.now();
        while (DateTime.now().difference(start) < const Duration(seconds: 5)) {
          if (_socketService.isConnected) break;
          await Future.delayed(const Duration(milliseconds: 120));
        }
      }
      _socketService.emitOfferCreated(chatId, offer.toJson());
    } catch (e) {
      print('⚠️ Could not relay offer over socket: $e');
    }
  }

  Future<void> _submitOffer() async {
    final priceValidationError = _validatePrice(_priceController.text);
    final descriptionValidationError = _validateDescription(
      _descriptionController.text,
    );

    setState(() {
      _priceError = priceValidationError;
      _descriptionError = descriptionValidationError;
    });

    if (priceValidationError != null || descriptionValidationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            priceValidationError ??
                descriptionValidationError ??
                'Invalid input',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final parsedPrice = double.tryParse(_priceController.text.trim());

    if (_requiresBarterItems &&
        !widget.isZeroCoin &&
        widget.selectedItems.isEmpty &&
        widget.selectedServiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item for barter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final walletAlreadyCheckedOnDeck =
        widget.offerMode == OfferSubmissionMode.both &&
        (widget.initialQuotedPrice?.trim().isNotEmpty ?? false);

    if (_requiresPrice &&
        parsedPrice != null &&
        parsedPrice > 0 &&
        !walletAlreadyCheckedOnDeck) {
      final canAfford = await WalletOfferGuard.ensureCanAfford(
        context,
        requiredCoins: parsedPrice.round(),
        itemName: widget.post.title,
      );
      if (!canAfford || !mounted) return;
    }

    try {
      setState(() => _isSubmitting = true);

      print('🚀 Initiating chat with offer:');
      print('   Responder ID: ${widget.post.postedById}');
      print('   Type: ${widget.isService ? "Service" : "Product"}');
      print('   ID: ${widget.post.id}');
      print('   Selected Items: ${widget.selectedItems.length}');
      print('   Description: ${_descriptionController.text.trim()}');

      // Call the initiate chat API with appropriate parameters
      late final TradeChat chat;

      if (widget.isService) {
        chat = await _chatService.initiateChat(
          responderId: widget.post.postedById,
          serviceId: widget.post.id,
        );
      } else {
        chat = await _chatService.initiateChat(
          responderId: widget.post.postedById,
          productId: widget.post.id,
        );
      }

      print('✅ Chat initiated successfully!');
      print('   Chat ID: ${chat.id}');

      final chatProductStatus = chat.product?.status.toUpperCase();
      final chatServiceStatus = chat.service?.status.toUpperCase();
      final isChatItemSold =
          chatProductStatus == 'SOLD' || chatServiceStatus == 'SOLD';
      final isMismatchedProductChat =
          !widget.isService &&
          chat.productId != null &&
          chat.productId != widget.post.id;
      final isMismatchedServiceChat =
          widget.isService &&
          chat.serviceId != null &&
          chat.serviceId != widget.post.id;

      // An accepted offer only blocks a new one while its deal is still in
      // flight (mirrors the backend's makeOffer gate) — once the deal has
      // completed, that offer is settled history, not a live block. This
      // matters most for services: unlike a product (sold once, caught by
      // isChatItemSold below), a service stays live for repeat business
      // after a completed deal, so a completed chat alone must not block a
      // fresh barter/coins offer on it.
      if ((chat.hasAcceptedOffer && !chat.isCompleted) ||
          chat.isArchived ||
          chat.isCancelled ||
          isChatItemSold ||
          isMismatchedProductChat ||
          isMismatchedServiceChat) {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }

        await _showAcceptedOfferConflictAndRedirect(
          'A deal is already active for this chat or the item is no longer available. Please complete/cancel the current deal from Trade Chat.',
        );
        return;
      }

      late final TradeOffer createdOffer;

      if (widget.isZeroCoin) {
        createdOffer = await _chatService.createZeroCoinOffer(
          chatId: chat.id,
          barterItemTitle: _buildOfferTitle(),
          barterItemDescription: _buildOfferDescription(),
          barterItemImages: _buildOfferImages(),
          barterItemIds: widget.selectedItems.map((item) => item.id).toList(),
        );
      } else if (widget.offerMode == OfferSubmissionMode.price) {
        createdOffer = await _chatService.createPriceOffer(
          chatId: chat.id,
          price: parsedPrice!,
          currency: 'USD',
          description: _buildOfferDescription(),
        );
      } else if (widget.offerMode == OfferSubmissionMode.barter) {
        createdOffer = await _chatService.createBarterOffer(
          chatId: chat.id,
          barterItemTitle: _buildOfferTitle(),
          barterItemDescription: _buildOfferDescription(),
          barterItemImages: _buildOfferImages(),
          barterItemIds: widget.selectedItems.map((item) => item.id).toList(),
          barterServiceItemIds: widget.selectedServiceItems
              .map((item) => item.id)
              .toList(),
        );
      } else {
        createdOffer = await _chatService.createBothOffer(
          chatId: chat.id,
          price: parsedPrice!,
          barterItemTitle: _buildOfferTitle(),
          barterItemDescription: _buildOfferDescription(),
          barterItemImages: _buildOfferImages(),
          barterItemIds: widget.selectedItems.map((item) => item.id).toList(),
          barterServiceItemIds: widget.selectedServiceItems
              .map((item) => item.id)
              .toList(),
        );
      }

      print('✅ Offer created successfully!');
      print('   Offer ID: ${createdOffer.id}');

      // Created over REST — ask the socket layer to relay it to the room so
      // the other participant sees the new offer live instead of only on
      // their next manual chat refresh (matches how counter offers already
      // notify via emitOfferCreated in ChatDetailScreen). This screen can be
      // reached directly from a post listing without the chat socket ever
      // having connected yet, so best-effort connect first — fire-and-forget,
      // must not delay the success flow below.
      unawaited(_relayOfferCreated(chat.id, createdOffer));

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Your offer has been sent!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatDetailScreen(
            chat: chat,
            currentUserId: widget.currentUserId,
            onChatUpdated: (_) {},
            returnToTradeChatOnBack: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        print('❌ Failed to initiate chat: $e');

        final readableError = ErrorMessageUtils.sanitize(e);
        final lowerError = readableError.toLowerCase();

        if (lowerError.contains('subscription has expired') ||
            lowerError.contains('subscription expired') ||
            lowerError.contains('subscription inactive')) {
          await _showSubscriptionExpiredDialog();
          return;
        }

        if (lowerError.contains('offer already accepted') ||
            lowerError.contains('complete or cancel the current deal first')) {
          await _showAcceptedOfferConflictAndRedirect(
            'An offer is already accepted for this chat. Please complete or cancel the current deal from Trade Chat first.',
          );
          return;
        }

        if (_requiresPrice &&
            lowerError.contains('price') &&
            (lowerError.contains('required') ||
                lowerError.contains('invalid') ||
                lowerError.contains('greater'))) {
          setState(() {
            _priceError = 'Price must be greater than 0';
          });
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send offer: $readableError'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _validatePrice(String value) {
    if (!_requiresPrice) return null;

    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Quoted price is required';
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Enter a valid price';
    }

    // The backend requires a price greater than 0 for both PRICE and BOTH
    // offer types — 0 is rejected server-side even for combined offers.
    if (parsed <= 0) {
      return 'Price must be greater than 0';
    }

    if (trimmed.length > 6) {
      return 'Price cannot exceed 6 digits';
    }

    return null;
  }

  String? _validateDescription(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Description is required';
    }

    if (!RegExp(r'[A-Za-z]').hasMatch(trimmed)) {
      return 'Description must contain text';
    }

    if (!RegExp(r"^[A-Za-z0-9\s.,!?()'\-]+$").hasMatch(trimmed)) {
      return 'Use only letters, numbers, and basic punctuation';
    }

    if (trimmed.length < 3) {
      return 'Description is too short';
    }

    return null;
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
          'Make Offer',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isZeroCoin) ...[
              Container(
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
                    Icon(Icons.check_box_outlined, color: Colors.teal.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Zero-coin transaction — no coins involved. Item(s) below are optional.',
                        style: TextStyle(fontSize: 12, color: Colors.teal.shade900),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Offer Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Offer Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // You want (Target post)
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SafeNetworkImage(
                                url: widget.post.processedImages.isNotEmpty
                                    ? widget.post.processedImages.first
                                    : widget.post.getDefaultImageUrl(),
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'You want:',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.post.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'by ${widget.post.postedBy.firstName}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (widget.post.price > 0)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        CoinFormat.withLabel(widget.post.price),
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Swap icon
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.swap_horiz,
                          color: Colors.blue.shade700,
                          size: 28,
                        ),
                      ),

                      // You offer (Selected items)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _requiresBarterItems
                                  ? 'You offer:'
                                  : 'Your quote:',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (_requiresBarterItems) ...[
                              if (widget.isZeroCoin && _allSelectedItems.isEmpty)
                                Text(
                                  'No item — asking for zero coins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ..._allSelectedItems
                                  .take(2)
                                  .map(
                                    (item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                            child: item.imageUrl.isNotEmpty
                                                ? SafeNetworkImage(
                                                    url: item.imageUrl,
                                                    width: 28,
                                                    height: 28,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    width: 28,
                                                    height: 28,
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(
                                                      Icons.image,
                                                      size: 16,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (item.value > 0)
                                                  Text(
                                                    CoinFormat.withLabel(item.value),
                                                    style: TextStyle(
                                                      color:
                                                          Colors.green.shade700,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              if (_allSelectedItems.length > 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: InkWell(
                                    onTap: _showAllSelectedItemsDialog,
                                    child: Text(
                                      '+ ${_allSelectedItems.length - 2} more',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              if (widget.selectedBundleItems.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Bundle: ${widget.selectedBundleItems.map((e) => e.name).join(', ')}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 11,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (widget.offerMode == OfferSubmissionMode.both)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '+ ${CoinFormat.withUnit(double.tryParse(_priceController.text.trim()) ?? 0)}',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ] else
                              Text(
                                _priceController.text.trim().isEmpty
                                    ? 'Enter a price below'
                                    : CoinFormat.withUnit(
                                        double.tryParse(
                                              _priceController.text.trim(),
                                            ) ??
                                            0,
                                      ),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description Input
            if (_requiresPrice) ...[
              const Text(
                'Your offer price',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (widget.post.price > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Listed at ${CoinFormat.withLabel(widget.post.price)} — enter the amount you want to offer.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) {
                  setState(() {
                    _priceError = _validatePrice(_priceController.text);
                  });
                },
                decoration: AppInputDecoration.build(
                  label: 'Offer Price',
                  hint: 'Enter your offer in coins',
                  prefix: coinInputPrefix(),
                  errorText: _priceError,
                  fillColor: Colors.grey.shade50,
                ),
              ),
              const SizedBox(height: 20),
            ],

            const Text(
              'Description',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              maxLength: 500,
              onChanged: (_) {
                setState(() {
                  _descriptionError = _validateDescription(
                    _descriptionController.text,
                  );
                });
              },
              decoration: AppInputDecoration.build(
                label: 'Description',
                hint: 'Explain your offer and why you want to trade...',
                errorText: _descriptionError,
                fillColor: Colors.grey.shade50,
                alignLabelWithHint: true,
                counterText: '',
              ),
            ),

            const SizedBox(height: 16),

            // Info Box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Include details about condition, reason for trading, or any special notes.',
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5BFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        widget.offerMode == OfferSubmissionMode.price
                            ? 'Send Price Quote'
                            : widget.offerMode == OfferSubmissionMode.barter
                            ? 'Send Barter Offer'
                            : 'Send Combined Offer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Back Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
