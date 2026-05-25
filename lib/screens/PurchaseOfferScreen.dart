import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:YemPover_app/models/ProductPostmain.dart';
import 'package:YemPover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:YemPover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:YemPover_app/utils/error_message_utils.dart';
import 'package:YemPover_app/widgets/coin_icon.dart';

class PurchaseOfferScreen extends StatefulWidget {
  final Post post;

  const PurchaseOfferScreen({super.key, required this.post});

  @override
  State<PurchaseOfferScreen> createState() => _PurchaseOfferScreenState();
}

class _PurchaseOfferScreenState extends State<PurchaseOfferScreen> {
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TradeChatService _chatService = TradeChatService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with post price if available
    if (widget.post.price > 0) {
      _priceController.text = widget.post.price.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _submitPurchaseOffer() async {
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a price')));
      return;
    }

    final price = double.tryParse(_priceController.text);
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid price')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final chat = await _chatService.initiateChat(
        responderId: widget.post.postedById,
        productId: widget.post.type == PostType.product ? widget.post.id : null,
        serviceId: widget.post.type == PostType.service ? widget.post.id : null,
      );

      final chatProductStatus = chat.product?.status.toUpperCase();
      final chatServiceStatus = chat.service?.status.toUpperCase();
      final isChatItemSold =
          chatProductStatus == 'SOLD' || chatServiceStatus == 'SOLD';
      final isMismatchedProductChat =
          widget.post.type == PostType.product &&
          chat.productId != null &&
          chat.productId != widget.post.id;
      final isMismatchedServiceChat =
          widget.post.type == PostType.service &&
          chat.serviceId != null &&
          chat.serviceId != widget.post.id;

      if (chat.hasAcceptedOffer ||
          chat.isArchived ||
          chat.isCompleted ||
          chat.isCancelled ||
          isChatItemSold ||
          isMismatchedProductChat ||
          isMismatchedServiceChat) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'A deal is already active for this chat or the item is no longer available. Please complete/cancel the current deal from Trade Chat.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TradeChatScreen()),
          (route) => false,
        );
        return;
      }

      await _chatService.createPriceOffer(
        chatId: chat.id,
        price: price,
        currency: 'USD',
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Temporarily hidden: success popup includes price/coins context, not needed now.
      // showDialog(
      //   context: context,
      //   barrierDismissible: false,
      //   builder: (context) => AlertDialog(
      //     title: const Icon(Icons.check_circle, color: Colors.green, size: 60),
      //     content: Column(
      //       mainAxisSize: MainAxisSize.min,
      //       children: [
      //         const Text(
      //           'Purchase Offer Submitted!',
      //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      //           textAlign: TextAlign.center,
      //         ),
      //         const SizedBox(height: 12),
      //         Text(
      //           'Your purchase offer of \$${_priceController.text} for "${widget.post.title}" has been sent to ${widget.post.postedBy.firstName}.',
      //           textAlign: TextAlign.center,
      //           style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      //         ),
      //         const SizedBox(height: 8),
      //         const Text(
      //           'You can track the status in the Trade Chat section.',
      //           textAlign: TextAlign.center,
      //           style: TextStyle(fontSize: 12, color: Colors.grey),
      //         ),
      //       ],
      //     ),
      //     actions: [
      //       SizedBox(
      //         width: double.infinity,
      //         child: ElevatedButton(
      //           onPressed: () {
      //             Navigator.pushAndRemoveUntil(
      //               context,
      //               MaterialPageRoute(
      //                 builder: (context) => const TradeChatScreen(),
      //               ),
      //               (route) => false,
      //             );
      //           },
      //           child: const Text('Go to Trade Chat'),
      //         ),
      //       ),
      //     ],
      //   ),
      // );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const TradeChatScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final readableError = ErrorMessageUtils.sanitize(e);
      final lowerError = readableError.toLowerCase();

      if (lowerError.contains('offer already accepted') ||
          lowerError.contains('complete or cancel the current deal first')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'An offer is already accepted for this chat. Please complete or cancel the current deal from Trade Chat first.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const TradeChatScreen()),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit purchase offer: $readableError'),
          backgroundColor: Colors.red,
        ),
      );
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
          'Make Purchase Offer',
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
            // Offer Summary
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
                    'Purchase Offer Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Product:',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.post.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Posted by: ${widget.post.postedBy.firstName}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                            if (widget.post.price > 0)
                              Text(
                                'Original Price: ${CoinFormat.amount(widget.post.price)} coins',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.shopping_cart,
                        color: Colors.blue.shade700,
                        size: 32,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Price Input
            const Text(
              'Your offer price',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (widget.post.price > 0)
              Text(
                'Listed at ${CoinFormat.amount(widget.post.price)} coins — enter the amount you want to offer.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            if (widget.post.price > 0) const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: 'Enter your offer in coins',
                prefix: coinInputPrefix(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E5BFF)),
                ),
                contentPadding: const EdgeInsets.all(16),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),

            const SizedBox(height: 24),

            // Description Input
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'Add any notes or conditions for your purchase offer...',
                hintStyle: const TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2E5BFF)),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 32),

            // Submit Offer Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitPurchaseOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E5BFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Purchase Offer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

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
