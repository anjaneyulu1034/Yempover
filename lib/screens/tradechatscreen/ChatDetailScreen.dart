import 'dart:async';
import 'dart:io';
import 'package:Yempover_app/services/socket_io/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:Yempover_app/models/chats/trade_chat.dart';
import 'package:Yempover_app/services/token_service.dart';
import 'package:Yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:Yempover_app/utils/loading_widget.dart';

class ChatDetailScreen extends StatefulWidget {
  final TradeChat chat;
  final String currentUserId;
  final void Function(TradeChat) onChatUpdated;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.onChatUpdated,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with WidgetsBindingObserver {
  final TradeChatService _chatService = TradeChatService();
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
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _currentChat = widget.chat;
    _messages = List.from(_currentChat.messages);
    Future.microtask(_refreshChat);
    _scrollToBottom();
    _initializeSocketListeners();
    Future.microtask(_initializeSocketAndJoin);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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

  void _handleOfferAccepted(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final offerId = data['offerId'];
      final offerData = data['offer'];

      if (chatId != _currentChat.id) return;

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

        // Add system message
        final systemMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tradeChatId: _currentChat.id,
          sentById: 'system',
          messageText: 'Offer accepted',
          messageType: MessageType.SYSTEM,
          isRead: true,
          createdAt: DateTime.now(),
          offerId: offerId,
        );

        _messages.add(systemMessage);
        _currentChat = TradeChat(
          id: _currentChat.id,
          initiatorId: _currentChat.initiatorId,
          responderId: _currentChat.responderId,
          productId: _currentChat.productId,
          serviceId: _currentChat.serviceId,
          status: _currentChat.status,
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
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer accepted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error handling offer accepted: $e');
    }
  }

