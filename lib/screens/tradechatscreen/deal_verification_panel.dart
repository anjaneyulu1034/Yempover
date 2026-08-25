// Deal completion panel — shown in ChatDetailScreen once an offer is
// accepted (chat.hasDealVerification). Dead-simple flow, no PIN, no photo
// inspection: an exchange-mode header, a background payment info banner
// (informational only), and the mutual "Deal Completed" / "Deal Not
// Completed" buttons driven entirely by GET .../deal/verification.
import 'package:flutter/material.dart';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:yempover_app/services/socket_io/socket_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/utils/wallet_offer_guard.dart';
import 'package:yempover_app/widgets/coin_icon.dart';

class DealVerificationPanel extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String? itemName;
  final VoidCallback onChatShouldRefresh;
  // Who gave what to whom, so the completed-deal card can spell out the
  // exchange instead of just a bare checkmark — the offerer handed over
  // offeredItemLabel and received itemName (the post) from the receiver.
  final String? offererName;
  final String? receiverName;
  final String? offeredItemLabel;
  // The other chat participant's first name — used in place of the generic
  // "the other user" wording so waiting/reassurance copy names them directly.
  final String? otherUserName;

  const DealVerificationPanel({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.onChatShouldRefresh,
    this.itemName,
    this.offererName,
    this.receiverName,
    this.offeredItemLabel,
    this.otherUserName,
  });

  @override
  State<DealVerificationPanel> createState() => _DealVerificationPanelState();
}

class _DealVerificationPanelState extends State<DealVerificationPanel> {
  final TradeChatService _chatService = TradeChatService();
  final SocketService _socketService = SocketService();

  DealVerification? _verification;
  bool _isLoading = true;
  String? _loadError;
  bool _isBusy = false; // completing / closing

  @override
  void initState() {
    super.initState();
    _socketService.on('deal:updated', _handleDealUpdated);
    _fetchVerification();
  }

  @override
  void dispose() {
    _socketService.off('deal:updated', _handleDealUpdated);
    super.dispose();
  }

  void _handleDealUpdated(dynamic data) {
    if (!mounted || data == null) return;
    try {
      final chatId = data['chatId']?.toString();
      if (chatId != widget.chatId) return;
      _fetchVerification(silent: true);
    } catch (_) {
      // Ignore malformed payloads — this is just a "go refetch" nudge.
    }
  }

  Future<void> _fetchVerification({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final verification = await _chatService.getDealVerification(
        widget.chatId,
      );
      if (!mounted) return;
      setState(() {
        _verification = verification;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', '')),
        backgroundColor: Colors.red,
      ),
    );
  }

  // Coins (when involved) are secured automatically in the background the
  // moment a payer marks the deal completed — there's no separate fund
  // step. If their balance is short, the backend 400s with a reassuring
  // "add N more coins" message rather than a generic error; detect that and
  // route to the same top-up flow used elsewhere, then retry.
  bool _isInsufficientCoinsError(Object e) =>
      e.toString().contains('more coins');

  Future<bool> _resolveInsufficientCoins() {
    final amount = _verification?.payment.amount ?? 0;
    return WalletOfferGuard.ensureCanAfford(
      context,
      requiredCoins: amount,
      itemName: widget.itemName,
    );
  }

  Future<void> _markCompleted() async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      await _chatService.markDealCompleted(chatId: widget.chatId);
      if (!mounted) return;

      // markDealCompleted doesn't return the deal summary — refetch so the
      // buttons/status reflect the real iCompleted/bothCompleted state.
      await _fetchVerification(silent: true);
      if (!mounted) return;
      setState(() => _isBusy = false);

      _socketService.emitDealUpdated(
        widget.chatId,
        _verification?.status.value,
      );
      // Also emit the dedicated deal:completed event — screens like the
      // chat list listen for that specifically, not deal:updated, to
      // refresh live instead of waiting for their next full reload.
      if (_verification?.completed == true) {
        _socketService.emitDealCompleted(widget.chatId, const {});
      }
      widget.onChatShouldRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);

