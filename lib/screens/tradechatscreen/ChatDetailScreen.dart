import 'dart:async';
import 'dart:io';
import 'package:yempover_app/services/socket_io/socket_service.dart';
import 'package:yempover_app/services/service_booking_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/models/ProductPostmain.dart';
import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:yempover_app/screens/OfferDeckScreen.dart';
import 'package:yempover_app/screens/OfferDescriptionScreen.dart';
import 'package:yempover_app/screens/PostDetailScreen.dart';
import 'package:yempover_app/services/my_posts_service.dart';
import 'package:yempover_app/utils/barter_clubbing.dart';
import 'package:yempover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:yempover_app/services/api_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/utils/loading_widget.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import 'package:yempover_app/widgets/exchange_mode_sheet.dart';
import 'package:yempover_app/utils/blocked_users_cache.dart';
import 'package:yempover_app/services/blocked_user_service.dart';
import 'package:yempover_app/services/coin_service.dart';
import 'package:yempover_app/screens/CoinsWalletScreen.dart';
import 'package:yempover_app/utils/error_message_utils.dart';
import 'package:yempover_app/utils/wallet_offer_guard.dart';
import 'package:yempover_app/utils/validators.dart';
import 'package:yempover_app/services/resume_state_service.dart';
import 'package:yempover_app/screens/tradechatscreen/deal_verification_panel.dart';

class ChatDetailScreen extends StatefulWidget {
  final TradeChat chat;
  final String currentUserId;
  final void Function(TradeChat) onChatUpdated;
  final bool returnToTradeChatOnBack;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onChatUpdated,
    this.returnToTradeChatOnBack = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  final TradeChatService _chatService = TradeChatService();
  final CoinService _coinService = CoinService();
  final ServiceBookingService _serviceBookingService = ServiceBookingService();
  final SocketService _socketService = SocketService();
  final TokenService _tokenService = TokenService();
  final BlockedUserService _blockedUserService = BlockedUserService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _focusNode = FocusNode();

  late TradeChat _currentChat;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSendingImage = false;
  bool _isOfferActionInProgress = false;
  String? _processingOfferId;
  bool _isShowingDealCompletionDialog = false;
  bool _isTyping = false;
  bool _isOtherUserOnline = false;
  // True when either side has blocked the other — hides the composer,
  // gallery button, offer-type button, and all accept/reject/counter/deal
  // actions. Seeded from the server's isBlocked (getChatDetail) on load and
  // every refresh, and kept live via chat:blocked/chat:unblocked so it
  // updates with no refresh needed.
  bool _isBlocked = false;
  bool _isPreparingOffer = false;
  bool _isOpeningPostDetail = false;
  Timer? _typingTimer;
  // Cache of full Post detail for offered barter items, populated lazily on
  // tap (see _openBarterItemDetail) so a second tap on the same item is
  // instant. The offer preview itself (image/title/price) now renders
  // straight from offer.barterProducts — this cache is only needed for the
  // full PostDetailScreen navigation, which wants more than that summary.
  final Map<String, Post> _barterItemPostCache = {};

  bool get _isReferenceUnavailable {
    // The backend marks the product/service SOLD as soon as an offer is
    // accepted (to reserve it) — well before both users have given deal
    // completion consent. Treat the reference as available for the whole
    // "accepted but not yet fully completed" window so the second user can
    // still see and act on the "Deal Ready to Complete" banner.
    if (_currentChat.hasAcceptedOffer && !_currentChat.isCompleted) {
      return false;
    }

    final productStatus = _currentChat.product?.status.trim().toUpperCase();
    if (productStatus != null &&
        (productStatus == 'SOLD' ||
            productStatus == 'BARTERED' ||
            productStatus == 'EXPIRED')) {
      return true;
    }

    final serviceStatus = _currentChat.service?.status.trim().toUpperCase();
    if (serviceStatus != null &&
        (serviceStatus == 'COMPLETED' || serviceStatus == 'CANCELLED')) {
      return true;
    }

    return false;
  }

  bool get _canShowOfferActions {
    if (!_currentChat.isActive) return false;
    if (_currentChat.hasAcceptedOffer) return false;
    if (_isReferenceUnavailable) return false;
    return true;
  }

  // Whether THIS user can start a brand-new offer right now — distinct from
  // _canShowOfferActions (which is about responding to an existing incoming
  // offer). Driven purely off the server's canMakeOffer: it's already false
  // for the owner, during an in-flight negotiation (either direction), once
  // accepted/completed, when the listing is unavailable, or when blocked —
  // and already true again for the interested user right after the owner
  // rejects an offer or cancels an accepted deal. Not recomputed
  // client-side, so it can't drift from what the server actually allows.
  bool get _canMakeNewOffer => _currentChat.canMakeOffer;

  // Whether THIS user is the one who would pay coins if a PRICE/BOTH offer
  // in this chat is accepted — mirrors the backend's deriveTerms rule
  // (DealVerificationService): for goods, the coin leg always flows from the
  // initiator (buyer) to the responder (listing owner), regardless of who
  // authored the offer/counter. For a service listing, direction flips when
  // the post itself is a "looking for service" request (the poster is the
  // one paying for a service, not providing one). A pure PRICE/BOTH wallet
  // check should only ever run for this user, never for whoever is about to
  // *receive* the coins.
  bool get _currentUserIsPayer {
    if (_currentChat.serviceId == null) {
      return widget.currentUserId == _currentChat.initiatorId;
    }
    final ownerIsProvider =
        _currentChat.service?.status != 'LOOKING_FOR_SERVICE';
    final providerId = ownerIsProvider
        ? _currentChat.responderId
        : _currentChat.initiatorId;
    final consumerId = providerId == _currentChat.initiatorId
        ? _currentChat.responderId
        : _currentChat.initiatorId;
    return widget.currentUserId == consumerId;
  }

