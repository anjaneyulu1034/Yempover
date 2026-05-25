import 'package:YemPover_app/models/chats/trade_chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:YemPover_app/models/ProductPostmain.dart';
import 'package:YemPover_app/payment/SubscriptionScreen.dart';
import 'package:YemPover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:YemPover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:YemPover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:YemPover_app/widgets/coin_icon.dart';
import 'package:YemPover_app/utils/error_message_utils.dart';
import 'package:YemPover_app/utils/wallet_offer_guard.dart';

enum OfferSubmissionMode { price, barter, both }

class OfferDescriptionScreen extends StatefulWidget {
  final Post post;
  final List<UserItem> selectedItems;
  final List<UserItem> selectedBundleItems;
  final String currentUserId;
  final bool isService;
  final OfferSubmissionMode offerMode;
  final String? initialQuotedPrice;

  const OfferDescriptionScreen({
    super.key,
    required this.post,
    required this.selectedItems,
    this.selectedBundleItems = const [],
    required this.currentUserId,
    this.isService = false,
    required this.offerMode,
    this.initialQuotedPrice,
  });

  @override
  State<OfferDescriptionScreen> createState() => _OfferDescriptionScreenState();
}

class _OfferDescriptionScreenState extends State<OfferDescriptionScreen> {
  final TradeChatService _chatService = TradeChatService();
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

    final initialQuotedPrice = widget.initialQuotedPrice?.trim() ?? '';
    if (initialQuotedPrice.isNotEmpty) {
      _priceController.text = initialQuotedPrice;
    } else if (widget.post.price > 0) {
      _priceController.text = widget.post.price.toStringAsFixed(2);
    }
  }

  String _buildOfferTitle() {
    if (widget.selectedItems.isEmpty) {
      return 'Offer for ${widget.post.title}';
    }

    if (widget.selectedItems.length == 1) {
      return widget.selectedItems.first.name;
    }

    final firstTwo = widget.selectedItems
        .take(2)
        .map((item) => item.name)
        .join(', ');
    final remaining = widget.selectedItems.length - 2;
    return remaining > 0 ? '$firstTwo +$remaining more' : firstTwo;
  }

  String _buildOfferDescription() {
    final userDescription = _descriptionController.text.trim();
    final selectedItemNames = widget.selectedItems
        .map((item) => item.name)
        .join(', ');
    final selectedBundleItemNames = widget.selectedBundleItems
        .map((item) => item.name)
        .join(', ');

    if (selectedItemNames.isEmpty && selectedBundleItemNames.isEmpty) {
      return userDescription;
    }

    final lines = <String>[];
    if (userDescription.isNotEmpty) {
      lines.add(userDescription);
    }
    if (selectedItemNames.isNotEmpty) {
      lines.add('Offered items: $selectedItemNames');
    }
    if (selectedBundleItemNames.isNotEmpty) {
      lines.add('Requested bundle items: $selectedBundleItemNames');
    }

    return lines.join('\n\n');
  }

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

    if (_requiresBarterItems && widget.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one item for barter'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_requiresPrice && parsedPrice != null && parsedPrice > 0) {
      final canAfford = await WalletOfferGuard.ensureCanAfford(
        context,
        requiredCoins: parsedPrice,
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

      if (chat.hasAcceptedOffer ||
          chat.isArchived ||
          chat.isCompleted ||
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

      if (widget.offerMode == OfferSubmissionMode.price) {
        createdOffer = await _chatService.createPriceOffer(
          chatId: chat.id,
          price: parsedPrice!,
          currency: 'USD',
        );
      } else if (widget.offerMode == OfferSubmissionMode.barter) {
        createdOffer = await _chatService.createBarterOffer(
          chatId: chat.id,
          barterItemTitle: _buildOfferTitle(),
          barterItemDescription: _buildOfferDescription(),
        );
      } else {
        createdOffer = await _chatService.createBothOffer(
          chatId: chat.id,
          price: parsedPrice!,
          barterItemTitle: _buildOfferTitle(),
          barterItemDescription: _buildOfferDescription(),
        );
      }

      print('✅ Offer created successfully!');
      print('   Offer ID: ${createdOffer.id}');

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
    if (parsed == null || parsed <= 0) {
      return 'Enter a valid price';
    }

    if (trimmed.length > 9) {
      return 'Price is too large';
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

    if (RegExp(r'\d').hasMatch(trimmed)) {
      return 'Description cannot contain numbers';
    }

    if (!RegExp(r"^[A-Za-z\s.,!?()'\-]+$").hasMatch(trimmed)) {
      return 'Use only letters';
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
                              ...widget.selectedItems
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
                                                ? Image.network(
                                                    item.imageUrl,
                                                    width: 28,
                                                    height: 28,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) {
                                                          return Container(
                                                            width: 28,
                                                            height: 28,
                                                            color: Colors
                                                                .grey
                                                                .shade200,
                                                            child: const Icon(
                                                              Icons.image,
                                                              size: 16,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          );
                                                        },
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
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              if (widget.selectedItems.length > 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    '+ ${widget.selectedItems.length - 2} more',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
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
                            ] else
                              Text(
                                _priceController.text.trim().isEmpty
                                    ? 'Enter a price below'
                                    : '${_priceController.text.trim()} coins',
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
                    'Listed at ${CoinFormat.amount(widget.post.price)} coins — enter the amount you want to offer.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              TextField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  LengthLimitingTextInputFormatter(9),
                ],
                onChanged: (_) {
                  setState(() {
                    _priceError = _validatePrice(_priceController.text);
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Enter your offer in coins',
                  prefix: coinInputPrefix(),
                  errorText: _priceError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF2E5BFF), width: 2),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.red, width: 1.4),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  filled: true,
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
              decoration: InputDecoration(
                hintText: 'Explain your offer and why you want to trade...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                errorText: _descriptionError,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF2E5BFF),
                    width: 2,
                  ),
                ),
                errorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red, width: 1.4),
                ),
                focusedErrorBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Colors.red, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
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
