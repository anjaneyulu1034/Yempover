import 'dart:async';
import 'dart:io';
import 'package:yempover_app/services/socket_io/socket_service.dart';
import 'package:yempover_app/services/service_booking_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/models/ProductPostmain.dart';
import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:yempover_app/screens/OfferDeckScreen.dart';
import 'package:yempover_app/screens/OfferDescriptionScreen.dart';
import 'package:yempover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:yempover_app/services/api_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/utils/loading_widget.dart';
import 'package:yempover_app/widgets/coin_icon.dart';
import 'package:yempover_app/widgets/exchange_mode_sheet.dart';
import 'package:yempover_app/utils/blocked_users_cache.dart';
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
  bool _isPreparingOffer = false;
  Timer? _typingTimer;

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
  // _canShowOfferActions (which is about responding to an existing
  // incoming offer). Server-authoritative: correctly re-opens after a
  // reject/counter/cancel and correctly blocks while my own offer is still
  // PENDING, without the client having to reconstruct that logic itself.
  bool get _canMakeNewOffer =>
      _currentChat.canMakeOffer && !_isReferenceUnavailable;

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

  @override
  void initState() {
    super.initState();
    _currentChat = widget.chat;
    _messages = List.from(_currentChat.messages);
    if (_currentChat.otherUserOnline != null) {
      _isOtherUserOnline = _currentChat.otherUserOnline!;
    }
    Future.microtask(_refreshChat);
    _scrollToBottom();
    _initializeSocketListeners();
    Future.microtask(_initializeSocketAndJoin);
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
    WidgetsBinding.instance.removeObserver(this);
    _chatService.dispose();
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
      final isOnline = data['isOnline'] == true;
      final otherUser = _getOtherUser();

      if (chatId != null && chatId != _currentChat.id) return;
      if (userId != otherUser.id) return;

      setState(() {
        _isOtherUserOnline = isOnline;
      });
    } catch (e) {
      print('Error handling user presence: $e');
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

      setState(() {
        _messages.add(newMessage);
        _currentChat = TradeChat(
          id: _currentChat.id,
          initiatorId: _currentChat.initiatorId,
          responderId: _currentChat.responderId,
          productId: _currentChat.productId,
          serviceId: _currentChat.serviceId,
          status: _currentChat.status,
          lastMessageAt: DateTime.now(),
          createdAt: _currentChat.createdAt,
          updatedAt: DateTime.now(),
          initiator: _currentChat.initiator,
          responder: _currentChat.responder,
          product: _currentChat.product,
          service: _currentChat.service,
          messages: _messages,
          offers: _currentChat.offers,
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
              : TradeOffer(
                  id: _currentChat.offers[index].id,
                  tradeChatId: _currentChat.offers[index].tradeChatId,
                  madeById: _currentChat.offers[index].madeById,
                  madeBy: _currentChat.offers[index].madeBy,
                  offerType: _currentChat.offers[index].offerType,
                  offerStatus: OfferStatus.ACCEPTED,
                  price: _currentChat.offers[index].price,
                  currency: _currentChat.offers[index].currency,
                  barterItemTitle: _currentChat.offers[index].barterItemTitle,
                  barterItemDescription:
                      _currentChat.offers[index].barterItemDescription,
                  barterItemImages: _currentChat.offers[index].barterItemImages,
                  barterWishCategories:
                      _currentChat.offers[index].barterWishCategories,
                  counterOfferCount:
                      _currentChat.offers[index].counterOfferCount,
                  createdAt: _currentChat.offers[index].createdAt,
                  acceptedAt: DateTime.now(),
                  rejectedAt: _currentChat.offers[index].rejectedAt,
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
              : TradeOffer(
                  id: _currentChat.offers[index].id,
                  tradeChatId: _currentChat.offers[index].tradeChatId,
                  madeById: _currentChat.offers[index].madeById,
                  madeBy: _currentChat.offers[index].madeBy,
                  offerType: _currentChat.offers[index].offerType,
                  offerStatus: OfferStatus.REJECTED,
                  price: _currentChat.offers[index].price,
                  currency: _currentChat.offers[index].currency,
                  barterItemTitle: _currentChat.offers[index].barterItemTitle,
                  barterItemDescription:
                      _currentChat.offers[index].barterItemDescription,
                  barterItemImages: _currentChat.offers[index].barterItemImages,
                  barterWishCategories:
                      _currentChat.offers[index].barterWishCategories,
                  counterOfferCount:
                      _currentChat.offers[index].counterOfferCount,
                  createdAt: _currentChat.offers[index].createdAt,
                  acceptedAt: _currentChat.offers[index].acceptedAt,
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
          _currentChat.offers[index] = TradeOffer(
            id: offer.id,
            tradeChatId: offer.tradeChatId,
            madeById: offer.madeById,
            madeBy: offer.madeBy,
            offerType: offer.offerType,
            offerStatus: OfferStatus.WITHDRAWN,
            price: offer.price,
            currency: offer.currency,
            barterItemTitle: offer.barterItemTitle,
            barterItemDescription: offer.barterItemDescription,
            barterItemImages: offer.barterItemImages,
            barterWishCategories: offer.barterWishCategories,
            counterOfferCount: offer.counterOfferCount,
            createdAt: offer.createdAt,
            acceptedAt: offer.acceptedAt,
            rejectedAt: offer.rejectedAt,
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

  void _handleDealCancelled(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];

      if (chatId != _currentChat.id) return;

      setState(() {
        _currentChat = TradeChat(
          id: _currentChat.id,
          initiatorId: _currentChat.initiatorId,
          responderId: _currentChat.responderId,
          productId: _currentChat.productId,
          serviceId: _currentChat.serviceId,
          status: ChatStatus.CANCELLED,
          lastMessageAt: _currentChat.lastMessageAt,
          createdAt: _currentChat.createdAt,
          updatedAt: DateTime.now(),
          initiator: _currentChat.initiator,
          responder: _currentChat.responder,
          product: _currentChat.product,
          service: _currentChat.service,
          messages: _messages,
          offers: _currentChat.offers,
        );
        _appendSystemMessageIfNotDuplicate('Trade cancelled');
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
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
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateChatLastMessage() {
    _currentChat = TradeChat(
      id: _currentChat.id,
      initiatorId: _currentChat.initiatorId,
      responderId: _currentChat.responderId,
      productId: _currentChat.productId,
      serviceId: _currentChat.serviceId,
      status: _currentChat.status,
      lastMessageAt: DateTime.now(),
      createdAt: _currentChat.createdAt,
      updatedAt: DateTime.now(),
      initiator: _currentChat.initiator,
      responder: _currentChat.responder,
      product: _currentChat.product,
      service: _currentChat.service,
      messages: _messages,
      offers: _currentChat.offers,
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
      });
      _scrollToBottom();
    } catch (e) {
      print('Error refreshing chat: $e');
    }
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
      setState(() {
        _isSendingImage = false;
        _messages.removeWhere((m) => m.messageText == 'Sending image...');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: ${e.toString()}'),
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
            ? 'Waiting for the other user to respond to your offer.'
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

      Navigator.push(
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
      return;
    }

    Navigator.push(
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
      // back to the app-wide max so the field still can't take an
      // arbitrarily large number.
      if (price.toStringAsFixed(0).length > Validators.maxAmountLength) {
        return 'Price is too large';
      }
      return null;
    }

    if (price.round() > listing.round()) {
      return 'Offer cannot exceed listing price of '
          '${CoinFormat.amount(listing)} coins';
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
                    setDialogState(
                      () => dialogError = 'Enter coins',
                    );
                    return;
                  }

                  final parsed = double.tryParse(trimmed);
                  if (parsed == null) {
                    setDialogState(
                      () => dialogError = 'Enter a valid coin amount',
                    );
                    return;
                  }

                  final validationError =
                      _validateOfferPriceAgainstListing(parsed);
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
    final canAfford = await WalletOfferGuard.ensureCanAfford(
      context,
      requiredCoins: parsedPrice,
      itemName: _currentChat.postTitle,
    );
    if (!canAfford || !mounted) return;

    await _createCounterOffer(
      originalOffer: originalOffer,
      offerType: 'PRICE',
      price: parsedPrice,
    );
  }

  Future<void> _showCounterBarterOfferDialog(TradeOffer originalOffer) async {
    final titleController = TextEditingController(
      text: originalOffer.barterItemTitle ?? '',
    );
    final descriptionController = TextEditingController(
      text: originalOffer.barterItemDescription ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
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
          title: const Text('Counter Barter Offer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Item Title',
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
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Your Thoughts / Description',
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
                if (titleController.text.trim().isNotEmpty) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Send Counter'),
            ),
          ],
        );
      },
    );

    if (result != true || titleController.text.trim().isEmpty) return;

    await _createCounterOffer(
      originalOffer: originalOffer,
      offerType: 'BARTER',
      barterItemTitle: titleController.text.trim(),
      barterItemDescription: descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null,
    );
  }

  /// Counter a Barter + Price ("Both") offer. Reusing the plain barter
  /// counter dialog here would silently drop the price side of the deal
  /// (Condition 2: barter + price difference), so this keeps both the
  /// barter item fields and the coin amount editable together.
  Future<void> _showCounterBothOfferDialog(TradeOffer originalOffer) async {
    final titleController = TextEditingController(
      text: originalOffer.barterItemTitle ?? '',
    );
    final descriptionController = TextEditingController(
      text: originalOffer.barterItemDescription ?? '',
    );
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
            title: const Text('Counter Barter + Coins Offer'),
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
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Item Title',
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
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
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
                  if (titleController.text.trim().isEmpty) {
                    setDialogState(() => dialogError = 'Enter an item title');
                    return;
                  }

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

                  final validationError =
                      _validateOfferPriceAgainstListing(parsed);
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

    if (result != true || titleController.text.trim().isEmpty) return;

    final parsedPrice = double.tryParse(priceController.text.trim());
    if (parsedPrice == null) return;

    if (!mounted) return;
    final canAfford = await WalletOfferGuard.ensureCanAfford(
      context,
      requiredCoins: parsedPrice,
      itemName: _currentChat.postTitle,
    );
    if (!canAfford || !mounted) return;

    await _createCounterOffer(
      originalOffer: originalOffer,
      offerType: 'BOTH',
      price: parsedPrice,
      barterItemTitle: titleController.text.trim(),
      barterItemDescription: descriptionController.text.trim().isNotEmpty
          ? descriptionController.text.trim()
          : null,
    );
  }

  Future<TradeOffer?> _createCounterOffer({
    required TradeOffer originalOffer,
    required String offerType,
    double? price,
    String? barterItemTitle,
    String? barterItemDescription,
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
          _currentChat.offers[index] = TradeOffer(
            id: offer.id,
            tradeChatId: offer.tradeChatId,
            madeById: offer.madeById,
            madeBy: offer.madeBy,
            offerType: offer.offerType,
            offerStatus: OfferStatus.WITHDRAWN,
            price: offer.price,
            currency: offer.currency,
            barterItemTitle: offer.barterItemTitle,
            barterItemDescription: offer.barterItemDescription,
            barterItemImages: offer.barterItemImages,
            barterWishCategories: offer.barterWishCategories,
            counterOfferCount: offer.counterOfferCount,
            createdAt: offer.createdAt,
            acceptedAt: offer.acceptedAt,
            rejectedAt: offer.rejectedAt,
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

  String get _otherParticipantId => widget.currentUserId == _currentChat.initiatorId
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
      final refreshedBalance =
          CoinService.parseCoinAmount(refreshedWallet?['balance']);
      if (refreshedBalance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You need ${CoinFormat.amount(amount)} coins to complete this deal.',
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
        isPriceOffer: _dealRequiresCoinPayment() && _currentUserPaysOnDealComplete(),
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
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    setDialogState(
                      () => dialogError = 'Please enter a reason',
                    );
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
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
            ),
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
        child: Column(
          children: [
            Text(
              message.messageText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 2),
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
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
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

                                  await _chatService.sendMessage(
                                    chatId: _currentChat.id,
                                    messageText: lines.join('\n'),
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

  Widget _buildBarterExchangePreview({
    required String myImage,
    required String myLabel,
    required String theirImage,
    required String theirLabel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                myLabel,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              _buildOfferItemThumb(myImage),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.swap_horiz, color: Colors.grey),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                theirLabel,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              _buildOfferItemThumb(theirImage),
            ],
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
                  'Offer ($statusText)',
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
                _buildOfferItemThumb(_currentChat.postImage),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentChat.postTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: ${CoinFormat.amount(latestOffer.price)} coins',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (latestOffer.isBarterOffer || latestOffer.isBothOffer) ...[
            Text(
              isServiceChat
                  ? 'This user is interested in your service. Here are their thoughts:'
                  : 'This user is interested in your product. Here are their thoughts:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            _buildBarterExchangePreview(
              myImage: _currentChat.postImage,
              myLabel: isServiceChat ? 'Your service' : 'Your product',
              theirImage: latestOffer.barterItemImages.isNotEmpty
                  ? latestOffer.barterItemImages.first
                  : '',
              theirLabel: 'Offered item',
            ),
            const SizedBox(height: 10),
            Text(
              'Item: ${latestOffer.barterItemTitle ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (latestOffer.barterItemDescription != null &&
                latestOffer.barterItemDescription!.trim().isNotEmpty)
              Text(
                latestOffer.barterItemDescription!,
                style: const TextStyle(fontSize: 12),
              ),
            if (latestOffer.isBothOffer && (latestOffer.price ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+ ${CoinFormat.amount(latestOffer.price)} coins added',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
          ],

          if (latestOffer.isPending && !_currentChat.hasAcceptedOffer) ...[
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
                        'Your Offer ($statusText)',
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
                _buildOfferItemThumb(_currentChat.postImage),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentChat.postTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Price: ${CoinFormat.amount(latestOffer.price)} coins',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ] else if (latestOffer.isBarterOffer || latestOffer.isBothOffer) ...[
            _buildBarterExchangePreview(
              myImage: latestOffer.barterItemImages.isNotEmpty
                  ? latestOffer.barterItemImages.first
                  : '',
              myLabel: 'Your offered item',
              theirImage: _currentChat.postImage,
              theirLabel: isServiceChat ? 'Their service' : 'Their product',
            ),
            const SizedBox(height: 10),
            Text(
              'Item: ${latestOffer.barterItemTitle ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (latestOffer.barterItemDescription != null)
              Text(
                latestOffer.barterItemDescription!,
                style: const TextStyle(fontSize: 12),
              ),
            if (latestOffer.isBothOffer && (latestOffer.price ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '+ ${CoinFormat.amount(latestOffer.price)} coins added',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDealCompletionBanner() {
    if (_isReferenceUnavailable) return const SizedBox();
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

            ListTile(
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
                            ..._buildOfferBannersInOrder(),
                            if (_currentChat.hasDealVerification)
                              DealVerificationPanel(
                                key: ValueKey(_currentChat.id),
                                chatId: _currentChat.id,
                                currentUserId: widget.currentUserId,
                                itemName: _currentChat.postTitle,
                                onChatShouldRefresh: _refreshChat,
                              )
                            else
                              _buildDealCompletionBanner(),
                            ..._sortedMessages.map(_buildMessageBubble),
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
                  Icon(Icons.hourglass_top, size: 14, color: Colors.orange.shade800),
                  const SizedBox(width: 6),
                  Text(
                    'Waiting for the other user to respond to your offer.',
                    style: TextStyle(fontSize: 11.5, color: Colors.orange.shade900),
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
                IconButton(
                  icon: _isPreparingOffer
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.request_page, color: Colors.orange),
                  onPressed: (_canMakeNewOffer && !_isPreparingOffer)
                      ? _showMakeOfferDialog
                      : null,
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
