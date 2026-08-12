// Deal PIN verification panel — shown in ChatDetailScreen once an offer is
// accepted (chat.hasDealVerification). Renders entirely off the backend's
// mode/status/role/flags — no per-scenario branching here, the backend has
// already derived everything (see DealVerification model).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:yempover_app/services/socket_io/socket_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/utils/image_picker_utils.dart';
import 'package:yempover_app/utils/wallet_offer_guard.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import 'package:yempover_app/widgets/deal_pin_input.dart';

class DealVerificationPanel extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final DealVerificationSummary summary;
  final String? itemName;
  final VoidCallback onChatShouldRefresh;

  const DealVerificationPanel({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.summary,
    required this.onChatShouldRefresh,
    this.itemName,
  });

  @override
  State<DealVerificationPanel> createState() => _DealVerificationPanelState();
}

class _DealVerificationPanelState extends State<DealVerificationPanel> {
  final TradeChatService _chatService = TradeChatService();
  final SocketService _socketService = SocketService();
  final GlobalKey<DealPinInputState> _pinInputKey =
      GlobalKey<DealPinInputState>();

  DealVerification? _verification;
  bool _isLoading = true;
  String? _loadError;

  bool _isBusy = false; // fund / add photos / set ready / close
  bool _isVerifyingPin = false;
  String? _pinError;
  String _pinValue = '';

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

  // Every deal/* endpoint's own effect is already applied server-side by
  // the time it responds; this just nudges the other participant's client
  // to refetch, and asks the parent ChatDetailScreen to refresh the chat
  // (new system message, possibly a status change).
  void _afterAction(DealVerification updated) {
    if (!mounted) return;
    setState(() => _verification = updated);
    _socketService.emitDealUpdated(widget.chatId, updated.status.value);
    widget.onChatShouldRefresh();
  }

  // Coins are now secured automatically when the payer confirms satisfied
  // (goods) or enters the Start PIN (service) — there's no separate fund
  // step anymore. If their balance is short, the backend 400s with a
  // reassuring "add N more coins" message rather than a generic error;
  // detect that and route to the same top-up flow used elsewhere, then
  // retry the action that triggered it.
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

  Future<void> _addPhotos() async {
    if (_isBusy) return;

    final files = await ImagePickerUtils.pickImagesFromGallery();
    if (files.isEmpty || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final dataUris = <String>[];
      for (final file in files) {
        final bytes = await file.readAsBytes();
        dataUris.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }

      final updated = await _chatService.addInspectionImages(
        widget.chatId,
        dataUris,
      );
      if (!mounted) return;
      setState(() => _isBusy = false);
      _afterAction(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);
      _showError(e);
    }
  }