      if (_isInsufficientCoinsError(e)) {
        final toppedUp = await _resolveInsufficientCoins();
        if (toppedUp && mounted) {
          _markCompleted();
          return;
        }
        if (!mounted) return;
      }
      _showError(e);
    }
  }

  Future<void> _confirmClose() async {
    final reasonController = TextEditingController();
    final prompt = _verification?.closeDealPrompt;

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(prompt?.title ?? 'Deal Not Completed'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prompt?.helperText ??
                    'Let the other person know why this deal fell through. '
                        'Any secured coins are refunded and the item goes '
                        'back on the marketplace immediately.',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              if (prompt != null && prompt.suggestions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: prompt.suggestions
                      .map(
                        (suggestion) => ActionChip(
                          label: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          onPressed: () => setDialogState(() {
                            reasonController.text = suggestion;
                            reasonController.selection =
                                TextSelection.collapsed(
                                  offset: reasonController.text.length,
                                );
                          }),
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 3,
                maxLength: prompt?.maxLength ?? 500,
                decoration: InputDecoration(
                  labelText: prompt?.required == true
                      ? 'Reason'
                      : 'Reason (optional)',
                  hintText: prompt?.placeholder,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Back'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () =>
                Navigator.pop(dialogContext, reasonController.text.trim()),
            child: const Text('Close Deal'),
          ),
        ],
      ),
    );

    if (reason == null || _isBusy || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final result = await _chatService.closeDeal(
        widget.chatId,
        reason: reason.isEmpty ? null : reason,
      );
      if (!mounted) return;
      setState(() => _isBusy = false);

      _socketService.emitDealUpdated(widget.chatId, null);
      // Also emit the dedicated deal:cancelled event — the chat list
      // screen listens for that specifically to refresh live.
      _socketService.emitDealCancelled(widget.chatId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      // The DealVerification row is deleted server-side on close — once
      // the parent refetches, chat.dealVerification becomes null and this
      // panel stops being rendered.
      widget.onChatShouldRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final verification = _verification;

    if (_isLoading && verification == null) {
      return _panelContainer(
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (verification == null) {
      return _panelContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _loadError ?? 'Could not load the deal status.',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _fetchVerification(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final isDone =
        verification.status == DealStatus.COMPLETED ||
        verification.completion.bothCompleted;

    return _panelContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (verification.exchangeModeLabel != null) ...[
            Row(
              children: [
                const Icon(Icons.handshake, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  verification.exchangeModeLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (verification.payment.required) ...[
            _buildPaymentInfo(verification.payment),
            const SizedBox(height: 12),
          ],
          if (isDone)
            _buildCompletedRow()
          else
            _buildCompletionAction(verification.completion),
          // Once this user has already marked their side completed,
          // backing out via "Deal Not Completed" no longer makes sense —
          // they've committed, so only the waiting note above shows.
          if (!isDone && !verification.completion.iCompleted) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isBusy ? null : _confirmClose,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange.shade800,
                  side: BorderSide(color: Colors.orange.shade300),
                ),
                child: const Text('Deal Not Completed'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _panelContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: child,
    );
  }

  // Calm, informational — never an action the user needs to press. Coins
  // move automatically in the background (secured when the payer marks the
  // deal completed; released to the payee once both sides have).
  Widget _buildPaymentInfo(DealPayment payment) {
    if (payment.iAmPayer) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF4FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFC9DBFF)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.shield_outlined,
              color: AppConstants.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                payment.message ??
                    'Your ${CoinFormat.withLabel(payment.amount)} are safe and only '
                        'transferred to '
                        '${widget.otherUserName?.trim().isNotEmpty == true ? widget.otherUserName : 'the other user'} '
                        'when the deal is completed.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
              ),
            ),
          ],
        ),
      );
    }

    if (payment.iAmPayee) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.savings_outlined,
              color: Colors.green.shade700,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                payment.message ??
                    "You'll receive ${CoinFormat.withLabel(payment.amount)} when the deal completes.",
                style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  // Either "Deal Completed" (enabled while canComplete) or, once this user
  // has already tapped it, a waiting note instead of a disabled button.
  Widget _buildCompletionAction(DealCompletion completion) {
    if (completion.iCompleted) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You marked the deal completed — waiting for '
              '${widget.otherUserName?.trim().isNotEmpty == true ? widget.otherUserName : 'the other user'}.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_isBusy || !completion.canComplete) ? null : _markCompleted,
        icon: _isBusy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check_circle_outline),
        label: const Text('Deal Completed'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCompletedRow() {
    final offererName = widget.offererName;
    final receiverName = widget.receiverName;
    final offeredItemLabel = widget.offeredItemLabel;
    final itemName = widget.itemName;
    final hasExchangeSummary =
        offererName != null &&
        receiverName != null &&
        offeredItemLabel != null &&
        offeredItemLabel.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Deal completed ✓',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              if (hasExchangeSummary) ...[
                const SizedBox(height: 4),
                Text(
                  itemName != null && itemName.trim().isNotEmpty
                      ? '$offererName gave "$offeredItemLabel" to $receiverName for "$itemName".'
                      : '$offererName gave "$offeredItemLabel" to $receiverName.',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