  void _handleOfferRejected(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final offerId = data['offerId'];
      final offerData = data['offer'];

      if (chatId != _currentChat.id) return;

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

        // Add system message
        final systemMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tradeChatId: _currentChat.id,
          sentById: 'system',
          messageText: 'Offer rejected',
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
      print('Error handling offer rejected: $e');
    }
  }

  void _handleOfferCreated(dynamic data) {
    if (!mounted) return;

    try {
      final chatId = data['chatId'];
      final offer = data['offer'];

      if (chatId != _currentChat.id) return;

      final newOffer = TradeOffer.fromJson(offer);

      setState(() {
        _currentChat.offers.add(newOffer);

        final systemMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tradeChatId: _currentChat.id,
          sentById: 'system',
          messageText: newOffer.isPriceOffer
              ? 'Price offer created: ${newOffer.currency} ${newOffer.price!.toStringAsFixed(2)}'
              : 'Barter offer created: ${newOffer.barterItemTitle}',
          messageType: MessageType.SYSTEM,
          isRead: true,
          createdAt: DateTime.now(),
          offerId: newOffer.id,
        );

        _messages.add(systemMessage);
      });

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

      setState(() {
        _currentChat = TradeChat(
          id: _currentChat.id,
          initiatorId: _currentChat.initiatorId,
          responderId: _currentChat.responderId,
          productId: _currentChat.productId,
          serviceId: _currentChat.serviceId,
          status: ChatStatus.COMPLETED,
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
        _appendSystemMessageIfNotDuplicate('Deal completed successfully');
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deal completed successfully'),
          backgroundColor: Colors.green,
        ),
      );
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

      // Add system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Offer accepted',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        offerId: acceptedOffer.id,
      );

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _currentChat.offers[index] = acceptedOffer;
        }
        _messages.add(systemMessage);
        _currentChat = TradeChat(
          id: _currentChat.id,
          initiatorId: _currentChat.initiatorId,
          responderId: _currentChat.responderId,
          productId: _currentChat.productId,
          serviceId: _currentChat.serviceId,
          status: _currentChat.status,
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
      });

      // Refresh entire chat to get latest state
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

      // Add system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Offer rejected',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        offerId: rejectedOffer.id,
      );

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _currentChat.offers[index] = rejectedOffer;
        }
        _messages.add(systemMessage);
      });

      // Refresh entire chat to get latest state
      await _refreshChat();

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reject offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

  Future<void> _showMakeOfferDialog() async {
    if (!_currentChat.isActive || _currentChat.hasAcceptedOffer) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Offers are no longer available for this chat.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make an Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.attach_money, color: Colors.green),
              title: const Text('Price Offer'),
              subtitle: const Text('Make a cash offer'),
              onTap: () => Navigator.pop(context, {'type': 'price'}),
            ),
            ListTile(
              leading: const Icon(Icons.sync_alt, color: Colors.orange),
              title: const Text('Barter Offer'),
              subtitle: const Text('Offer an item for trade'),
              onTap: () => Navigator.pop(context, {'type': 'barter'}),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    if (result['type'] == 'price') {
      _showPriceOfferDialog();
    } else if (result['type'] == 'barter') {
      _showBarterOfferDialog();
    }
  }

  Future<void> _showPriceOfferDialog() async {
    final priceController = TextEditingController();
    final currencyController = TextEditingController(text: 'USD');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Price Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currencyController,
              decoration: const InputDecoration(
                labelText: 'Currency',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create Offer'),
          ),
        ],
      ),
    );

    if (result == true && priceController.text.isNotEmpty) {
      await _createPriceOffer(
        price: double.parse(priceController.text),
        currency: currencyController.text,
      );
    }
  }

  Future<void> _showBarterOfferDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barter Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Create Offer'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.isNotEmpty) {
      await _createBarterOffer(
        title: titleController.text,
        description: descriptionController.text.isNotEmpty
            ? descriptionController.text
            : null,
      );
    }
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

    await _showCounterBarterOfferDialog(originalOffer);
  }

  Future<void> _showCounterPriceOfferDialog(TradeOffer originalOffer) async {
    final priceController = TextEditingController(
      text: originalOffer.price?.toStringAsFixed(2) ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Counter Price Offer'),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Your Counter Price',
            prefixText: '\$ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Send Counter'),
          ),
        ],
      ),
    );

    if (result != true || priceController.text.trim().isEmpty) return;

    await _createCounterOffer(
      originalOffer: originalOffer,
      offerType: 'PRICE',
      price: double.tryParse(priceController.text.trim()),
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
      builder: (context) => AlertDialog(
        title: const Text('Counter Barter Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Item Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Your Thoughts / Description',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
      ),
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

  Future<void> _createCounterOffer({
    required TradeOffer originalOffer,
    required String offerType,
    double? price,
    String? barterItemTitle,
    String? barterItemDescription,
  }) async {
    if (!_currentChat.isActive ||
        _currentChat.hasAcceptedOffer ||
        !originalOffer.isPending ||
        originalOffer.madeById == widget.currentUserId) {
      return;
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
        _messages.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            tradeChatId: _currentChat.id,
            sentById: 'system',
            messageText: offerType == 'PRICE'
                ? 'Counter offer sent: \$${(price ?? 0).toStringAsFixed(2)}'
                : 'Counter offer sent: ${barterItemTitle ?? 'Barter item'}',
            messageType: MessageType.SYSTEM,
            isRead: true,
            createdAt: DateTime.now(),
            offerId: counterOffer.id,
          ),
        );
      });

      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send counter offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isOfferActionInProgress = false;
          _processingOfferId = null;
        });
      }
    }
  }

  Future<void> _createPriceOffer({
    required double price,
    required String currency,
  }) async {
    if (!_currentChat.isActive || _currentChat.hasAcceptedOffer) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final offer = await _chatService.createPriceOffer(
        chatId: _currentChat.id,
        price: price,
        currency: currency,
      );

      // Emit socket event
      _socketService.emitOfferCreated(_currentChat.id, offer.toJson());

      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText:
            'Price offer created: \$${price.toStringAsFixed(2)} $currency',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        offerId: offer.id,
      );

      setState(() {
        _currentChat.offers.add(offer);
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
            content: Text('Failed to create offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createBarterOffer({
    required String title,
    String? description,
  }) async {
    if (!_currentChat.isActive || _currentChat.hasAcceptedOffer) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final offer = await _chatService.createBarterOffer(
        chatId: _currentChat.id,
        barterItemTitle: title,
        barterItemDescription: description,
      );

      // Emit socket event
      _socketService.emitOfferCreated(_currentChat.id, offer.toJson());

      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Barter offer created: $title',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        offerId: offer.id,
      );

      setState(() {
        _currentChat.offers.add(offer);
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
            content: Text('Failed to create offer: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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

  Future<void> _completeTrade() async {
    if (_isShowingDealCompletionDialog) return;

    _isShowingDealCompletionDialog = true;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _DealCompletionDialog(
        isPriceOffer: _currentChat.latestAcceptedOffer?.isPriceOffer ?? false,
      ),
    );

    _isShowingDealCompletionDialog = false;

    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bool isCompleted = result['isCompleted'] == true;

      final updatedChat = isCompleted
          ? await _chatService.markDealCompleted(
              chatId: _currentChat.id,
              remarks: result['remarks'] ?? 'accepted',
            )
          : await _chatService.cancelTrade(_currentChat.id);

      // Deal completion/cancel state is authoritative from REST response.
      // Do not emit legacy socket events here because they bypass consent flow.

      setState(() {
        _currentChat = updatedChat;
        _appendSystemMessageIfNotDuplicate(
          result['isCompleted'] == true
              ? (updatedChat.isActive
                    ? 'Completion consent sent. Waiting for other user.'
                    : 'Deal completed successfully')
              : 'Deal marked as not completed',
        );
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
            content: Text('Failed to complete deal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelTrade() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Trade'),
        content: const Text('Are you sure you want to cancel this trade?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final cancelledChat = await _chatService.cancelTrade(_currentChat.id);

      setState(() {
        _currentChat = cancelledChat;
        _appendSystemMessageIfNotDuplicate('Trade cancelled');
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
            content: Text('Failed to cancel trade: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentUser = _isMessageFromCurrentUser(message);
    final isSystemMessage = message.messageType == MessageType.SYSTEM;
    final isImageMessage = message.messageType == MessageType.IMAGE;
    final isOfferMessage = message.messageType == MessageType.OFFER;
    final otherUser = _getOtherUser();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isSystemMessage
            ? MainAxisAlignment.center
            : isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUser && !isSystemMessage)
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
                color: isSystemMessage
                    ? Colors.grey.shade200
                    : isCurrentUser
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
                      message.messageText,
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
                      if (isCurrentUser && !isSystemMessage) ...[
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

  Widget _buildOfferBanner() {
    if (_currentChat.offers.isEmpty) return const SizedBox();

    if (!_currentChat.isActive) return const SizedBox();

    final visibleOffers = _currentChat.offers
        .where((offer) => !offer.isWithdrawn)
        .toList();

    if (visibleOffers.isEmpty) return const SizedBox();

    visibleOffers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latestOffer = visibleOffers.last;
    final isIncoming = latestOffer.madeById != widget.currentUserId;

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
              Text(
                'Offer ($statusText)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (latestOffer.isPriceOffer) ...[
            Text(
              'Price: ${latestOffer.currency ?? '\$'} ${latestOffer.price!.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ] else if (latestOffer.isBarterOffer || latestOffer.isBothOffer) ...[
            const Text(
              'This user is interested in your product. Here are their thoughts:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
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
          ],

          if (latestOffer.isPending && !_currentChat.hasAcceptedOffer) ...[
            const SizedBox(height: 12),
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
                    : () => _showCounterOfferDialog(latestOffer),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Counter Offer'),
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

    final myOffers = _currentChat.offers
        .where(
          (offer) =>
              offer.madeById == widget.currentUserId && !offer.isWithdrawn,
        )
        .toList();

    if (myOffers.isEmpty) return const SizedBox();

    myOffers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latestOffer = myOffers.last;

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
              Row(
                children: [
                  Icon(Icons.access_time, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Your Offer ($statusText)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
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
            Text(
              'Price: ${latestOffer.currency ?? '\$'} ${latestOffer.price!.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ] else if (latestOffer.isBarterOffer || latestOffer.isBothOffer) ...[
            Text(
              'Item: ${latestOffer.barterItemTitle ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (latestOffer.barterItemDescription != null)
              Text(
                latestOffer.barterItemDescription!,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDealCompletionBanner() {
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
          ElevatedButton(
            onPressed: _completeTrade,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 40),
            ),
            child: const Text('Complete Deal'),
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

            if (_currentChat.isActive &&
                _currentChat.canCompleteDeal(widget.currentUserId)) ...[
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Complete Deal'),
                subtitle: const Text('Mark this deal as completed'),
                onTap: () {
                  Navigator.pop(context);
                  _completeTrade();
                },
              ),
              const Divider(),
            ],

            if (_currentChat.isActive || _currentChat.isCompleted) ...[
              ListTile(
                leading: const Icon(Icons.archive, color: Colors.blue),
                title: const Text('Archive Chat'),
                subtitle: const Text('Move this chat to archive'),
                onTap: () {
                  Navigator.pop(context);
                  _archiveChat();
                },
              ),
              const Divider(),
            ],

            if (_currentChat.isActive && !_currentChat.hasAcceptedOffer) ...[
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.orange),
                title: const Text('Cancel Trade'),
                subtitle: const Text('Cancel this trade negotiation'),
                onTap: () {
                  Navigator.pop(context);
                  _cancelTrade();
                },
              ),
              const Divider(),
            ],

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

    return Scaffold(
      appBar: AppBar(
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
                  (_currentChat.isActive && _isOtherUserOnline)
                      ? 'Active'
                      : 'Inactive',
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
                      child: ListView(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        children: [
                          _buildOfferBanner(),
                          _buildMyOfferBanner(),
                          _buildDealCompletionBanner(),
                          ..._messages.map((msg) => _buildMessageBubble(msg)),
                        ],
                      ),
                    ),
                  ),

                  if (_currentChat.isActive) _buildMessageInput(),
                ],
              ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return SafeArea(
      top: false,
      child: Container(
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
              icon: const Icon(Icons.request_page, color: Colors.orange),
              onPressed: _currentChat.hasAcceptedOffer
                  ? null
                  : _showMakeOfferDialog,
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
    );
  }
}

class _DealCompletionDialog extends StatefulWidget {
  final bool isPriceOffer;

  const _DealCompletionDialog({required this.isPriceOffer});

  @override
  State<_DealCompletionDialog> createState() => __DealCompletionDialogState();
}

class __DealCompletionDialogState extends State<_DealCompletionDialog> {
  bool _isDealCompleted = true;
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

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
                  'Deal Completed: The trade has been completed. Completing a Deal will close further communication, and the chat becomes inactive. The item will be marked as sold, and the post will be deleted.\n\n'
                  'Deal Not Completed: It closes Further Communication with the user and the chat becomes inactive. Since the item is not sold, it will be available on the Marketplace.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -2,
                ),
                title: const Text('Deal Completed'),
                value: true,
                groupValue: _isDealCompleted,
                onChanged: (value) {
                  setState(() {
                    _isDealCompleted = value ?? true;
                  });
                },
              ),
              RadioListTile<bool>(
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(
                  horizontal: -4,
                  vertical: -2,
                ),
                title: const Text('Deal Not Completed'),
                value: false,
                groupValue: _isDealCompleted,
                onChanged: (value) {
                  setState(() {
                    _isDealCompleted = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Enter any remarks about the deal',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_isDealCompleted && widget.isPriceOffer) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Selling Price (Required)',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_isDealCompleted &&
                widget.isPriceOffer &&
                _priceController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter the selling price'),
                  backgroundColor: Colors.orange,
                ),
              );
              return;
            }

            Navigator.pop(context, {
              'isCompleted': _isDealCompleted,
              'remarks': _remarksController.text,
              'price': _priceController.text,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDealCompleted ? Colors.green : Colors.orange,
          ),
          child: Text(
            _isDealCompleted ? 'Complete Deal' : 'Mark Not Completed',
          ),
        ),
      ],
    );
  }
}