  void _showErrorToast(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final cleaned = raw.startsWith('Bad request:')
        ? raw.replaceFirst('Bad request:', '').trim()
        : raw;
    final message = ErrorMessageUtils.sanitize(
      cleaned,
      fallback: 'Something went wrong. Please try again.',
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // Deep-link to the post detail screen (Point 7) — used by both the
  // tappable header card and the tappable CHAT_STARTED system card. Fetches
  // the full Post since the chat only carries a lightweight product/service
  // summary (id, title, images, price).
  Future<void> _openPostDetail() async {
    final postId = _currentChat.productId ?? _currentChat.serviceId;
    if (postId == null || _isOpeningPostDetail) return;
    final isService = _currentChat.serviceId != null;

    setState(() => _isOpeningPostDetail = true);
    try {
      final response = await ApiService().getPostDetail(
        postId: postId,
        type: isService ? PostType.service : PostType.product,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PostDetailScreen(post: response.post, userItems: const []),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      // 410 (deal completed elsewhere) / 403 (blocked) are expected states
      // for a post reached via a deep link, not real errors — show them
      // calmly instead of as a red failure toast.
      if (e is ApiException && (e.statusCode == 410 || e.statusCode == 403)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.statusCode == 410
                  ? 'This item is no longer available.'
                  : 'Post not available.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        _showErrorToast(e);
      }
    } finally {
      if (mounted) setState(() => _isOpeningPostDetail = false);
    }
  }

  // Deep-link to the OFFERED item's post detail (as opposed to
  // _openPostDetail, which is always the chat's own product/service).
  // Reuses _barterItemPostCache when available so a second tap is instant;
  // falls back to a fresh fetch otherwise.
  Future<void> _openBarterItemDetail(String productId) async {
    if (productId.isEmpty || _isOpeningPostDetail) return;

    final cached = _barterItemPostCache[productId];
    if (cached != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PostDetailScreen(post: cached, userItems: const []),
        ),
      );
      return;
    }

    setState(() => _isOpeningPostDetail = true);
    try {
      final response = await ApiService().getPostDetail(
        postId: productId,
        type: PostType.product,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PostDetailScreen(post: response.post, userItems: const []),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && (e.statusCode == 410 || e.statusCode == 403)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.statusCode == 410
                  ? 'This item is no longer available.'
                  : 'Post not available.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        _showErrorToast(e);
      }
    } finally {
      if (mounted) setState(() => _isOpeningPostDetail = false);
    }
  }

  // Generic deep-link for a `post` reference carried in a system message's
  // eventData (currently DEAL_COMPLETED_PENDING_OTHER) — unlike
  // _openBarterItemDetail this covers services too, keyed off postType.
  Future<void> _openEventPost(Map<String, dynamic>? post) async {
    if (post == null || _isOpeningPostDetail) return;
    final isService = post['postType'] == 'service';
    final postId = isService ? post['serviceId'] : post['productId'];
    if (postId == null || postId is! String || postId.isEmpty) return;

    setState(() => _isOpeningPostDetail = true);
    try {
      final response = await ApiService().getPostDetail(
        postId: postId,
        type: isService ? PostType.service : PostType.product,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PostDetailScreen(post: response.post, userItems: const []),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && (e.statusCode == 410 || e.statusCode == 403)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.statusCode == 410
                  ? 'This item is no longer available.'
                  : 'Post not available.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        _showErrorToast(e);
      }
    } finally {
      if (mounted) setState(() => _isOpeningPostDetail = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentChat = widget.chat;
    _messages = List.from(_currentChat.messages);
    if (_currentChat.otherUserOnline != null) {
      _isOtherUserOnline = _currentChat.otherUserOnline!;
    }
    _isBlocked = _currentChat.isBlocked;
    Future.microtask(_refreshChat);
    _scrollToBottom();
    _initializeSocketListeners();
    Future.microtask(_initializeSocketAndJoin);
    // So the More Options menu can correctly offer Block vs Unblock.
    unawaited(BlockedUsersCache.instance.ensureLoaded());
    WidgetsBinding.instance.addObserver(this);
    ResumeStateService.saveChat(widget.chat.id);
  }

  @override
  void dispose() {
    ResumeStateService.clearIfCurrent('chat', widget.chat.id);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    _leaveChatRoom();
    _socketService.off('connect', _handleSocketConnected);
    _socketService.off('new_message', _handleNewMessage);
    _socketService.off('offer_accepted', _handleOfferAccepted);
    _socketService.off('offer_rejected', _handleOfferRejected);
    _socketService.off('offer_created', _handleOfferCreated);
    _socketService.off('offer_withdrawn', _handleOfferWithdrawn);
    _socketService.off('chat_updated', _handleChatUpdated);
    _socketService.off('deal_completed', _handleDealCompleted);
    _socketService.off('deal_cancelled', _handleDealCancelled);
    _socketService.off('messages_read', _handleMessagesRead);
    _socketService.off('typing', _handleTypingIndicator);
    _socketService.off('user_presence', _handleUserPresence);
    _socketService.off('chat_blocked', _handleChatBlocked);
    _socketService.off('chat_unblocked', _handleChatUnblocked);
    WidgetsBinding.instance.removeObserver(this);
    _chatService.dispose();
    _blockedUserService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeSocketAndJoin();
      _refreshChat();
      _markMessagesAsRead();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _sendTypingStatus(false);
      _leaveChatRoom();
    }
  }

  void _initializeSocketListeners() {
    _socketService.on('connect', _handleSocketConnected);

    // Listen for new messages
    _socketService.on('new_message', _handleNewMessage);

    // Listen for offer events
    _socketService.on('offer_accepted', _handleOfferAccepted);
    _socketService.on('offer_rejected', _handleOfferRejected);
    _socketService.on('offer_created', _handleOfferCreated);
    _socketService.on('offer_withdrawn', _handleOfferWithdrawn);

    // Listen for chat updates
    _socketService.on('chat_updated', _handleChatUpdated);

    // Listen for deal events
    _socketService.on('deal_completed', _handleDealCompleted);
    _socketService.on('deal_cancelled', _handleDealCancelled);

    // Listen for read receipts
    _socketService.on('messages_read', _handleMessagesRead);

    // Listen for typing indicators
    _socketService.on('typing', _handleTypingIndicator);

    // Listen for user online/offline updates
    _socketService.on('user_presence', _handleUserPresence);

    // Listen for the other participant blocking/unblocking us — reacts
    // immediately instead of waiting on a manual refresh.
    _socketService.on('chat_blocked', _handleChatBlocked);
    _socketService.on('chat_unblocked', _handleChatUnblocked);
  }

  Future<void> _initializeSocketAndJoin() async {
    try {
      final token = await _tokenService.getToken();
      if (token == null || token.isEmpty) {
        return;
      }

      _socketService.init(token: token);

      final connected = await _waitForSocketConnection();
      if (!connected) {
        return;
      }

      _joinChatRoom();
      await _markMessagesAsRead();
    } catch (e) {
      print('Error initializing socket: $e');
    }
  }

  Future<bool> _waitForSocketConnection({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      if (_socketService.isConnected) {
        return true;
      }
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return _socketService.isConnected;
  }

  void _handleSocketConnected(dynamic _) {
    _joinChatRoom();
  }

  void _joinChatRoom() {
    _socketService.joinChat(_currentChat.id);
  }

  void _leaveChatRoom() {
    _socketService.leaveChat(_currentChat.id);
  }

  void _handleUserPresence(dynamic data) {
    if (!mounted || data == null) return;

    try {
      final chatId = data['chatId'];
      final userId = data['userId'];
      var isOnline = data['isOnline'] == true;
      final otherUser = _getOtherUser();

      if (chatId != null && chatId != _currentChat.id) return;
      if (userId != otherUser.id) return;

      // The live global user_online/offline broadcast isn't block-aware
      // server-side (unlike the REST getChatDetail snapshot, which already
      // forces this to false) — never show online for someone this user has
      // blocked (Point 6: "ignore if blocked user").
      if (isOnline && BlockedUsersCache.instance.isBlocked(userId)) {
        isOnline = false;
      }

      setState(() {
        _isOtherUserOnline = isOnline;
      });
    } catch (e) {
      print('Error handling user presence: $e');
    }
  }

  // Either side blocking the other disables messaging symmetrically
  // server-side, so react the same way regardless of who blocked whom —
  // no refresh needed, the composer disables the moment this arrives.
  void _handleChatBlocked(dynamic data) {
    if (!mounted || data == null) return;

    try {
      final chatId = data['chatId'];
      if (chatId != null && chatId != _currentChat.id) return;

      setState(() {
        _isBlocked = true;
      });
    } catch (e) {
      print('Error handling chat blocked: $e');
    }
  }

  // No chatId on this event (it's sent to a personal room, not a chat
  // room) — match on the other participant's id instead, then refetch so
  // canMakeOffer/status/etc. are back in sync with the now-unblocked state.
  void _handleChatUnblocked(dynamic data) {
    if (!mounted || data == null) return;

    try {
      final otherUserId = data['otherUserId'];
      final currentOtherUserId = _getOtherUser().id;
      if (otherUserId != null && otherUserId != currentOtherUserId) return;

      setState(() {
        _isBlocked = false;
      });
      unawaited(_refreshChat());
    } catch (e) {
      print('Error handling chat unblocked: $e');
    }
  }

  void _handleNewMessage(dynamic data) {
    if (!mounted) return;

    try {
      final messageData = data['message'] ?? data;
      final chatId = data['chatId'] ?? _currentChat.id;

      if (chatId != _currentChat.id) return;

      final newMessage = ChatMessage.fromJson(messageData);

      // Don't add if it's our own message (already added optimistically)
      if (newMessage.sentById == widget.currentUserId) return;

      // The server now also broadcasts chat:message_received authoritatively
      // from the REST send-message path (in addition to the raw socket
      // chat:message handler, and this client's own message:created relay
      // for images) — the same message id can arrive more than once.
      if (_messages.any((m) => m.id == newMessage.id)) return;

      setState(() {
        _messages.add(newMessage);
        _currentChat = _currentChat.copyWith(
          lastMessageAt: DateTime.now(),
          updatedAt: DateTime.now(),
          messages: _messages,
        );
      });

      _scrollToBottom();
      _markMessagesAsRead();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  Future<void> _handleOfferAccepted(dynamic data) async {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final offerId = data['offerId'];
      final offerData = data['offer'];

      if (chatId != _currentChat.id) return;

      // The room broadcast this came from also reaches the sender's own
      // socket — if this offer is already marked ACCEPTED, it's the echo of
      // an accept this client just performed and applied optimistically.
      // Skip it to avoid a duplicate system message and success toast.
      final existingIndex = _currentChat.offers.indexWhere(
        (o) => o.id == offerId,
      );
      if (existingIndex != -1 &&
          _currentChat.offers[existingIndex].offerStatus ==
              OfferStatus.ACCEPTED) {
        return;
      }

      setState(() {
        // Update the offer in the list
        final index = _currentChat.offers.indexWhere((o) => o.id == offerId);
        if (index != -1) {
          final updatedOffer = offerData != null
              ? TradeOffer.fromJson(offerData)
              : _currentChat.offers[index].copyWith(
                  offerStatus: OfferStatus.ACCEPTED,
                  acceptedAt: DateTime.now(),
                );
          _currentChat.offers[index] = updatedOffer;
        }
      });

      // The real "Offer accepted" system message is persisted server-side —
      // refresh to pick it up instead of fabricating a local one that could
      // drift from (or duplicate) what's actually in the chat's history.
      await _refreshChat();

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error handling offer accepted: $e');
    }
  }

  Future<void> _handleOfferRejected(dynamic data) async {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final offerId = data['offerId'];
      final offerData = data['offer'];

      if (chatId != _currentChat.id) return;

      // Same self-echo case as accept: skip if this offer is already marked
      // REJECTED locally, since that means this client just rejected it
      // itself and already applied the update optimistically.
      final existingIndex = _currentChat.offers.indexWhere(
        (o) => o.id == offerId,
      );
      if (existingIndex != -1 &&
          _currentChat.offers[existingIndex].offerStatus ==
              OfferStatus.REJECTED) {
        return;
      }

      setState(() {
        // Update the offer in the list
        final index = _currentChat.offers.indexWhere((o) => o.id == offerId);
        if (index != -1) {
          final updatedOffer = offerData != null
              ? TradeOffer.fromJson(offerData)
              : _currentChat.offers[index].copyWith(
                  offerStatus: OfferStatus.REJECTED,
                  rejectedAt: DateTime.now(),
                );
          _currentChat.offers[index] = updatedOffer;
        }
      });

      // The real "Offer rejected" system message is persisted server-side —
      // refresh to pick it up instead of fabricating a local one.
      await _refreshChat();

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      print('Error handling offer rejected: $e');
    }
  }

  Future<void> _handleOfferCreated(dynamic data) async {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final offer = data['offer'];

      if (chatId != _currentChat.id) return;

      final newOffer = TradeOffer.fromJson(offer);

      // The room broadcast this came from also reaches the sender's own
      // socket — if this offer is already in the list, it's the echo of an
      // offer this client just created and added optimistically. Skip it to
      // avoid adding the same offer/system message a second time.
      if (_currentChat.offers.any((o) => o.id == newOffer.id)) {
        return;
      }

      setState(() {
        _currentChat.offers.add(newOffer);
      });

      // The real "Offer sent"/"Counter offer sent" system message is
      // persisted server-side — refresh to pick it up.
      await _refreshChat();

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      print('Error handling offer created: $e');
    }
  }

  void _handleOfferWithdrawn(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final offerId = data['offerId'];

      if (chatId != _currentChat.id) return;

      // Same self-echo case as accept/reject: skip if this offer is already
      // marked WITHDRAWN locally, since that means this client just
      // withdrew it itself and already applied the update optimistically.
      final existingIndex = _currentChat.offers.indexWhere(
        (o) => o.id == offerId,
      );
      if (existingIndex != -1 &&
          _currentChat.offers[existingIndex].offerStatus ==
              OfferStatus.WITHDRAWN) {
        return;
      }

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offerId);
        if (index != -1) {
          final offer = _currentChat.offers[index];
          _currentChat.offers[index] = offer.copyWith(
            offerStatus: OfferStatus.WITHDRAWN,
          );
        }

        final systemMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tradeChatId: _currentChat.id,
          sentById: 'system',
          messageText: 'Offer withdrawn',
          messageType: MessageType.SYSTEM,
          isRead: true,
          createdAt: DateTime.now(),
          offerId: offerId,
        );

        _messages.add(systemMessage);
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      print('Error handling offer withdrawn: $e');
    }
  }

  void _handleChatUpdated(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final chatData = data['chat'];

      if (chatId != _currentChat.id) return;

      // Some socket translations emit only chatId without a full chat object.
      if (chatData is! Map<String, dynamic>) {
        _refreshChat();
        return;
      }

      final updatedChat = TradeChat.fromJson(chatData);

      setState(() {
        _currentChat = updatedChat;
        _messages = List.from(updatedChat.messages);
        _isBlocked = updatedChat.isBlocked;
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      print('Error handling chat updated: $e');
    }
  }

  void _handleDealCompleted(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];

      if (chatId != _currentChat.id) return;

      final partial = data['partial'] == true;
      unawaited(_refreshChat());

      if (!partial && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deal completed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error handling deal completed: $e');
    }
  }

  Future<void> _handleDealCancelled(dynamic data) async {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];

      if (chatId != _currentChat.id) return;

      setState(() {
        _currentChat = _currentChat.copyWith(
          status: ChatStatus.CANCELLED,
          updatedAt: DateTime.now(),
          messages: _messages,
        );
        _appendSystemMessageIfNotDuplicate('Trade cancelled');
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);

      // Cancelling reopens offering for the interested party — resync
      // canMakeOffer (and everything else server-computed) from the server
      // instead of leaving it stale until a manual refresh (Point: "Make
      // offer again" should reappear live after the owner cancels).
      await _refreshChat();
    } catch (e) {
      print('Error handling deal cancelled: $e');
    }
  }

  void _handleMessagesRead(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final messageIds = data['messageIds'] as List;

      if (chatId != _currentChat.id) return;

      setState(() {
        for (var i = 0; i < _messages.length; i++) {
          if (messageIds.contains(_messages[i].id)) {
            final msg = _messages[i];
            _messages[i] = ChatMessage(
              id: msg.id,
              tradeChatId: msg.tradeChatId,
              sentById: msg.sentById,
              messageText: msg.messageText,
              messageType: msg.messageType,
              isRead: true,
              createdAt: msg.createdAt,
              sentBy: msg.sentBy,
              imageUrl: msg.imageUrl,
              readAt: DateTime.now(),
              offerId: msg.offerId,
            );
          }
        }
      });
    } catch (e) {
      print('Error handling messages read: $e');
    }
  }

  void _handleTypingIndicator(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final userId = data['userId'];
      final isTyping = data['isTyping'];

      if (chatId != _currentChat.id || userId == widget.currentUserId) return;

      // You can show typing indicator in UI here
      // For now, just log it
      if (isTyping) {
        print('User $userId is typing...');
      }
    } catch (e) {
      print('Error handling typing indicator: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final unreadMessageIds = _messages
          .where((msg) => !msg.isRead && msg.sentById != widget.currentUserId)
          .map((msg) => msg.id)
          .toList();

      if (unreadMessageIds.isNotEmpty) {
        await _chatService.markMessagesAsRead(_currentChat.id);
        _socketService.markMessagesRead(_currentChat.id, unreadMessageIds);

        setState(() {
          for (var i = 0; i < _messages.length; i++) {
            if (unreadMessageIds.contains(_messages[i].id)) {
              final msg = _messages[i];
              _messages[i] = ChatMessage(
                id: msg.id,
                tradeChatId: msg.tradeChatId,
                sentById: msg.sentById,
                messageText: msg.messageText,
                messageType: msg.messageType,
                isRead: true,
                createdAt: msg.createdAt,
                sentBy: msg.sentBy,
                imageUrl: msg.imageUrl,
                readAt: DateTime.now(),
                offerId: msg.offerId,
              );
            }
          }
        });
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _sendTypingStatus(bool isTyping) {
    if (_isTyping != isTyping) {
      _isTyping = isTyping;
      _socketService.sendTyping(_currentChat.id, isTyping);

      if (isTyping) {
        _typingTimer?.cancel();
        _typingTimer = Timer(const Duration(seconds: 3), () {
          if (_isTyping) {
            _sendTypingStatus(false);
          }
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    if (!_socketService.isConnected) {
      await _initializeSocketAndJoin();
    }

    if (!_socketService.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection lost. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final content = _messageController.text.trim();
    _messageController.clear();
    _sendTypingStatus(false);

    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tradeChatId: _currentChat.id,
      sentById: widget.currentUserId,
      messageText: content,
      messageType: MessageType.TEXT,
      isRead: false,
      createdAt: DateTime.now(),
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final sentMessageJson = await _socketService.sendMessageWithAck(
        chatId: _currentChat.id,
        messageText: content,
      );
      final sentMessage = ChatMessage.fromJson(sentMessageJson);

      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage;
        }
      });

      _updateChatLastMessage();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      // A block (either direction) rejects the send with a 403/"cannot
      // message this user" — belt-and-suspenders alongside the live
      // chat:blocked event, in case that broadcast is delayed or missed.
      final isBlockedError = e.toString().toLowerCase().contains(
        'cannot message this user',
      );

      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
        if (isBlockedError) _isBlocked = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBlockedError
                  ? 'You can no longer message this user.'
                  : 'Failed to send message: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateChatLastMessage() {
    _currentChat = _currentChat.copyWith(
      lastMessageAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: _messages,
    );
  }

  Future<void> _refreshChat() async {
    try {
      final updatedChat = await _chatService.getChatById(_currentChat.id);
      setState(() {
        _currentChat = updatedChat;
        _messages = List.from(updatedChat.messages);
        if (updatedChat.otherUserOnline != null) {
          _isOtherUserOnline = updatedChat.otherUserOnline!;
        }
        _isBlocked = updatedChat.isBlocked;
      });
      _scrollToBottom();
    } catch (e) {
      print('Error refreshing chat: $e');
    }
  }

  // Same as _refreshChat, but with the full-screen loading state Accept/
  // Reject already show while they refetch — used only for
  // DealVerificationPanel's Deal Completed / Deal Not Completed actions so
  // all four offer/deal actions give the same clear "the screen just
  // refreshed" feedback. Deliberately NOT used for pull-to-refresh or
  // background socket-driven refreshes, which already have their own
  // (non-disruptive) way of showing progress.
  Future<void> _refreshChatWithFullScreenLoader() async {
    if (mounted) setState(() => _isLoading = true);
    await _refreshChat();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _pickAndSendImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() {
        _isSendingImage = true;
      });

      final imageFile = File(pickedFile.path);

      // Add temporary loading message
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: widget.currentUserId,
        messageText: 'Sending image...',
        messageType: MessageType.TEXT,
        isRead: false,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(tempMessage);
      });
      _scrollToBottom();

      // Upload image
      final sentMessage = await _chatService.uploadImageMessage(
        chatId: _currentChat.id,
        imageFile: imageFile,
      );

      // Created over REST (image upload needs the presigned-URL round
      // trip first) — ask the socket layer to relay it to the room so the
      // other participant sees it live instead of on their next refresh.
      _socketService.emitMessageCreated(_currentChat.id, sentMessage.id);

      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage;
        }
        _isSendingImage = false;
      });

      _updateChatLastMessage();
      widget.onChatUpdated(_currentChat);

      _scrollToBottom();
    } catch (e) {
      final isBlockedError = e.toString().toLowerCase().contains(
        'cannot message this user',
      );

      setState(() {
        _isSendingImage = false;
        _messages.removeWhere((m) => m.messageText == 'Sending image...');
        if (isBlockedError) _isBlocked = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBlockedError
                  ? 'You can no longer message this user.'
                  : 'Failed to send image: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Updated accept offer method with socket emit and full refresh
  Future<void> _acceptOffer(TradeOffer offer) async {
    if (!_canShowOfferActions) {
      _showErrorToast('Offers are not available for this chat.');
      return;
    }
    if (_isOfferActionInProgress) return;

    setState(() {
      _isLoading = true;
      _isOfferActionInProgress = true;
      _processingOfferId = offer.id;
    });

    try {
      final acceptedOffer = await _chatService.acceptOffer(
        _currentChat.id,
        offer.id,
      );

      // Emit socket event
      _socketService.emitOfferAccepted(_currentChat.id, offer.id);

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _currentChat.offers[index] = acceptedOffer;
        }
      });

      // Refresh entire chat to get latest state, including the real
      // "Offer accepted" system message persisted server-side.
      await _refreshChat();

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offer accepted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showErrorToast(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOfferActionInProgress = false;
          _processingOfferId = null;
        });
      }
    }
  }

  // Updated reject offer method with socket emit and full refresh
  Future<void> _rejectOffer(TradeOffer offer) async {
    if (!_canShowOfferActions) {
      _showErrorToast('Offers are not available for this chat.');
      return;
    }
    if (_isOfferActionInProgress) return;

    setState(() {
      _isLoading = true;
      _isOfferActionInProgress = true;
      _processingOfferId = offer.id;
    });

    try {
      final rejectedOffer = await _chatService.rejectOffer(
        _currentChat.id,
        offer.id,
      );

      // Emit socket event
      _socketService.emitOfferRejected(_currentChat.id, offer.id);

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _currentChat.offers[index] = rejectedOffer;
        }
      });

      // Refresh entire chat to get latest state, including the real
      // "Offer rejected" system message persisted server-side.
      await _refreshChat();

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      _showErrorToast(e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isOfferActionInProgress = false;
          _processingOfferId = null;
        });
      }
    }
  }

  // Same backend-driven "How do you want to exchange?" flow used for a
  // first-time offer from the product/service detail screen — including
  // cross-mode requests (e.g. requesting a barter on a pure-price listing).
  // A re-offer from inside the chat must present exactly the same options
  // as an original offer, so this deliberately shares showExchangeModeSheet
  // / confirmCrossModeOption / mapOfferTypeToSubmissionMode with
  // PostDetailScreen instead of guessing locally from cached capability
  // flags.
  Future<void> _showMakeOfferDialog() async {
    if (!_canMakeNewOffer) {
      _showErrorToast(
        _currentChat.myPendingOffer
            ? 'Waiting for ${_getOtherUser().firstName} to respond to your offer.'
            : 'Offers are no longer available for this chat.',
      );
      return;
    }

    if (_isPreparingOffer) return;
    setState(() => _isPreparingOffer = true);

    ExchangeModeOptions options;
    try {
      options = await _chatService.getExchangeModeOptions(
        productId: _currentChat.productId,
        serviceId: _currentChat.serviceId,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPreparingOffer = false);
      _showErrorToast(e);
      return;
    }
    if (!mounted) return;
    setState(() => _isPreparingOffer = false);

    if (!options.canRequest) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot make an offer on this item right now'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final selectedOption = await showExchangeModeSheet(context, options);
    if (!mounted || selectedOption == null) return;

    if (selectedOption is ZeroCoinSelected) {
      await _navigateToOfferScreen(
        offerMode: OfferSubmissionMode.barter,
        isZeroCoin: true,
      );
      return;
    }

    if (selectedOption is! ExchangeModeOption) return;

    if (selectedOption.isCrossMode) {
      final confirmed = await confirmCrossModeOption(context, selectedOption);
      if (!mounted || confirmed != true) return;
    }

    final offerMode = mapOfferTypeToSubmissionMode(selectedOption.offerType);
    await _navigateToOfferScreen(
      selectedOption: selectedOption,
      offerMode: offerMode,
    );
  }

  // Every mode — including a plain coins offer — goes through the exact
  // same offer-composition screens a first-time offer uses (Offer Summary
  // card, quoted price, description, real barterItemIds picker for
  // barter/both), never a stripped-down local dialog. Barter/Both (and
  // zero-coin, whose item is optional) need OfferDeckScreen's picker first;
  // a pure coins offer goes straight to OfferDescriptionScreen.
  Future<void> _navigateToOfferScreen({
    ExchangeModeOption? selectedOption,
    required OfferSubmissionMode offerMode,
    bool isZeroCoin = false,
  }) async {
    final postId = _currentChat.productId ?? _currentChat.serviceId;
    if (postId == null) return;
    final isService = _currentChat.serviceId != null;

    if (_isPreparingOffer) return;
    setState(() => _isPreparingOffer = true);

    Post post;
    try {
      final response = await ApiService().getPostDetail(
        postId: postId,
        type: isService ? PostType.service : PostType.product,
      );
      post = response.post;
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPreparingOffer = false);
      _showErrorToast(e);
      return;
    }
    if (!mounted) return;
    setState(() => _isPreparingOffer = false);

    final requiresProductSelection =
        isZeroCoin || (selectedOption?.requiresProductSelection ?? true);

    if (!requiresProductSelection) {
      final hasEnoughBalance = await _ensureSufficientWalletBalance(post);
      if (!mounted || !hasEnoughBalance) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OfferDescriptionScreen(
            post: post,
            selectedItems: const [],
            currentUserId: widget.currentUserId,
            isService: isService,
            offerMode: offerMode,
          ),
        ),
      );
      // Covers the "backed out without submitting" case — refresh so a
      // listingUnavailable/canMakeOffer change that happened meanwhile
      // (Point 8's race: a deal on this item completed elsewhere) shows up
      // immediately instead of waiting for the next natural refresh.
      if (mounted) unawaited(_refreshChat());
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OfferDeckScreen(
          post: post,
          currentUserId: widget.currentUserId,
          offerMode: offerMode,
          isZeroCoin: isZeroCoin,
        ),
      ),
    );
    if (mounted) unawaited(_refreshChat());
  }

  // Pre-flight check against the listing price before even navigating to
  // the offer-composition screen (OfferDescriptionScreen re-validates
  // against the actual entered amount on submit regardless).
  Future<bool> _ensureSufficientWalletBalance(Post post) async {
    final required = post.price;
    if (required <= 0) return true;

    return WalletOfferGuard.ensureCanAfford(
      context,
      requiredCoins: required,
      itemName: post.title,
    );
  }

  Future<void> _showCounterOfferDialog(TradeOffer originalOffer) async {
    if (!_currentChat.isActive || _currentChat.hasAcceptedOffer) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Counter offers are not available for this chat anymore.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!originalOffer.isPending ||
        originalOffer.madeById == widget.currentUserId) {
      return;
    }

    if (originalOffer.isPriceOffer) {
      await _showCounterPriceOfferDialog(originalOffer);
      return;
    }

    if (originalOffer.isBothOffer) {
      await _showCounterBothOfferDialog(originalOffer);
      return;
    }

    await _showCounterBarterOfferDialog(originalOffer);
  }

  double? get _listingPrice {
    final productPrice = _currentChat.product?.price;
    if (productPrice != null && productPrice > 0) return productPrice;

    final servicePrice = _currentChat.service?.price;
    if (servicePrice != null && servicePrice > 0) return servicePrice;

    return null;
  }

  String? _validateOfferPriceAgainstListing(double price) {
    if (price <= 0) {
      return 'Enter a valid price';
    }

    final listing = _listingPrice;
    if (listing == null) {
      // No listing price to bound against (e.g. barter-only listing) — fall
      // back to the same 6-digit cap as the price field itself so it still
      // can't take an arbitrarily large number.
      if (price.toStringAsFixed(0).length > 6) {
        return 'Price cannot exceed 6 digits';
      }
      return null;
    }

    if (price.round() > listing.round()) {
      return 'Offer cannot exceed listing price of '
          '${CoinFormat.withUnit(listing)}';
    }

    return null;
  }

  Future<void> _showOfferMessageDialog(String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Offer'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCounterPriceOfferDialog(TradeOffer originalOffer) async {
    // Coins are whole numbers (see allowDecimal: false below), so the
    // starting text must be too — a leftover ".00" from toStringAsFixed(2)
    // makes every edit fail the digits-only formatter and silently revert,
    // which looks like the field can't be edited at all.
    final priceController = TextEditingController(
      text: originalOffer.price != null && originalOffer.price! > 0
          ? (originalOffer.price == originalOffer.price!.roundToDouble()
                ? originalOffer.price!.toInt().toString()
                : originalOffer.price!.toStringAsFixed(2))
          : '',
    );
    // Empty, not seeded from the original offer's description — same
    // reasoning as the barter counter dialogs (a previous round's note
    // shouldn't carry forward and compound).
    final descriptionController = TextEditingController();
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Counter Coins Offer'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (dialogError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: Validators.amountInputFormatters(
                    allowDecimal: false,
                    maxLength: 6,
                  ),
                  onChanged: (_) {
                    if (dialogError != null) {
                      setDialogState(() => dialogError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Your Counter Coins',
                    prefixIcon: coinInputPrefix(),
                    prefixIconConstraints: coinPrefixIconConstraints,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final trimmed = priceController.text.trim();
                  if (trimmed.isEmpty) {
                    setDialogState(() => dialogError = 'Enter coins');
                    return;
                  }

                  final parsed = double.tryParse(trimmed);
                  if (parsed == null) {
                    setDialogState(
                      () => dialogError = 'Enter a valid coin amount',
                    );
                    return;
                  }

                  final validationError = _validateOfferPriceAgainstListing(
                    parsed,
                  );
                  if (validationError != null) {
                    setDialogState(() => dialogError = validationError);
                    return;
                  }

                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Send Counter'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true || priceController.text.trim().isEmpty) return;

    final parsedPrice = double.tryParse(priceController.text.trim());
    if (parsedPrice == null) return;

    if (!mounted) return;
    // Only the payer's wallet needs checking — a listing owner countering
    // with a higher price is naming what they want to *receive*, not
    // spending their own coins.
    if (_currentUserIsPayer) {
      final canAfford = await WalletOfferGuard.ensureCanAfford(
        context,
        requiredCoins: parsedPrice,
        itemName: _currentChat.postTitle,
      );
      if (!canAfford || !mounted) return;
    }

    await _createCounterOffer(
      originalOffer: originalOffer,
      offerType: 'PRICE',
      price: parsedPrice,
      barterItemDescription: descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null,
    );
  }

  String _titleForCounterItems(List<UserItem> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first.name;
    final firstTwo = items.take(2).map((item) => item.name).join(', ');
    final remaining = items.length - 2;
    return remaining > 0 ? '$firstTwo +$remaining more' : firstTwo;
  }

  // Real product picker for counter-offers — sends actual barterItemIds
  // (like the initial-offer flow already does) instead of a free-typed
  // title, and enforces the same clubbing rule as OfferDeckScreen so a
  // multi-product counter settles correctly (every id gets marked sold,
  // not just the listing).
  Future<List<UserItem>?> _pickCounterBarterItems(
    List<UserItem> initialSelection,
  ) async {
    List<UserItem> allItems = [];
    bool isLoading = true;
    String? loadError;
    List<UserItem> selected = List.from(initialSelection);

    Future<void> loadItems(StateSetter setSheetState) async {
      try {
        final response = await MyPostsService().getMyPosts(page: 1, limit: 50);
        final items = response.data.posts
            .where((p) => p.postedById == widget.currentUserId)
            .where((p) => p.type.toLowerCase() == 'product')
            .where((p) => p.isListed == true)
            .where((p) => !p.isExpiredOrUnavailable)
            .where(
              (p) =>
                  p.isOpenForBarter ||
                  p.status.trim().toUpperCase() == 'FOR_BARTER',
            )
            .where(
              (p) =>
                  p.status.toUpperCase() != 'SOLD' &&
                  p.status.toUpperCase() != 'ARCHIVED' &&
                  p.status.toUpperCase() != 'DELETED',
            )
            // Exclude items already committed to the live pending offer —
            // they can't be re-added to a fresh counter-offer selection.
            .where((p) => !_currentChat.activeBarterProductIds.contains(p.id))
            // Exclude the listing itself (chat.product) — it's the item
            // being negotiated FOR, not something the listing owner can
            // also offer back as a barter item in the same deal. Without
            // this, the owner's own listing kept reappearing as a
            // selectable "item to offer" alongside their other products.
            .where((p) => p.id != _currentChat.productId)
            .map(
              (p) => UserItem(
                id: p.id,
                name: p.title,
                description: p.description,
                imageUrl: p.images.isNotEmpty ? p.images.first : '',
                category: p.category.name,
                price: p.price ?? 0.0,
                value: p.price ?? 0.0,
                isClubbable: p.isClubbable,
              ),
            )
            .toList();
        setSheetState(() {
          allItems = items;
          isLoading = false;
        });
      } catch (e) {
        setSheetState(() {
          loadError = 'Could not load your items';
          isLoading = false;
        });
      }
    }

    return showModalBottomSheet<List<UserItem>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        bool hasStartedLoad = false;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            if (!hasStartedLoad) {
              hasStartedLoad = true;
              loadItems(setSheetState);
            }
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select items to offer',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Items with clubbing off can only be offered alone.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: isLoading
                              ? const Center(child: CircularProgressIndicator())
                              : loadError != null
                              ? Center(child: Text(loadError!))
                              : allItems.isEmpty
                              ? const Center(
                                  child: Text('No barter-eligible items'),
                                )
                              : GridView.builder(
                                  controller: scrollController,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                        childAspectRatio: 0.8,
                                      ),
                                  itemCount: allItems.length,
                                  itemBuilder: (context, index) {
                                    final item = allItems[index];
                                    final isSelected = selected.any(
                                      (i) => i.id == item.id,
                                    );
                                    return GestureDetector(
                                      onTap: () {
                                        final result = applyClubbingSelection(
                                          current: selected,
                                          tapped: item,
                                        );
                                        setSheetState(
                                          () => selected = result.items,
                                        );
                                        if (result.hint != null) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(result.hint!),
                                              duration: const Duration(
                                                seconds: 2,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF2E5BFF)
                                                    : Colors.grey.shade300,
                                                width: isSelected ? 2 : 1,
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                                  Expanded(
                                                    child:
                                                        item.imageUrl.isNotEmpty
                                                        ? Image.network(
                                                            item.imageUrl,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) => Container(
                                                                  color: Colors
                                                                      .grey
                                                                      .shade200,
                                                                  child: const Icon(
                                                                    Icons.image,
                                                                  ),
                                                                ),
                                                          )
                                                        : Container(
                                                            color: Colors
                                                                .grey
                                                                .shade200,
                                                            child: const Icon(
                                                              Icons.image,
                                                            ),
                                                          ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    child: Text(
                                                      item.name,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF2E5BFF),
                                                size: 18,
                                              ),
                                            ),
                                          if (!item.isClubbable)
                                            Positioned(
                                              bottom: 22,
                                              left: 4,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 1,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.black54,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Solo only',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () => Navigator.pop(sheetContext, selected),
                            child: Text(
                              selected.isEmpty
                                  ? 'Select at least one item'
                                  : 'Use ${selected.length} item${selected.length > 1 ? 's' : ''}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _showCounterBarterOfferDialog(TradeOffer originalOffer) async {
    // Deliberately empty, not seeded from originalOffer.barterItemDescription
    // — that text is the PREVIOUS round's note (already carrying its own
    // "Offered items: ..." line appended by OfferDescriptionScreen), so
    // pre-filling it here would let old notes compound across rounds
    // instead of the user writing a fresh one for this counter.
    final descriptionController = TextEditingController();
    List<UserItem> selectedItems = [];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final border = OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade500, width: 1.2),
        );

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              scrollable: true,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 24,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade300, width: 1.2),
              ),
              title: const Text('Counter Barter Offer'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await _pickCounterBarterItems(
                          selectedItems,
                        );
                        if (picked != null) {
                          setDialogState(() => selectedItems = picked);
                        }
                      },
                      icon: const Icon(Icons.add_box_outlined),
                      label: Text(
                        selectedItems.isEmpty
                            ? 'Select items to offer'
                            : 'Edit selection (${selectedItems.length})',
                      ),
                    ),
                    if (selectedItems.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: selectedItems
                            .map(
                              (item) => Chip(
                                avatar: item.imageUrl.isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          item.imageUrl,
                                        ),
                                      )
                                    : null,
                                label: Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Optional',
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border.copyWith(
                          borderSide: const BorderSide(
                            color: Color(0xFF2E5BFF),
                            width: 1.8,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E5BFF),
                    side: const BorderSide(
                      color: Color(0xFF2E5BFF),
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedItems.isEmpty
                      ? null
                      : () => Navigator.pop(context, true),
                  child: const Text('Send Counter'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != true || selectedItems.isEmpty) return;

    await _createCounterOffer(
      originalOffer: originalOffer,
      offerType: 'BARTER',
      barterItemTitle: _titleForCounterItems(selectedItems),
      barterItemDescription: descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null,
      barterItemIds: selectedItems.map((item) => item.id).toList(),
      barterItemImages: selectedItems
          .map((item) => item.imageUrl)
          .where((url) => url.trim().isNotEmpty)
          .toList(),
    );
  }

  /// Counter a Barter + Price ("Both") offer with coins only — the
  /// responder isn't required to pick an item of their own just to
  /// negotiate the coin amount (it used to force that, via the same
  /// item-selection block as the plain barter counter dialog). The barter
  /// item already on the table from `originalOffer` is kept automatically —
  /// this dialog only renegotiates the coin amount — so it survives to
  /// acceptance and isn't lost from trade history the way it used to be
  /// when this silently downgraded the counter to a coins-only PRICE offer.
  Future<void> _showCounterBothOfferDialog(TradeOffer originalOffer) async {
    // Same reasoning as the pure-barter counter dialog: start empty rather
    // than carrying the previous round's (already-appended) description
    // forward, so notes don't compound across counters.
    final descriptionController = TextEditingController();
    final priceController = TextEditingController(
      text: originalOffer.price != null && originalOffer.price! > 0
          ? (originalOffer.price == originalOffer.price!.roundToDouble()
                ? originalOffer.price!.toInt().toString()
                : originalOffer.price!.toStringAsFixed(2))
          : '',
    );
    String? dialogError;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final border = OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade500, width: 1.2),
          );

          return AlertDialog(
            scrollable: true,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 24,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.grey.shade300, width: 1.2),
            ),
            title: const Text('Counter with Coins'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dialogError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        dialogError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  // The barter item already on the table stays part of the
                  // deal — only the coin amount is being renegotiated here.
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        _buildOfferItemThumb(
                          originalOffer.barterProducts.isNotEmpty
                              ? originalOffer.barterProducts.first.firstImage
                              : (originalOffer.barterItemImages.isNotEmpty
                                    ? originalOffer.barterItemImages.first
                                    : ''),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Item stays part of this offer',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                _offeredItemsLabel(originalOffer),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional',
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: const BorderSide(
                          color: Color(0xFF2E5BFF),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: Validators.amountInputFormatters(
                      allowDecimal: false,
                      maxLength: 6,
                    ),
                    onChanged: (_) {
                      if (dialogError != null) {
                        setDialogState(() => dialogError = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Coins to Pay',
                      prefixIcon: coinInputPrefix(),
                      prefixIconConstraints: coinPrefixIconConstraints,
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border.copyWith(
                        borderSide: const BorderSide(
                          color: Color(0xFF2E5BFF),
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E5BFF),
                  side: const BorderSide(color: Color(0xFF2E5BFF), width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final trimmedPrice = priceController.text.trim();
                  if (trimmedPrice.isEmpty) {
                    setDialogState(() => dialogError = 'Enter coins to pay');
                    return;
                  }

                  final parsed = double.tryParse(trimmedPrice);
                  if (parsed == null || parsed <= 0) {
                    setDialogState(
                      () => dialogError = 'Enter a valid coin amount',
                    );
                    return;
                  }

                  final validationError = _validateOfferPriceAgainstListing(
                    parsed,
                  );
                  if (validationError != null) {
                    setDialogState(() => dialogError = validationError);
                    return;
                  }

                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Send Counter'),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    final parsedPrice = double.tryParse(priceController.text.trim());
    if (parsedPrice == null) return;

    if (!mounted) return;
    // Only the payer's wallet needs checking — see the PRICE counter above.
    if (_currentUserIsPayer) {
      final canAfford = await WalletOfferGuard.ensureCanAfford(
        context,
        requiredCoins: parsedPrice,
        itemName: _currentChat.postTitle,
      );
      if (!canAfford || !mounted) return;
    }

    await _createCounterOffer(
      originalOffer: originalOffer,
      offerType: 'BOTH',
      price: parsedPrice,
      barterItemDescription: descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null,
      // The server derives the actual barter item from `originalOffer`
      // itself (the countering user doesn't own it, so it can't be
      // re-validated as something they're offering) — these are sent too
      // so the optimistic local update below renders correctly before the
      // next refresh confirms the server's copy.
      barterItemTitle: originalOffer.barterItemTitle,
      barterItemImages: originalOffer.barterItemImages,
      barterItemIds: originalOffer.barterProductIds,
      keepOriginalBarterItems: true,
    );
  }

  Future<TradeOffer?> _createCounterOffer({
    required TradeOffer originalOffer,
    required String offerType,
    double? price,
    String? barterItemTitle,
    String? barterItemDescription,
    List<String> barterItemIds = const [],
    List<String> barterItemImages = const [],
    bool keepOriginalBarterItems = false,
  }) async {
    if (!_currentChat.isActive ||
        _currentChat.hasAcceptedOffer ||
        _isReferenceUnavailable ||
        !originalOffer.isPending ||
        originalOffer.madeById == widget.currentUserId) {
      return null;
    }

    if ((offerType == 'PRICE' || offerType == 'BOTH') && price != null) {
      final validationError = _validateOfferPriceAgainstListing(price);
      if (validationError != null) {
        await _showOfferMessageDialog(validationError);
        return null;
      }
    }

    setState(() {
      _isOfferActionInProgress = true;
      _processingOfferId = originalOffer.id;
    });

    try {
      final counterOffer = await _chatService.createCounterOffer(
        chatId: _currentChat.id,
        offerId: originalOffer.id,
        offerType: offerType,
        price: price,
        barterItemTitle: barterItemTitle,
        barterItemDescription: barterItemDescription,
        barterItemIds: barterItemIds,
        barterItemImages: barterItemImages,
        keepOriginalBarterItems: keepOriginalBarterItems,
      );

      _socketService.emitOfferCreated(_currentChat.id, counterOffer.toJson());

      setState(() {
        _currentChat.offers.add(counterOffer);
      });

      // Picks up the real "Counter offer sent" system message persisted
      // server-side.
      await _refreshChat();

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
      return counterOffer;
    } catch (e) {
      if (mounted) {
        _showErrorToast(e);
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isOfferActionInProgress = false;
          _processingOfferId = null;
        });
      }
    }
  }

  Future<void> _withdrawOffer(TradeOffer offer) async {
    if (!offer.isPending) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _chatService.withdrawOffer(offer.id);

      // Emit socket event
      _socketService.emitOfferWithdrawn(_currentChat.id, offer.id);

      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Offer withdrawn',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        offerId: offer.id,
      );

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _currentChat.offers[index] = offer.copyWith(
            offerStatus: OfferStatus.WITHDRAWN,
          );
        }
        _messages.add(systemMessage);
        _isLoading = false;
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to withdraw offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _acceptedOfferRequiresCoinPayment() {
    final offer = _currentChat.latestAcceptedOffer;
    if (offer == null) return false;
    if (!offer.isPriceOffer && !offer.isBothOffer) return false;
    return (offer.price ?? 0) > 0;
  }

  bool _dealRequiresCoinPayment() {
    return (_resolveDealPaymentAmount() ?? 0) > 0;
  }

  /// Offer price first, then product listing price — but only when there is
  /// no accepted offer to read from. A pure barter (item-for-item) offer has
  /// no price by design (Condition 1: equal-value swap, no coins change
  /// hands), so it must never fall back to charging the full listing price.
  int? _resolveDealPaymentAmount({String? dialogPriceText}) {
    if (dialogPriceText != null && dialogPriceText.trim().isNotEmpty) {
      final fromDialog = _coinAmountFromPrice(dialogPriceText);
      if (fromDialog > 0) return fromDialog;
    }

    final offer = _currentChat.latestAcceptedOffer;
    if (offer != null) {
      if (offer.isBarterOffer) return null;
      if (offer.price != null && offer.price! > 0) {
        return _coinAmountFromPrice(offer.price);
      }
      return null;
    }

    final productPrice = _currentChat.product?.price;
    if (productPrice != null && productPrice > 0) {
      return _coinAmountFromPrice(productPrice);
    }

    return null;
  }

  /// Product/service owner is always [responderId] in initiate-chat flows.
  String get _listingOwnerId => _currentChat.responderId;

  /// Who owes coins on this deal, and to whom.
  ///
  /// - PRICE offers (Condition 3, pure purchase): there is no bartered item,
  ///   so the buyer (non-owner) always pays the listing owner, regardless of
  ///   who typed the number into the offer.
  /// - BOTH offers (Condition 2, barter + price difference): the offer maker
  ///   is proposing "my item + this much money", so whoever made the accepted
  ///   BOTH offer is always the one who owes the difference — that could be
  ///   either the initiator or the listing owner, depending on whose item is
  ///   worth less.
  /// - BARTER offers (Condition 1) never require payment.
  String? get _dealPayerId {
    if (!_dealRequiresCoinPayment()) return null;
    final offer = _currentChat.latestAcceptedOffer;
    if (offer != null && offer.isBothOffer) {
      return offer.madeById;
    }
    return widget.currentUserId != _listingOwnerId
        ? widget.currentUserId
        : _currentChat.initiatorId;
  }

  String get _otherParticipantId =>
      widget.currentUserId == _currentChat.initiatorId
      ? _currentChat.responderId
      : _currentChat.initiatorId;

  bool _currentUserPaysOnDealComplete() {
    return _dealPayerId == widget.currentUserId;
  }

  int _coinAmountFromPrice(dynamic priceValue) {
    if (priceValue == null) return 0;
    if (priceValue is int) return priceValue;
    if (priceValue is double) return priceValue.round();
    final parsed = double.tryParse(priceValue.toString().trim());
    return parsed?.round() ?? 0;
  }

  Future<bool> _payDealCoins({
    required int amount,
    required String offerId,
  }) async {
    final wallet = await _coinService.getWallet();
    final balance = CoinService.parseCoinAmount(wallet?['balance']);

    if (balance < amount) {
      if (!mounted) return false;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CoinsWalletScreen(requiredAmount: amount.toDouble()),
        ),
      );
      if (!mounted) return false;

      final refreshedWallet = await _coinService.getWallet();
      final refreshedBalance = CoinService.parseCoinAmount(
        refreshedWallet?['balance'],
      );
      if (refreshedBalance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You need ${CoinFormat.withUnit(amount)} to complete this deal.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return false;
      }
    }

    await _coinService.pay(
      toUserId: _otherParticipantId,
      amount: amount,
      referenceId: _currentChat.id,
      referenceType: 'ORDER_PAYMENT',
      description: 'Wallet payment',
      metadata: {
        'source': 'mobile-app',
        'chatId': _currentChat.id,
        if (_currentChat.productId != null)
          'productId': _currentChat.productId!,
        'offerId': offerId,
      },
      idempotencyKey: '${_currentChat.id}-$offerId-pay',
    );
    return true;
  }

  Future<void> _completeTrade() async {
    if (_isShowingDealCompletionDialog) return;

    _isShowingDealCompletionDialog = true;

    final acceptedOffer = _currentChat.latestAcceptedOffer;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DealCompletionDialog(
        // Only the participant who actually owes coins should see the
        // "coins will be deducted" prompt — the other side of the deal
        // never gets charged (see _currentUserPaysOnDealComplete).
        isPriceOffer:
            _dealRequiresCoinPayment() && _currentUserPaysOnDealComplete(),
        acceptedPrice: (acceptedOffer != null && acceptedOffer.isBarterOffer)
            ? null
            : (acceptedOffer?.price ?? _currentChat.product?.price),
      ),
    );

    _isShowingDealCompletionDialog = false;

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUserPaysOnDealComplete()) {
        final amount = _resolveDealPaymentAmount(
          dialogPriceText: result['price']?.toString(),
        );
        if (amount == null || amount <= 0) {
          throw Exception('Deal price is unavailable');
        }

        final paid = await _payDealCoins(
          amount: amount,
          offerId: acceptedOffer?.id ?? _currentChat.id,
        );
        if (!paid) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // markDealCompleted already re-fetches the full chat server-side, so
      // updatedChat.messages carries the real, persisted system message for
      // whichever outcome happened (fully completed, or waiting on the
      // other party) — sync from it instead of fabricating local text.
      final updatedChat = await _chatService.markDealCompleted(
        chatId: _currentChat.id,
        remarks: result['remarks'] ?? 'accepted',
      );

      setState(() {
        _currentChat = updatedChat;
        _messages = List.from(updatedChat.messages);
        _isLoading = false;
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        await _refreshChat();
      }
    }
  }

  /// Prompts for why the deal fell through. Returns the trimmed reason, or
  /// null if the user backed out without submitting one.
  Future<String?> _showDealNotCompletedReasonDialog() async {
    final reasonController = TextEditingController();
    String? dialogError;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Deal Not Completed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Let the other person know why this deal fell through. '
                  'The item goes back on the marketplace immediately.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                if (dialogError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      dialogError!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                TextField(
                  controller: reasonController,
                  autofocus: true,
                  maxLines: 3,
                  maxLength: 300,
                  onChanged: (_) {
                    if (dialogError != null) {
                      setDialogState(() => dialogError = null);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText:
                        'e.g. Buyer did not show up, item condition '
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
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    setDialogState(() => dialogError = 'Please enter a reason');
                    return;
                  }
                  Navigator.pop(dialogContext, reason);
                },
                child: const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _markDealNotCompleted() async {
    final reason = await _showDealNotCompletedReasonDialog();
    if (reason == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // cancelTrade already re-fetches the full chat server-side, so
      // updatedChat.messages carries the real, persisted "Deal marked as
      // not completed: <reason>" system message — sync from it instead of
      // fabricating local text.
      final updatedChat = await _chatService.cancelTrade(
        _currentChat.id,
        reason: reason,
      );

      setState(() {
        _currentChat = updatedChat;
        _messages = List.from(updatedChat.messages);
        _isLoading = false;
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
        await _refreshChat();
      }
    }
  }

  Future<void> _archiveChat() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final archivedChat = await _chatService.archiveChat(_currentChat.id);

      setState(() {
        _currentChat = archivedChat;
        _isLoading = false;
      });

      widget.onChatUpdated(_currentChat);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat archived'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _blockUser() async {
    final otherUser = _getOtherUser();

    if (_currentChat.hasAcceptedOffer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot block user with an accepted deal. Complete the deal first.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text(
          'Are you sure you want to block ${otherUser.firstName}?\n\n'
          'You will no longer receive messages or offers from them.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
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
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5BFF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _chatService.blockUser(
        chatId: _currentChat.id,
        userIdToBlock: otherUser.id,
      );

      setState(() {
        _isLoading = false;
      });

      if (success && mounted) {
        BlockedUsersCache.instance.add(otherUser.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${otherUser.firstName} has been blocked.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Blocking is only reachable from this chat's menu, but unblocking used to
  // only exist in a separate Settings > Blocked Users screen — easy to miss,
  // which read as "unblock doesn't work". Offer it right back here too.
  Future<void> _unblockUser() async {
    final otherUser = _getOtherUser();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text('Do you want to unblock ${otherUser.firstName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _blockedUserService.unblockUser(otherUser.id);
      BlockedUsersCache.instance.remove(otherUser.id);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isBlocked = false;
      });
      unawaited(_refreshChat());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${otherUser.firstName} has been unblocked.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unblock user: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reportUser() {
    final otherUser = _getOtherUser();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report User'),
        content: Text(
          'Are you sure you want to report ${otherUser.firstName}?\n\n'
          'Our team will review this report.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('User reported. Thank you for your feedback.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  // This screen calls _scrollToBottom() from ~20 places (initial load,
  // refresh, every socket event, sending a message, ...), often within
  // milliseconds of each other — e.g. initState's call and _refreshChat's
  // call race on every single open. An animateTo() gets interrupted by the
  // next call before it finishes, so the scroll position settles wherever
  // the last interruption happened instead of the true bottom, which is
  // why the chat was opening on old messages instead of the latest one.
  // jumpTo() has no animation to interrupt, so every call is idempotent —
  // it always lands exactly on the current bottom.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  UserInfo _getOtherUser() {
    return _currentChat.getOtherUserInfo(widget.currentUserId);
  }

  // Who actually handed over what once a deal is complete — the offerer is
  // whoever made the accepted offer; the receiver is the other party (the
  // post owner), who hands back the post's product/service in exchange.
  // Real first names on both sides (not "You"/"Them") so the completed-deal
  // summary reads the same for both participants.
  String? get _dealOffererName {
    final offer = _currentChat.latestAcceptedOffer;
    if (offer == null) return null;
    return offer.madeById == _currentChat.initiatorId
        ? _currentChat.initiator.firstName
        : _currentChat.responder.firstName;
  }

  String? get _dealReceiverName {
    final offer = _currentChat.latestAcceptedOffer;
    if (offer == null) return null;
    return offer.madeById == _currentChat.initiatorId
        ? _currentChat.responder.firstName
        : _currentChat.initiator.firstName;
  }

  String? get _dealOfferedItemLabel {
    final offer = _currentChat.latestAcceptedOffer;
    if (offer == null) return null;
    if (offer.isBarterOffer || offer.isBothOffer) {
      return offer.barterItemTitle;
    }
    if (offer.isPriceOffer && offer.price != null) {
      return CoinFormat.withUnit(offer.price);
    }
    return null;
  }

  bool _isMessageFromCurrentUser(ChatMessage message) {
    return message.sentById == widget.currentUserId;
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(dateTime);
    } else {
      return DateFormat('h:mm a').format(dateTime);
    }
  }

  String _formatServiceProposalText(String rawText) {
    final lines = rawText.split('\n');
    bool changed = false;

    final normalizedLines = lines.map((line) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('Date/Time:')) {
        return line;
      }

      final rawDate = trimmed.replaceFirst('Date/Time:', '').trim();
      final parsed = DateTime.tryParse(rawDate);
      if (parsed == null) {
        return line;
      }

      changed = true;
      final displayDate = DateFormat(
        'dd MMM yyyy, h:mm a',
      ).format(parsed.toLocal());
      return 'Date/Time: $displayDate';
    }).toList();

    return changed ? normalizedLines.join('\n') : rawText;
  }

  bool _hasRecentSystemMessage(
    String messageText, {
    Duration within = const Duration(seconds: 10),
  }) {
    final now = DateTime.now();

    for (var i = _messages.length - 1; i >= 0; i--) {
      final msg = _messages[i];
      if (msg.messageType != MessageType.SYSTEM) continue;
      if (msg.messageText != messageText) continue;

      final deltaMs = now.difference(msg.createdAt).inMilliseconds;
      final absDeltaMs = deltaMs < 0 ? -deltaMs : deltaMs;
      if (absDeltaMs <= within.inMilliseconds) {
        return true;
      }

      if (deltaMs > within.inMilliseconds * 3) {
        break;
      }
    }

    return false;
  }

  void _appendSystemMessageIfNotDuplicate(String messageText) {
    if (_hasRecentSystemMessage(messageText)) return;

    _messages.add(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: messageText,
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Messages should render oldest-first regardless of the order they
  /// landed in [_messages]. Offer-related system messages are fabricated
  /// locally the moment each client processes an offer event (create,
  /// counter, accept, reject, withdraw) rather than being persisted and
  /// fetched in order, so a socket event that arrives late (reconnect,
  /// brief lag, screen just opened) lands at the end of the list even
  /// though it happened earlier. Sorting by createdAt at render time fixes
  /// the display regardless of arrival order.
  List<ChatMessage> get _sortedMessages =>
      List<ChatMessage>.from(_messages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  // Deterministic icon/color per structured eventType (Point 6) — the
  // authoritative source when present. DEAL_COMPLETED/DEAL_NOT_COMPLETED are
  // the two terminal states the spec calls out by color (green/red) and get
  // a bolder card treatment below.
  ({IconData icon, Color color})? _eventTypeStyle(String? eventType) {
    switch (eventType) {
      case 'OFFER_PENDING':
        return (icon: Icons.local_offer_outlined, color: Colors.blue.shade600);
      case 'OFFER_ACCEPTED':
        return (icon: Icons.check_circle_outline, color: Colors.green.shade600);
      case 'OFFER_REJECTED':
        return (icon: Icons.cancel_outlined, color: Colors.red.shade600);
      case 'EXCHANGE_MODE_SELECTED':
        return (icon: Icons.handshake_outlined, color: Colors.indigo.shade400);
      case 'ESCROW_SECURED':
        return (icon: Icons.shield_outlined, color: Colors.blue.shade600);
      case 'DEAL_COMPLETED_PENDING_OTHER':
        return (icon: Icons.hourglass_top, color: Colors.orange.shade700);
      case 'DEAL_COMPLETED':
        return (icon: Icons.check_circle, color: Colors.green.shade600);
      case 'DEAL_NOT_COMPLETED':
        return (icon: Icons.cancel_outlined, color: Colors.red.shade600);
      case 'CHAT_STARTED':
        return (
          icon: Icons.chat_bubble_outline,
          color: Colors.blueGrey.shade400,
        );
      case 'ITEM_UNAVAILABLE':
        return (icon: Icons.info_outline, color: Colors.orange.shade700);
      default:
        return null;
    }
  }

  // Fallback for older SYSTEM messages that predate eventType — matched
  // from the persisted text itself. Ordered most-specific first so
  // overlapping keywords (e.g. "completed" appearing in both a full
  // completion and a "waiting on the other side" message) resolve right.
  ({IconData icon, Color color}) _systemMessageStyle(String text) {
    final t = text.toLowerCase();

    if (t.contains('not completed') ||
        t.contains('rejected') ||
        t.contains('withdrawn') ||
        t.contains('cancelled')) {
      return (icon: Icons.cancel_outlined, color: Colors.red.shade600);
    }
    if (t.contains('marked the deal as completed') || t.contains('waiting')) {
      return (icon: Icons.hourglass_top, color: Colors.orange.shade700);
    }
    if (t.contains('deal completed') ||
        t.contains('completed by both') ||
        t.contains('verified with deal pins')) {
      return (icon: Icons.check_circle, color: Colors.green.shade600);
    }
    if (t.contains('accepted')) {
      return (icon: Icons.check_circle_outline, color: Colors.green.shade600);
    }
    if (t.contains('coins') && (t.contains('secured') || t.contains('safe'))) {
      return (icon: Icons.shield_outlined, color: Colors.blue.shade600);
    }
    if (t.contains('zero-coin')) {
      return (icon: Icons.check_box_outlined, color: Colors.teal.shade600);
    }
    if (t.contains('exchange mode selected')) {
      return (icon: Icons.handshake_outlined, color: Colors.indigo.shade400);
    }
    if (t.contains('inspection') || t.contains('photo')) {
      return (icon: Icons.photo_camera_outlined, color: Colors.purple.shade400);
    }
    if (t.contains('offer sent') || t.contains('counter')) {
      return (icon: Icons.local_offer_outlined, color: Colors.blue.shade600);
    }
    if (t.contains('chat started')) {
      return (icon: Icons.chat_bubble_outline, color: Colors.blueGrey.shade400);
    }

    return (icon: Icons.info_outline, color: Colors.grey.shade500);
  }

  // The persisted "Offer sent: $X" system-message text is written once,
  // server-side, from the offer-maker's point of view — but it's shown to
  // BOTH participants verbatim, so the recipient wrongly sees "sent"
  // instead of "received". Rebuild the label client-side from the
  // structured eventData (madeById, price, offerType, isCounter) so each
  // viewer sees "You offered X coins to {name}" vs "{name} offered you X
  // coins". Returns the headline plus an optional note separately (rather
  // than one concatenated string) so the caller can render "Note: " in its
  // own bold style — matching _buildOfferNote's treatment on the offer
  // banner — instead of it blending into the plain system-message text.
  ({String headline, String? note}) _systemMessageParts(ChatMessage message) {
    final data = message.eventData;
    if (message.eventType != 'OFFER_PENDING' || data == null) {
      return (headline: message.messageText, note: null);
    }
    if (data['isZeroCoin'] == true) {
      return (headline: message.messageText, note: null);
    }

    final madeById = data['madeById'] as String?;
    final isMine = madeById == widget.currentUserId;
    final isCounter = data['isCounter'] == true;
    final otherName = _getOtherUser().firstName;
    final actorLabel = isCounter
        ? (isMine
              ? 'You countered with'
              : '$otherName countered your offer with')
        : (isMine ? 'You offered' : '$otherName offered you');
    // Only the actor's own copy needs the explicit "to {name}" — the
    // recipient's copy already names the actor at the start of the
    // sentence ("{name} offered you...").
    final targetSuffix = isMine ? ' to $otherName' : '';

    final offerType = (data['offerType'] as String? ?? '').toUpperCase();
    final barterTitle = (data['barterItemTitle'] as String? ?? '').trim();
    final rawPrice = data['price'];
    double? price;
    if (rawPrice != null) {
      price = rawPrice is num
          ? rawPrice.toDouble()
          : double.tryParse(rawPrice.toString());
    }
    final amount = price != null ? CoinFormat.withUnit(price) : null;

    // The listing this offer/counter is anchored to — names the product in
    // the sentence so it reads e.g. "You offered 30 coins to John for Fish
    // with Meat." even for a coins-only counter with no barter items.
    final listingData = data['listing'];
    final listingTitle = listingData is Map
        ? (listingData['title'] as String? ?? '').trim()
        : '';
    final titleSuffix = listingTitle.isNotEmpty ? ' for $listingTitle' : '';

    String headline;
    if (offerType == 'BOTH' && amount != null && barterTitle.isNotEmpty) {
      headline = '$actorLabel $barterTitle + $amount$targetSuffix$titleSuffix.';
    } else if (offerType == 'PRICE' && amount != null) {
      headline = '$actorLabel $amount$targetSuffix$titleSuffix.';
    } else if ((offerType == 'BARTER' || offerType == 'BOTH') &&
        barterTitle.isNotEmpty) {
      headline = '$actorLabel $barterTitle$targetSuffix$titleSuffix.';
    } else {
      headline = '$actorLabel$targetSuffix$titleSuffix.';
    }

    // The offerer's note now rides along with every offer type, not just
    // barter (Point 1) — surface it on the system card too.
    final description = (data['description'] as String? ?? '').trim();
    return (headline: headline, note: description.isEmpty ? null : description);
  }

  // DEAL_COMPLETED_PENDING_OTHER carries a `post` reference in eventData so
  // the item name can deep-link, same as CHAT_STARTED used to — but here
  // only the item name itself is tappable, inline within the sentence,
  // rather than the whole card. Falls back to the plain display text for
  // every other system message type, or when eventData/post is missing.
  Widget _buildSystemMessageText(
    ChatMessage message, {
    required double fontSize,
    required FontWeight fontWeight,
  }) {
    final baseStyle = TextStyle(
      fontSize: fontSize,
      color: const Color(0xFF374151),
      fontWeight: fontWeight,
      height: 1.3,
    );

    if (message.eventType == 'DEAL_COMPLETED_PENDING_OTHER') {
      final data = message.eventData;
      final rawPost = data?['post'];
      final post = rawPost is Map ? Map<String, dynamic>.from(rawPost) : null;
      final itemName = (data?['itemName'] as String?)?.trim();
      final actorName = (data?['actorName'] as String?)?.trim();

      if (post != null &&
          itemName != null &&
          itemName.isNotEmpty &&
          actorName != null &&
          actorName.isNotEmpty) {
        return Text.rich(
          TextSpan(
            style: baseStyle,
            children: [
              TextSpan(text: '$actorName has completed the Deal for \''),
              TextSpan(
                text: itemName,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _openEventPost(post),
              ),
              const TextSpan(text: '\'. Request for your deal completion.'),
            ],
          ),
          textAlign: TextAlign.center,
        );
      }
    }

    final parts = _systemMessageParts(message);
    final note = parts.note;
    if (note == null) {
      return Text(
        parts.headline,
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: '${parts.headline}\n'),
          TextSpan(
            text: 'Note: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: note),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentUser = _isMessageFromCurrentUser(message);
    final isSystemMessage = message.messageType == MessageType.SYSTEM;
    final isImageMessage = message.messageType == MessageType.IMAGE;
    final isOfferMessage = message.messageType == MessageType.OFFER;
    final otherUser = _getOtherUser();

    // Feature 2: the backend writes each deal-lifecycle event (offer made,
    // accepted, exchange mode chosen, deal completed/not completed, ...) as
    // its own SYSTEM message — this is the authoritative, complete history.
    // Render it as a centered timeline entry, distinct from left/right chat
    // bubbles, not another bubble.
    if (isSystemMessage) {
      // Redundant with the tappable post header card already pinned above
      // the message list — drop it from the timeline instead of showing
      // the same "what this chat is about" info twice.
      final isChatStarted =
          message.eventType == 'CHAT_STARTED' ||
          message.messageText.toLowerCase().contains('chat started');
      if (isChatStarted) return const SizedBox.shrink();

      final style =
          _eventTypeStyle(message.eventType) ??
          _systemMessageStyle(message.messageText);
      // The two terminal deal outcomes get a bolder card (spec calls them
      // out explicitly by color) so they stand out from the rest of the
      // step-by-step timeline.
      final isTerminalEvent =
          message.eventType == 'DEAL_COMPLETED' ||
          message.eventType == 'DEAL_NOT_COMPLETED';
      // CHAT_STARTED deep-links to the post detail screen (Point 7) — same
      // target as the header card above, using the chat's own product/
      // service id rather than re-deriving it from eventData.
      final isTappable =
          message.eventType == 'CHAT_STARTED' &&
          (_currentChat.productId != null || _currentChat.serviceId != null);

      // Offer/counter-offer and acceptance cards carry the listing's image
      // in eventData now — show a small thumbnail so the product stays
      // visible on every round of the negotiation timeline, not just the
      // live banner above.
      String? listingThumb;
      if (message.eventType == 'OFFER_PENDING' ||
          message.eventType == 'OFFER_ACCEPTED') {
        final listingData = message.eventData?['listing'];
        if (listingData is Map) {
          final image = listingData['image'] as String?;
          if (image != null && image.trim().isNotEmpty) {
            listingThumb = image;
          }
        }
      }

      final card = Container(
        padding: EdgeInsets.symmetric(
          horizontal: isTerminalEvent ? 14 : 12,
          vertical: isTerminalEvent ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: isTerminalEvent ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: style.color.withValues(alpha: isTerminalEvent ? 0.35 : 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (listingThumb != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  listingThumb,
                  width: 20,
                  height: 20,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox(width: 20, height: 20),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Icon(
              style.icon,
              size: isTerminalEvent ? 17 : 14,
              color: style.color,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: _buildSystemMessageText(
                message,
                fontSize: isTerminalEvent ? 12.5 : 12,
                fontWeight: isTerminalEvent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (isTappable) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 14, color: style.color),
            ],
          ],
        ),
      );

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
        child: Column(
          children: [
            isTappable
                ? InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _isOpeningPostDetail ? null : _openPostDetail,
                    child: card,
                  )
                : card,
            const SizedBox(height: 3),
            Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser)
            CircleAvatar(
              radius: 16,
              backgroundImage: otherUser.profileImage != null
                  ? NetworkImage(otherUser.profileImage!)
                  : null,
              child: otherUser.profileImage == null
                  ? Text(otherUser.firstName[0].toUpperCase())
                  : null,
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Colors.blue.shade100
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isOfferMessage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.request_page,
                            size: 14,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offer',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          if (message.offerId != null) ...[
                            const SizedBox(width: 8),
                            Builder(
                              builder: (context) {
                                final offerId = message.offerId;
                                if (offerId == null || offerId.isEmpty) {
                                  return const SizedBox();
                                }
                                final matched = _currentChat.offers
                                    .where((o) => o.id == offerId)
                                    .toList();
                                final offer = matched.isNotEmpty
                                    ? matched.first
                                    : null;
                                if (offer == null || !offer.isRejected) {
                                  return const SizedBox();
                                }
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.red.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  child: const Text(
                                    'REJECTED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.red,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),

                  if (isImageMessage && message.imageUrl != null)
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: InteractiveViewer(
                              child: Image.network(
                                message.imageUrl!,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          message.imageUrl!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image),
                            );
                          },
                        ),
                      ),
                    )
                  else
                    Text(
                      _formatServiceProposalText(message.messageText),
                      style: const TextStyle(fontSize: 14),
                    ),

                  const SizedBox(height: 4),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatMessageTime(message.createdAt),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.done,
                          size: 12,
                          color: message.isRead ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildServiceProposalBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.35)),
      ),
      child: const Text(
        'Service Proposal',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.deepPurple,
        ),
      ),
    );
  }

  DateTime? _proposalSlotDateTime(
    DateTime selectedDate,
    Map<String, dynamic> slot,
  ) {
    final direct = [
      slot['startDateTime'],
      slot['appointmentDate'],
      slot['dateTime'],
      slot['slotDateTime'],
    ];

    for (final raw in direct) {
      if (raw == null) continue;
      final dt = DateTime.tryParse(raw.toString());
      if (dt != null) return dt;
    }

    final time = slot['startTime']?.toString() ?? slot['time']?.toString();
    return _serviceBookingService.parseTimeOfDay(selectedDate, time);
  }

  bool _proposalSlotAvailable(Map<String, dynamic> slot) {
    final available = slot['available'];
    if (available is bool) return available;
    return slot['isAvailable'] != false;
  }

  String _proposalSlotLabel(DateTime selectedDate, Map<String, dynamic> slot) {
    final dt = _proposalSlotDateTime(selectedDate, slot);
    final end = slot['endTime']?.toString();
    if (dt != null) {
      final startText = DateFormat('h:mm a').format(dt);
      if (end != null && end.isNotEmpty) {
        return '$startText - $end';
      }
      return startText;
    }

    return slot['startTime']?.toString() ?? slot['time']?.toString() ?? 'Slot';
  }

  String? _proposalSlotKey(DateTime selectedDate, Map<String, dynamic> slot) {
    final dt = _proposalSlotDateTime(selectedDate, slot);
    if (dt != null) {
      return dt.toIso8601String();
    }
    final raw = slot['startTime']?.toString() ?? slot['time']?.toString();
    if (raw == null || raw.isEmpty) return null;
    return '${_serviceBookingService.dateOnly(selectedDate)} $raw';
  }

  DateTime? _parseProposalTime(DateTime date, String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();

    // Common backend formats first.
    final normalized = value.length >= 5 ? value.substring(0, 5) : value;
    final hhmm = _serviceBookingService.parseTimeOfDay(date, normalized);
    if (hhmm != null) return hhmm;

    for (final pattern in ['h:mm a', 'hh:mm a']) {
      try {
        final parsed = DateFormat(pattern).parseStrict(value.toUpperCase());
        return DateTime(
          date.year,
          date.month,
          date.day,
          parsed.hour,
          parsed.minute,
        );
      } catch (_) {
        // Try next pattern.
      }
    }

    return null;
  }

  bool _matchesWeekDay(DateTime date, dynamic dayValue) {
    if (dayValue == null) return false;

    if (dayValue is num) {
      return date.weekday == dayValue.toInt();
    }

    final dayText = dayValue.toString().trim().toUpperCase();
    if (dayText.isEmpty) return false;

    final selected = DateFormat('EEEE').format(date).toUpperCase();
    if (dayText == selected) return true;

    final aliases = {
      'MON': 'MONDAY',
      'TUE': 'TUESDAY',
      'WED': 'WEDNESDAY',
      'THU': 'THURSDAY',
      'FRI': 'FRIDAY',
      'SAT': 'SATURDAY',
      'SUN': 'SUNDAY',
    };

    return aliases[dayText] == selected;
  }

  List<Map<String, dynamic>> _buildSlotsFromWeeklyAvailability(
    DateTime date,
    List<Map<String, dynamic>> weekly,
    int fallbackDuration,
  ) {
    final slots = <Map<String, dynamic>>[];

    for (final row in weekly) {
      if (row['isAvailable'] == false || row['available'] == false) {
        continue;
      }
      if (!_matchesWeekDay(date, row['dayOfWeek'])) {
        continue;
      }

      final start = _parseProposalTime(date, row['startTime']?.toString());
      final end = _parseProposalTime(date, row['endTime']?.toString());
      if (start == null || end == null || !end.isAfter(start)) {
        continue;
      }

      final rawDuration = row['slotDurationMinutes'];
      final slotDuration = rawDuration is int
          ? rawDuration
          : int.tryParse(rawDuration?.toString() ?? '') ?? fallbackDuration;
      if (slotDuration <= 0) continue;

      var pointer = start;
      while (pointer
              .add(Duration(minutes: slotDuration))
              .isAtSameMomentAs(end) ||
          pointer.add(Duration(minutes: slotDuration)).isBefore(end)) {
        final slotEnd = pointer.add(Duration(minutes: slotDuration));
        slots.add({
          'startTime': DateFormat('HH:mm').format(pointer),
          'endTime': DateFormat('HH:mm').format(slotEnd),
          'available': true,
          'slotDurationMinutes': slotDuration,
          'startDateTime': pointer.toIso8601String(),
        });
        pointer = slotEnd;
      }
    }

    return slots;
  }

  Future<void> _openServiceProposalEditor(TradeOffer sourceOffer) async {
    final serviceId = _currentChat.serviceId;
    if (serviceId == null || serviceId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to edit slot: service details are missing.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    DateTime selectedDate = DateTime.now();
    List<Map<String, dynamic>> slots = [];
    Map<String, dynamic>? selectedSlot;
    String? slotsUnavailableReason;
    bool loadingSlots = false;
    bool sendingProposal = false;
    bool initialized = false;
    String location = '';
    int duration = 30;
    String notes = '';
    List<Map<String, dynamic>> weeklyAvailability = [];

    try {
      final detail = await _serviceBookingService.getServiceDetail(serviceId);
      final data = detail['data'];
      if (data is Map<String, dynamic>) {
        final service = data['service'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['service'])
            : data;
        location = service['location']?.toString() ?? '';
        if (service['availabilitySlots'] is List) {
          weeklyAvailability = (service['availabilitySlots'] as List)
              .whereType<Map>()
              .map((row) => Map<String, dynamic>.from(row))
              .toList();
        }
      }
    } catch (_) {
      // Keep defaults when detail fetch fails.
    }

    Future<void> loadSlotsForDate(
      DateTime date,
      void Function(void Function()) setSheetState,
    ) async {
      setSheetState(() {
        selectedDate = DateTime(date.year, date.month, date.day);
        loadingSlots = true;
        slots = const [];
        selectedSlot = null;
        slotsUnavailableReason = null;
      });

      try {
        final response = await _serviceBookingService.getAvailableSlots(
          serviceId: serviceId,
          date: _serviceBookingService.dateOnly(selectedDate),
        );

        List<Map<String, dynamic>> loadedSlots = [];
        String? unavailableReason;

        final data = response['data'];
        if (data is List) {
          if (data.isNotEmpty && data.first is String) {
            loadedSlots = data
                .whereType<String>()
                .map(
                  (t) => <String, dynamic>{
                    'startTime': t,
                    'available': true,
                    'slotDurationMinutes': duration,
                  },
                )
                .toList();
          } else {
            loadedSlots = data
                .whereType<Map>()
                .map((slot) => Map<String, dynamic>.from(slot))
                .toList();
          }
        } else if (data is Map<String, dynamic>) {
          final source =
              data['slots'] ?? data['availableSlots'] ?? data['data'];
          if (source is List) {
            if (source.isNotEmpty && source.first is String) {
              loadedSlots = source
                  .whereType<String>()
                  .map(
                    (t) => <String, dynamic>{
                      'startTime': t,
                      'available': true,
                      'slotDurationMinutes': duration,
                    },
                  )
                  .toList();
            } else {
              loadedSlots = source
                  .whereType<Map>()
                  .map((slot) => Map<String, dynamic>.from(slot))
                  .toList();
            }
          }
          unavailableReason = data['message']?.toString();

          if (loadedSlots.isEmpty && data['availabilitySlots'] is List) {
            final fromResponseWeekly = (data['availabilitySlots'] as List)
                .whereType<Map>()
                .map((row) => Map<String, dynamic>.from(row))
                .toList();
            loadedSlots = _buildSlotsFromWeeklyAvailability(
              selectedDate,
              fromResponseWeekly,
              duration,
            );
          }
        }

        if (loadedSlots.isEmpty && weeklyAvailability.isNotEmpty) {
          loadedSlots = _buildSlotsFromWeeklyAvailability(
            selectedDate,
            weeklyAvailability,
            duration,
          );
        }

        final now = DateTime.now();
        loadedSlots = loadedSlots.where((slot) {
          if (!_proposalSlotAvailable(slot)) return false;
          final start = _proposalSlotDateTime(selectedDate, slot);
          if (start == null) return false;
          return start.isAfter(now);
        }).toList();

        setSheetState(() {
          slots = loadedSlots;
          slotsUnavailableReason = unavailableReason;
          loadingSlots = false;
        });
      } catch (e) {
        setSheetState(() {
          loadingSlots = false;
          slots = const [];
          slotsUnavailableReason = _serviceBookingService.extractMessage(e);
        });
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            if (!initialized) {
              initialized = true;
              Future.microtask(
                () => loadSlotsForDate(selectedDate, setSheetState),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Slot & Send Return Proposal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: loadingSlots
                                ? null
                                : () async {
                                    final picked = await showDatePicker(
                                      context: sheetContext,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(
                                        const Duration(days: 60),
                                      ),
                                    );
                                    if (picked != null) {
                                      await loadSlotsForDate(
                                        picked,
                                        setSheetState,
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              DateFormat('EEE, MMM d').format(selectedDate),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Available Slots',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (loadingSlots)
                      const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (slots.isEmpty)
                      Text(
                        slotsUnavailableReason ??
                            'No slots available for this date',
                        style: const TextStyle(color: Colors.black54),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: slots.map((slot) {
                          final selected =
                              selectedSlot != null &&
                              _proposalSlotKey(selectedDate, selectedSlot!) ==
                                  _proposalSlotKey(selectedDate, slot);
                          return ChoiceChip(
                            label: Text(_proposalSlotLabel(selectedDate, slot)),
                            selected: selected,
                            onSelected: (_) {
                              setSheetState(() {
                                selectedSlot = slot;
                                final rawDuration = slot['slotDurationMinutes'];
                                duration = rawDuration is int
                                    ? rawDuration
                                    : int.tryParse(
                                            rawDuration?.toString() ?? '',
                                          ) ??
                                          duration;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) => notes = value,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (sendingProposal || selectedSlot == null)
                            ? null
                            : () async {
                                final chosenSlot = selectedSlot;
                                if (chosenSlot == null) return;

                                final slotDateTime = _proposalSlotDateTime(
                                  selectedDate,
                                  chosenSlot,
                                );
                                if (slotDateTime == null) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Unable to resolve selected slot date/time',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => sendingProposal = true);
                                try {
                                  final displayDate = DateFormat(
                                    'dd MMM yyyy, h:mm a',
                                  ).format(slotDateTime.toLocal());

                                  final lines = <String>[
                                    'Return service proposal',
                                    'Date/Time: $displayDate',
                                    'Duration: $duration minutes',
                                  ];

                                  final trimmedLocation = location.trim();
                                  if (trimmedLocation.isNotEmpty) {
                                    lines.add('Location: $trimmedLocation');
                                  }

                                  final trimmedNotes = notes.trim();
                                  if (trimmedNotes.isNotEmpty) {
                                    lines.add('Notes: $trimmedNotes');
                                  }

                                  final isSourcePrice =
                                      sourceOffer.isPriceOffer;
                                  final counterOffer =
                                      await _createCounterOffer(
                                        originalOffer: sourceOffer,
                                        offerType: isSourcePrice
                                            ? 'PRICE'
                                            : 'BARTER',
                                        price: isSourcePrice
                                            ? sourceOffer.price
                                            : null,
                                        barterItemTitle: isSourcePrice
                                            ? null
                                            : (sourceOffer.barterItemTitle ??
                                                  'Service Proposal'),
                                        barterItemDescription: isSourcePrice
                                            ? null
                                            : sourceOffer.barterItemDescription,
                                      );

                                  if (counterOffer == null) {
                                    return;
                                  }

                                  final proposalMessage = await _chatService
                                      .sendMessage(
                                        chatId: _currentChat.id,
                                        messageText: lines.join('\n'),
                                      );
                                  _socketService.emitMessageCreated(
                                    _currentChat.id,
                                    proposalMessage.id,
                                  );

                                  if (!sheetContext.mounted) return;
                                  Navigator.pop(sheetContext);
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to send return proposal: ${e.toString()}',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } finally {
                                  if (sheetContext.mounted) {
                                    setSheetState(
                                      () => sendingProposal = false,
                                    );
                                  }
                                }
                              },
                        icon: sendingProposal
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(
                          sendingProposal
                              ? 'Sending...'
                              : 'Send Return Proposal',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    await _refreshChat();
  }

  Widget _buildOfferItemThumb(String imageUrl) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const Icon(Icons.image_not_supported, color: Colors.grey),
            )
          : const Icon(Icons.image, color: Colors.grey),
    );
  }

  // barterItemDescription is the offerer's own free-text note — the item
  // name/image/price are already shown separately above, so this needs a
  // clear "Note:" label or it reads as an unexplained fragment of text.
  Widget _buildOfferNote(String description) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          children: [
            TextSpan(
              text: 'Note: ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            TextSpan(text: description),
          ],
        ),
      ),
    );
  }

  Widget _buildBarterExchangePreview({
    required String myImage,
    required String myLabel,
    String? myName,
    String? myPriceLabel,
    VoidCallback? onMyTap,
    // The actually-offered products for this side, when known — renders one
    // thumbnail per product instead of a single image so a multi-item offer
    // doesn't collapse down to just its first item. Falls back to the
    // single myImage/myName/myPriceLabel when null/empty (free-text-only
    // offers, or a side that's always a single listing).
    List<BarterProductInfo>? myItems,
    required String theirImage,
    required String theirLabel,
    String? theirName,
    String? theirPriceLabel,
    VoidCallback? onTheirTap,
    List<BarterProductInfo>? theirItems,
  }) {
    Widget side({
      required String image,
      required String label,
      String? name,
      String? priceLabel,
      VoidCallback? onTap,
    }) {
      final column = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          _buildOfferItemThumb(image),
          if (name != null && name.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (priceLabel != null && priceLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              priceLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ],
      );

      if (onTap == null) return column;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: column,
      );
    }

    Widget multiSide({
      required List<BarterProductInfo> items,
      required String label,
      String? priceLabel,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 64,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final item = items[index];
                final thumb = _buildOfferItemThumb(item.firstImage);
                if (item.id.isEmpty || _isOpeningPostDetail) return thumb;
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _openBarterItemDetail(item.id),
                  child: thumb,
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            items.length == 1
                ? items.first.title
                : items.map((p) => p.title).join(', '),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (priceLabel != null && priceLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              priceLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: myItems != null && myItems.isNotEmpty
              ? multiSide(
                  items: myItems,
                  label: myLabel,
                  priceLabel: myPriceLabel,
                )
              : side(
                  image: myImage,
                  label: myLabel,
                  name: myName,
                  priceLabel: myPriceLabel,
                  onTap: onMyTap,
                ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.swap_horiz, color: Colors.grey),
        ),
        Expanded(
          child: theirItems != null && theirItems.isNotEmpty
              ? multiSide(
                  items: theirItems,
                  label: theirLabel,
                  priceLabel: theirPriceLabel,
                )
              : side(
                  image: theirImage,
                  label: theirLabel,
                  name: theirName,
                  priceLabel: theirPriceLabel,
                  onTap: onTheirTap,
                ),
        ),
      ],
    );
  }

  /// The offer these two banners would each show, used only to order the
  /// banners themselves — mirrors the "latest" selection each builder does
  /// internally so the two stay consistent with what's actually displayed.
  TradeOffer? get _latestIncomingOfferForBanner {
    final visibleOffers = _currentChat.offers
        .where((offer) => !offer.isWithdrawn)
        .toList();
    if (visibleOffers.isEmpty) return null;
    visibleOffers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latest = visibleOffers.last;
    return latest.madeById != widget.currentUserId ? latest : null;
  }

  TradeOffer? get _latestMyOfferForBanner {
    final myOffers = _currentChat.offers
        .where(
          (offer) =>
              offer.madeById == widget.currentUserId && !offer.isWithdrawn,
        )
        .toList();
    if (myOffers.isEmpty) return null;
    myOffers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return myOffers.last;
  }

  // Tappable summary of what this chat is about (Point 7) — deep-links to
  // the post detail screen. The chat only carries a lightweight
  // product/service snapshot (id, title, images, price), which is enough
  // for this card without an extra fetch.
  Widget _buildPostHeaderCard() {
    final title = _currentChat.postTitle;
    final image = _currentChat.postImage;
    final price = _currentChat.product?.price ?? _currentChat.service?.price;
    final isService = _currentChat.serviceId != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _isOpeningPostDetail ? null : _openPostDetail,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: image.isNotEmpty
                    ? Image.network(
                        image,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.image, size: 20),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: Colors.grey.shade200,
                        child: Icon(
                          isService
                              ? Icons.build_circle
                              : Icons.inventory_2_outlined,
                          size: 20,
                          color: Colors.grey.shade500,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (price != null && price > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CoinIcon(size: 13, iconSize: 8),
                          const SizedBox(width: 3),
                          Text(
                            CoinFormat.withUnit(price),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (_isOpeningPostDetail)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Point 8: once a deal on this listing completes in a competing chat, the
  // backend closes this one out — canMakeOffer flips false and
  // listingUnavailable becomes true. Surface it plainly instead of just
  // silently hiding the offer button.
  Widget _buildListingUnavailableBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No longer available',
              style: TextStyle(fontSize: 12.5, color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }

  /// The incoming-offer and my-offer banners are otherwise independent
  /// widgets, each always rendered incoming-first — so whichever offer is
  /// actually more recent could end up on top instead of at the bottom
  /// nearest the latest activity. Order them by their offer's createdAt so
  /// the newer one is always the one closer to the message list, matching
  /// _sortedMessages' oldest-top/newest-bottom ordering below.
  List<Widget> _buildOfferBannersInOrder() {
    final incomingOffer = _latestIncomingOfferForBanner;
    final myOffer = _latestMyOfferForBanner;
    final incomingBanner = _buildOfferBanner();
    final myBanner = _buildMyOfferBanner();

    if (incomingOffer != null &&
        myOffer != null &&
        myOffer.createdAt.isBefore(incomingOffer.createdAt)) {
      return [myBanner, incomingBanner];
    }

    return [incomingBanner, myBanner];
  }

  Widget _buildOfferBanner() {
    if (_currentChat.offers.isEmpty) return const SizedBox();

    if (!_currentChat.isActive) return const SizedBox();
    if (_isReferenceUnavailable) return const SizedBox();

    final visibleOffers = _currentChat.offers
        .where((offer) => !offer.isWithdrawn)
        .toList();

    if (visibleOffers.isEmpty) return const SizedBox();

    visibleOffers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latestOffer = visibleOffers.last;
    final isIncoming = latestOffer.madeById != widget.currentUserId;
    final isServiceChat =
        (_currentChat.serviceId != null &&
            _currentChat.serviceId!.isNotEmpty) ||
        _currentChat.service != null;

    if (!isIncoming) return const SizedBox();

    final senderName = _getOtherUser().firstName;
    final statusText = latestOffer.offerStatus.value;
    final statusColor = latestOffer.isPending
        ? Colors.blue.shade700
        : latestOffer.isAccepted
        ? Colors.green.shade700
        : latestOffer.isRejected
        ? Colors.red.shade700
        : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.request_page, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$senderName's Offer to You ($statusText)",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              if (isServiceChat) _buildServiceProposalBadge(),
            ],
          ),
          const SizedBox(height: 8),

          if (latestOffer.isPriceOffer) ...[
            Row(
              children: [
                _buildOfferItemThumb(
                  latestOffer.listing?.image ?? _currentChat.postImage,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestOffer.listing?.title ?? _currentChat.postTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if ((latestOffer.listing?.price ?? _listingPrice) != null)
                        Text(
                          'Actual: ${CoinFormat.withUnit(latestOffer.listing?.price ?? _listingPrice)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      Text(
                        'Offer: ${CoinFormat.withUnit(latestOffer.price)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (latestOffer.barterItemDescription != null &&
                latestOffer.barterItemDescription!.trim().isNotEmpty)
              _buildOfferNote(latestOffer.barterItemDescription!),
          ] else if (latestOffer.isBarterOffer || latestOffer.isBothOffer) ...[
            Text(
              isServiceChat
                  ? '$senderName is interested in your service. Here are their thoughts:'
                  : '$senderName is interested in your product. Here are their thoughts:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildBarterExchangePreview(
              myImage: latestOffer.listing?.image ?? _currentChat.postImage,
              myLabel: isServiceChat ? 'Your service' : 'Your product',
              myName: latestOffer.listing?.title ?? _currentChat.postTitle,
              myPriceLabel: (latestOffer.listing?.price ?? _listingPrice) != null
                  ? CoinFormat.withUnit(latestOffer.listing?.price ?? _listingPrice)
                  : null,
              onMyTap: _isOpeningPostDetail ? null : _openPostDetail,
              theirImage: latestOffer.barterItemImages.isNotEmpty
                  ? latestOffer.barterItemImages.first
                  : '',
              theirLabel: '$senderName offers',
              theirName: latestOffer.barterItemTitle,
              theirItems: latestOffer.barterProducts,
              theirPriceLabel: latestOffer.barterProducts.isNotEmpty
                  ? CoinFormat.withUnit(latestOffer.barterProductsTotalValue)
                  : null,
              onTheirTap:
                  latestOffer.barterProducts.length == 1 &&
                      !_isOpeningPostDetail
                  ? () => _openBarterItemDetail(
                      latestOffer.barterProducts.first.id,
                    )
                  : null,
            ),
            const SizedBox(height: 10),
            Text(
              '$senderName is offering: ${_offeredItemsLabel(latestOffer)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (latestOffer.barterItemDescription != null &&
                latestOffer.barterItemDescription!.trim().isNotEmpty)
              _buildOfferNote(latestOffer.barterItemDescription!),
            if (latestOffer.isBothOffer && (latestOffer.price ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+ ${CoinFormat.withUnit(latestOffer.price)} added',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            if (latestOffer.isBothOffer &&
                latestOffer.barterProducts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Total offer value: ${CoinFormat.withUnit(latestOffer.offerTotalValue)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
          ],

          if (latestOffer.isPending &&
              !_currentChat.hasAcceptedOffer &&
              !_isBlocked) ...[
            const SizedBox(height: 12),
            if (isServiceChat)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      _isOfferActionInProgress &&
                          _processingOfferId == latestOffer.id
                      ? null
                      : () => _acceptOffer(latestOffer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child:
                      _isOfferActionInProgress &&
                          _processingOfferId == latestOffer.id
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Accept'),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isOfferActionInProgress &&
                              _processingOfferId == latestOffer.id
                          ? null
                          : () => _rejectOffer(latestOffer),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child:
                          _isOfferActionInProgress &&
                              _processingOfferId == latestOffer.id
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _isOfferActionInProgress &&
                              _processingOfferId == latestOffer.id
                          ? null
                          : () => _acceptOffer(latestOffer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child:
                          _isOfferActionInProgress &&
                              _processingOfferId == latestOffer.id
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Accept'),
                    ),
                  ),
                ],
              ),
            // Zero-coin offers and pure product-swap barter offers are a
            // simple accept/reject — there's no coin amount to negotiate,
            // so countering doesn't apply (only Barter+Coins / Price offers
            // have a number worth countering). Service chats keep "Edit
            // Slot" regardless — that's about the proposed time, not value.
            if (!latestOffer.isZeroCoin &&
                !(latestOffer.isBarterOffer && !isServiceChat)) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      _isOfferActionInProgress &&
                          _processingOfferId == latestOffer.id
                      ? null
                      : isServiceChat
                      ? () => _openServiceProposalEditor(latestOffer)
                      : () => _showCounterOfferDialog(latestOffer),
                  icon: Icon(
                    isServiceChat ? Icons.edit_calendar : Icons.swap_horiz,
                  ),
                  label: Text(isServiceChat ? 'Edit Slot' : 'Counter Offer'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildMyOfferBanner() {
    if (_currentChat.offers.isEmpty) return const SizedBox();

    if (!_currentChat.isActive) return const SizedBox();
    if (_isReferenceUnavailable) return const SizedBox();

    final myOffers = _currentChat.offers
        .where(
          (offer) =>
              offer.madeById == widget.currentUserId && !offer.isWithdrawn,
        )
        .toList();

    if (myOffers.isEmpty) return const SizedBox();

    myOffers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latestOffer = myOffers.last;
    final isServiceChat =
        (_currentChat.serviceId != null &&
            _currentChat.serviceId!.isNotEmpty) ||
        _currentChat.service != null;
    final recipientName = _getOtherUser().firstName;

    final statusText = latestOffer.offerStatus.value;
    final statusColor = latestOffer.isPending
        ? Colors.orange.shade700
        : latestOffer.isAccepted
        ? Colors.green.shade700
        : latestOffer.isRejected
        ? Colors.red.shade700
        : Colors.grey.shade700;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your Offer to $recipientName ($statusText)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    if (isServiceChat) ...[
                      const SizedBox(width: 8),
                      _buildServiceProposalBadge(),
                    ],
                  ],
                ),
              ),
              //   if (latestOffer.isPending)
              // IconButton(
              //   icon: const Icon(Icons.close, size: 20),
              //   onPressed: () => _withdrawOffer(latestOffer),
              //   tooltip: 'Withdraw Offer',
              // ),
            ],
          ),
          const SizedBox(height: 8),

          if (latestOffer.isPriceOffer) ...[
            Row(
              children: [
                _buildOfferItemThumb(
                  latestOffer.listing?.image ?? _currentChat.postImage,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestOffer.listing?.title ?? _currentChat.postTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if ((latestOffer.listing?.price ?? _listingPrice) != null)
                        Text(
                          'Actual: ${CoinFormat.withUnit(latestOffer.listing?.price ?? _listingPrice)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      Text(
                        'Offer: ${CoinFormat.withUnit(latestOffer.price)}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (latestOffer.barterItemDescription != null &&
                latestOffer.barterItemDescription!.trim().isNotEmpty)
              _buildOfferNote(latestOffer.barterItemDescription!),
          ] else if (latestOffer.isBarterOffer || latestOffer.isBothOffer) ...[
            _buildBarterExchangePreview(
              myImage: latestOffer.barterItemImages.isNotEmpty
                  ? latestOffer.barterItemImages.first
                  : '',
              myLabel: 'You offer',
              myName: latestOffer.barterItemTitle,
              myItems: latestOffer.barterProducts,
              myPriceLabel: latestOffer.barterProducts.isNotEmpty
                  ? CoinFormat.withUnit(latestOffer.barterProductsTotalValue)
                  : null,
              onMyTap:
                  latestOffer.barterProducts.length == 1 &&
                      !_isOpeningPostDetail
                  ? () => _openBarterItemDetail(
                      latestOffer.barterProducts.first.id,
                    )
                  : null,
              theirImage: latestOffer.listing?.image ?? _currentChat.postImage,
              theirLabel: isServiceChat
                  ? '$recipientName\'s service'
                  : '$recipientName\'s product',
              theirName: latestOffer.listing?.title ?? _currentChat.postTitle,
              theirPriceLabel: (latestOffer.listing?.price ?? _listingPrice) != null
                  ? CoinFormat.withUnit(latestOffer.listing?.price ?? _listingPrice)
                  : null,
              onTheirTap: _isOpeningPostDetail ? null : _openPostDetail,
            ),
            const SizedBox(height: 10),
            Text(
              'You are offering: ${_offeredItemsLabel(latestOffer)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (latestOffer.barterItemDescription != null &&
                latestOffer.barterItemDescription!.trim().isNotEmpty)
              _buildOfferNote(latestOffer.barterItemDescription!),
            if (latestOffer.isBothOffer && (latestOffer.price ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+ ${CoinFormat.withUnit(latestOffer.price)} added',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            if (latestOffer.isBothOffer &&
                latestOffer.barterProducts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  'Total offer value: ${CoinFormat.withUnit(latestOffer.offerTotalValue)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ),
          ],
        ],
      ),
    );
  }

  // Offered-item display name for the offer banners — prefers the resolved
  // barterProducts (real product titles) over the offerer's free-text
  // barterItemTitle, which is only a fallback for pre-barterProducts offers.
  String _offeredItemsLabel(TradeOffer offer) {
    if (offer.barterProducts.isNotEmpty) {
      return offer.barterProducts.map((p) => p.title).join(', ');
    }
    return offer.barterItemTitle ?? 'Unknown';
  }

  Widget _buildDealCompletionBanner() {
    if (_isReferenceUnavailable) return const SizedBox();
    if (_isBlocked) return const SizedBox();
    if (!_currentChat.canCompleteDeal(widget.currentUserId)) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Deal Ready to Complete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The offer has been accepted. Complete the deal to finalize the transaction.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _completeTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('Deal Complete'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _markDealNotCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('Deal Not Complete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    final otherUser = _getOtherUser();
    final isBlocked = BlockedUsersCache.instance.isBlocked(otherUser.id);

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
            const Text(
              'More Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            isBlocked
                ? ListTile(
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    title: const Text('Unblock User'),
                    subtitle: Text('Unblock ${otherUser.firstName}'),
                    onTap: () {
                      Navigator.pop(context);
                      _unblockUser();
                    },
                  )
                : ListTile(
                    leading: const Icon(Icons.block, color: Colors.red),
                    title: const Text('Block User'),
                    subtitle: Text('Block ${otherUser.firstName}'),
                    onTap: () {
                      Navigator.pop(context);
                      _blockUser();
                    },
                  ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: const Text('Report User'),
              subtitle: Text('Report ${otherUser.firstName}'),
              onTap: () {
                Navigator.pop(context);
                _reportUser();
              },
            ),

            const SizedBox(height: 20),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF2E5BFF), width: 1.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = _getOtherUser();

    return WillPopScope(
      onWillPop: () async {
        if (!widget.returnToTradeChatOnBack) {
          return true;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const TradeChatScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          leading: widget.returnToTradeChatOnBack
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TradeChatScreen(),
                      ),
                      (route) => false,
                    );
                  },
                )
              : null,
          title: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: otherUser.profileImage != null
                    ? NetworkImage(otherUser.profileImage!)
                    : null,
                child: otherUser.profileImage == null
                    ? Text(otherUser.firstName[0].toUpperCase())
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(otherUser.firstName),
                  Text(
                    // Presence-only: whether this deal/chat is still open is a
                    // separate concept (shown elsewhere) and must not make an
                    // actually-online user read as "Inactive" here.
                    _isOtherUserOnline ? 'Active' : 'Inactive',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMoreOptions,
            ),
          ],
        ),

        body: SafeArea(
          child: _isLoading
              ? const Center(child: LoadingWidget())
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refreshChat,
                        color: const Color(0xFF2E5BFF),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        strokeWidth: 2.2,
                        child: ListView(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          children: [
                            _buildPostHeaderCard(),
                            if (_currentChat.listingUnavailable)
                              _buildListingUnavailableBanner(),
                            ..._sortedMessages.map(_buildMessageBubble),
                            // The actionable offer card (Accept/Reject/
                            // Counter) reflects the CURRENT negotiation
                            // state, so — like deal status below — it
                            // belongs at the end of the timeline next to the
                            // composer, not pinned above the whole
                            // conversation history where it reads as if it
                            // happened before everything shown beneath it.
                            ..._buildOfferBannersInOrder(),
                            if (_currentChat.hasDealVerification)
                              DealVerificationPanel(
                                key: ValueKey(_currentChat.id),
                                chatId: _currentChat.id,
                                currentUserId: widget.currentUserId,
                                itemName: _currentChat.postTitle,
                                offererName: _dealOffererName,
                                receiverName: _dealReceiverName,
                                offeredItemLabel: _dealOfferedItemLabel,
                                otherUserName: _getOtherUser().firstName,
                                onChatShouldRefresh:
                                    _refreshChatWithFullScreenLoader,
                              )
                            else
                              _buildDealCompletionBanner(),
                          ],
                        ),
                      ),
                    ),

                    _buildBottomInputArea(),
                  ],
                ),
        ),
      ),
    );
  }

  // The chat goes INACTIVE after a reject (no offers left pending) or after
  // "Deal Not Completed" closes an accepted deal — but the backend still
  // allows a fresh offer in both cases (canMakeOffer stays true; makeOffer
  // itself reactivates an INACTIVE chat to ACTIVE the moment a new offer
  // lands). Gating the whole input bar on isActive alone hid that path
  // entirely, so surface a dedicated re-offer entry point instead of
  // nothing when that's the situation.
  Widget _buildBottomInputArea() {
    // Live block signal (isBlocked from getChatDetail, kept live via
    // chat:blocked/chat:unblocked) — disable immediately, no refresh
    // required, regardless of what the composer would otherwise show.
    if (_isBlocked) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          color: Colors.red.shade50,
          child: Row(
            children: [
              Icon(Icons.block, size: 16, color: Colors.red.shade700),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'You can no longer interact with this user.',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentChat.isActive) {
      return _buildMessageInput();
    }

    if (_canMakeNewOffer) {
      return SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: ElevatedButton.icon(
            onPressed: _isPreparingOffer ? null : _showMakeOfferDialog,
            icon: _isPreparingOffer
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : const Icon(Icons.request_page),
            label: const Text('Make Offer Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E5BFF),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentChat.myPendingOffer)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.orange.shade50,
              child: Row(
                children: [
                  Icon(
                    Icons.hourglass_top,
                    size: 14,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Waiting for ${_getOtherUser().firstName} to respond to your offer.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image, color: Colors.blue),
                  onPressed: _isSendingImage ? null : _pickAndSendImage,
                ),
                if (_canMakeNewOffer)
                  IconButton(
                    icon: _isPreparingOffer
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.request_page, color: Colors.orange),
                    onPressed: !_isPreparingOffer ? _showMakeOfferDialog : null,
                  ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (text) {
                      _sendTypingStatus(text.isNotEmpty);
                    },
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _isSendingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.blue),
                  onPressed: _isSendingImage ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DealCompletionDialog extends StatefulWidget {
  final bool isPriceOffer;
  final double? acceptedPrice;

  const _DealCompletionDialog({required this.isPriceOffer, this.acceptedPrice});

  @override
  State<_DealCompletionDialog> createState() => __DealCompletionDialogState();
}

class __DealCompletionDialogState extends State<_DealCompletionDialog> {
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final acceptedPrice = widget.acceptedPrice;
    if (acceptedPrice != null && acceptedPrice > 0) {
      _priceController.text = acceptedPrice == acceptedPrice.roundToDouble()
          ? acceptedPrice.toInt().toString()
          : acceptedPrice.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Complete Deal'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Text(
                  'Completing a deal will close further communication, and the chat becomes inactive. The item will be marked as sold, and the post will be removed from the Marketplace.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Enter any remarks about the deal',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    borderSide: BorderSide(color: Color(0xFF2E5BFF), width: 2),
                  ),
                ),
              ),
              if (widget.isPriceOffer) ...[
                const SizedBox(height: 12),
                Text(
                  'Coins will be deducted from your wallet when you complete this deal.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  readOnly: true,
                  enableInteractiveSelection: false,
                  decoration: InputDecoration(
                    labelText: 'Selling Price',
                    prefixIcon: coinInputPrefix(),
                    prefixIconConstraints: coinPrefixIconConstraints,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade400),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(
                        color: Color(0xFF2E5BFF),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2E5BFF),
            side: const BorderSide(color: Color(0xFF2E5BFF), width: 1.2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.isPriceOffer && _priceController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Accepted offer price is unavailable'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'remarks': _remarksController.text,
              'price': _priceController.text,
            });
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Complete Deal'),
        ),
      ],
    );
  }
}