  Future<void> _setReady(bool ready) async {
    if (_isBusy) return;

    setState(() => _isBusy = true);
    try {
      final updated = await _chatService.setDealReady(widget.chatId, ready);
      if (!mounted) return;
      setState(() => _isBusy = false);
      _afterAction(updated);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBusy = false);

      if (ready && _isInsufficientCoinsError(e)) {
        final toppedUp = await _resolveInsufficientCoins();
        if (toppedUp && mounted) {
          _setReady(true);
          return;
        }
        if (!mounted) return;
      }
      _showError(e);
    }
  }

  Future<void> _verifyPin() async {
    if (_isVerifyingPin || _pinValue.length != 4) return;

    final pinToVerify = _pinValue;
    setState(() {
      _isVerifyingPin = true;
      _pinError = null;
    });

    try {
      final result = await _chatService.verifyDealPin(
        widget.chatId,
        pinToVerify,
      );
      if (!mounted) return;

      _pinInputKey.currentState?.clear();
      setState(() {
        _isVerifyingPin = false;
        _pinValue = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }

      // verify-pin doesn't return the full view (unlike fund/inspection),
      // so refetch to pick up the new status/flags/next PIN to share.
      await _fetchVerification(silent: true);
      _socketService.emitDealUpdated(widget.chatId, _verification?.status.value);
      // Also emit the dedicated deal:completed event — screens like the
      // chat list listen for that specifically, not deal:updated, to
      // refresh live instead of waiting for their next full reload.
      if (result.completed) {
        _socketService.emitDealCompleted(widget.chatId, const {});
      }
      widget.onChatShouldRefresh();
    } catch (e) {
      if (!mounted) return;

      if (_isInsufficientCoinsError(e)) {
        setState(() => _isVerifyingPin = false);
        final toppedUp = await _resolveInsufficientCoins();
        if (toppedUp && mounted) {
          // The PIN boxes were never cleared, so _pinValue is still intact.
          _verifyPin();
          return;
        }
        if (!mounted) return;
      }

      _pinInputKey.currentState?.clear();
      setState(() {
        _isVerifyingPin = false;
        _pinValue = '';
        _pinError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _confirmClose() async {
    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deal Not Completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Let the other person know why this deal fell through. '
              'Any secured coins are refunded and the item goes back on '
              'the marketplace immediately.',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              autofocus: true,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'e.g. Buyer did not show up, item condition '
                    'mismatch...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
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

  void _showFullScreenImage(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
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
          _buildStepper(verification),
          const SizedBox(height: 16),
          _buildStageContent(verification),
          if (verification.status != DealStatus.COMPLETED) ...[
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

  Widget _buildStepper(DealVerification verification) {
    final List<String> labels;
    final int activeIndex;

    if (verification.isServiceSequential) {
      labels = const ['Start', 'In progress', 'Complete'];
      activeIndex = switch (verification.status) {
        DealStatus.AWAITING_START => 0,
        DealStatus.IN_PROGRESS => 1,
        DealStatus.COMPLETED => 2,
        _ => 0,
      };
    } else if (verification.inspection.required) {
      labels = const ['Inspect', 'Confirm', 'Complete'];
      activeIndex = switch (verification.status) {
        DealStatus.INSPECTION => 0,
        DealStatus.AWAITING_HANDOVER => 1,
        DealStatus.COMPLETED => 2,
        _ => 0,
      };
    } else {
      labels = const ['Confirm', 'Complete'];
      activeIndex = switch (verification.status) {
        DealStatus.AWAITING_HANDOVER => 0,
        DealStatus.COMPLETED => 1,
        _ => 0,
      };
    }

    return Row(
      children: List.generate(labels.length * 2 - 1, (i) {
        if (i.isOdd) {
          final passed = (i ~/ 2) < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: passed ? Colors.green : Colors.green.shade100,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isActive = stepIndex == activeIndex;
        final isPast = stepIndex < activeIndex;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: isActive || isPast
                  ? Colors.green
                  : Colors.green.shade100,
              child: isPast
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : Text(
                      '${stepIndex + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : Colors.green,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              labels[stepIndex],
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: Colors.green.shade800,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStageContent(DealVerification verification) {
    switch (verification.status) {
      case DealStatus.INSPECTION:
        return _buildInspectionStage(verification);
      case DealStatus.AWAITING_HANDOVER:
        return _buildPinExchangeStage(verification);
      case DealStatus.AWAITING_START:
        return _buildAwaitingStartStage(verification);
      case DealStatus.IN_PROGRESS:
        return _buildInProgressStage(verification);
      case DealStatus.COMPLETED:
        return _buildCompletedStage();
      case DealStatus.CANCELLED:
        return const Text(
          'This deal was closed.',
          style: TextStyle(color: Colors.black54),
        );
    }
  }

  // ---- A) INSPECTION ----
  Widget _buildInspectionStage(DealVerification verification) {
    final inspection = verification.inspection;

    // Only the inspector(s) for this scenario act here — e.g. only the
    // buyer on a pure-price deal. Everyone else gets a passive status.
    if (!inspection.iAmInspector) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Waiting for the buyer to inspect the item and confirm.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Inspect the item',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        if (inspection.images.isNotEmpty)
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: inspection.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final image = inspection.images[index];
                return GestureDetector(
                  onTap: () => _showFullScreenImage(image.url),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      image.url,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 84,
                        height: 84,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isBusy ? null : _addPhotos,
          icon: const Icon(Icons.add_a_photo, size: 18),
          label: Text(_isBusy ? 'Uploading...' : 'Add photos'),
        ),
        if (inspection.mustAddPhoto) ...[
          const SizedBox(height: 4),
          Text(
            "Add at least one photo of the item you received before confirming you're satisfied.",
            style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
          ),
        ],
        if (verification.payment.required) ...[
          const SizedBox(height: 12),
          _buildPaymentInfo(verification.payment),
        ],
        const SizedBox(height: 12),
        if (inspection.iAmReady)
          Row(
            children: [
              const Icon(Icons.check_circle, size: 16, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  inspection.waitingForOther
                      ? 'Waiting for the other user to confirm.'
                      : 'Confirmed — moving to Deal PIN handover.',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: _isBusy ? null : () => _setReady(false),
                child: const Text('Withdraw'),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isBusy || inspection.mustAddPhoto)
                  ? null
                  : () => _setReady(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("I'm satisfied — ready to complete"),
            ),
          ),
      ],
    );
  }

  // Calm, informational — never an action the user needs to press. Coins
  // move automatically in the background (on confirm-satisfied / Start PIN
  // for the payer; released to the payee on completion).
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
                        'transferred when you complete the deal with your PIN.',
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
            Icon(Icons.savings_outlined, color: Colors.green.shade700, size: 18),
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

  // ---- B) AWAITING_HANDOVER (mutual PIN exchange) ----
  Widget _buildPinExchangeStage(DealVerification verification) {
    final payment = verification.payment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (verification.myPin != null)
          _buildPinCard(verification.myPin!, verification.myPinLabel),
        if (verification.myPin != null &&
            (payment.required || verification.awaitingMyEntry))
          const SizedBox(height: 16),
        if (payment.required) ...[
          _buildPaymentInfo(payment),
          if (verification.awaitingMyEntry) const SizedBox(height: 12),
        ],
        if (verification.awaitingMyEntry)
          _buildPinEntry(verification.entryLabel ?? 'Enter the Deal PIN'),
      ],
    );
  }

  // ---- C) AWAITING_START (service, sequential) ----
  Widget _buildAwaitingStartStage(DealVerification verification) {
    if (verification.role == DealRole.PROVIDER) {
      return _buildPinCard(verification.myPin, verification.myPinLabel);
    }

    final payment = verification.payment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (payment.required) ...[
          _buildPaymentInfo(payment),
          const SizedBox(height: 12),
        ],
        _buildPinEntry(
          verification.entryLabel ?? "Enter the provider's Start PIN",
        ),
      ],
    );
  }

  // ---- D) IN_PROGRESS (service, sequential) ----
  Widget _buildInProgressStage(DealVerification verification) {
    if (verification.role == DealRole.CONSUMER) {
      return _buildPinCard(verification.myPin, verification.myPinLabel);
    }

    return _buildPinEntry(
      verification.entryLabel ?? "Enter the customer's Completion PIN",
    );
  }

  // ---- E) COMPLETED ----
  Widget _buildCompletedStage() {
    return Row(
      children: const [
        Icon(Icons.check_circle, color: Colors.green, size: 28),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Deal completed ✓',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ],
    );
  }

  Widget _buildPinCard(String? pin, String? label) {
    if (pin == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label ?? 'Share this Deal PIN',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                pin.split('').join('  '),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white70, size: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: pin));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN copied')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinEntry(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        const SizedBox(height: 12),
        DealPinInput(
          key: _pinInputKey,
          hasError: _pinError != null,
          enabled: !_isVerifyingPin,
          onChanged: (value) => setState(() {
            _pinValue = value;
            _pinError = null;
          }),
        ),
        if (_pinError != null) ...[
          const SizedBox(height: 8),
          Text(
            _pinError!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_pinValue.length == 4 && !_isVerifyingPin)
                ? _verifyPin
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: _isVerifyingPin
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Verify'),
          ),
        ),
      ],
    );
  }
}
