import 'package:yempover_app/screens/Home_screen.dart';
import 'package:yempover_app/services/socket_io/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/utils/error_widget.dart';
import 'package:yempover_app/utils/loading_widget.dart';

class TradeChatScreen extends StatefulWidget {
  const TradeChatScreen({super.key});

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final TradeChatService _chatService = TradeChatService();
  final TokenService _tokenService = TokenService();
  final SocketService _socketService = SocketService();

  List<TradeChat> _allChats = [];
  List<TradeChat> _inboxChats = [];
  List<TradeChat> _outboxChats = [];
  List<String> _userProducts = [];
  final Map<String, String> _lastMessagePreviewCache = {};
  final Set<String> _previewFetchInProgress = {};

  bool _isLoading = true;
  String? _errorMessage;

  // Pagination variables
  int _allChatsCurrentPage = 1;
  int _allChatsTotalPages = 1;
  bool _isLoadingMoreAllChats = false;
  int _inboxCurrentPage = 1;
  int _inboxTotalPages = 1;
  bool _isLoadingMoreInbox = false;
  int _outboxCurrentPage = 1;
  int _outboxTotalPages = 1;
  bool _isLoadingMoreOutbox = false;

  String? _currentUserId;
  String? _selectedProductFilter;

  @override
  void initState() {
    super.initState();
    debugPrint('🏁 TradeChatScreen: initState called');

    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    WidgetsBinding.instance.addObserver(this);
    _loadCurrentUser();
    _initializeSocketListeners();
  }

  @override
  void dispose() {
    debugPrint('🗑️ TradeChatScreen: dispose called');
    _socketService.off('new_message', _handleNewMessage);
    _socketService.off('chat_updated', _handleChatUpdated);
    _socketService.off('offer_accepted', _handleOfferUpdated);
    _socketService.off('offer_rejected', _handleOfferUpdated);
    _socketService.off('offer_created', _handleOfferCreated);
    _socketService.off('deal_completed', _handleChatStatusChanged);
    _socketService.off('deal_cancelled', _handleChatStatusChanged);

    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _chatService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshChats();
    }
  }

  /// 🔙 Navigation method to go back to HomeScreen
  void _navigateToHomeScreen() {
    debugPrint('🏠 TradeChatScreen: Navigating to HomeScreen');

    // Use a post-frame callback to avoid navigator lock issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      try {
        // First try to pop until we find HomeScreen
        bool foundHomeScreen = false;

        Navigator.popUntil(context, (route) {
          if (route.settings.name == '/home' ||
              route.settings.name == 'HomeScreen' ||
              route.settings.name == '/') {
            foundHomeScreen = true;
            return true; // Stop at HomeScreen
          }
          return false; // Continue popping
        });

        // If we didn't find HomeScreen in the stack, just pop
        if (!foundHomeScreen && mounted) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            // If can't pop, push HomeScreen and remove all previous
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
              (route) => false,
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Navigation error: $e');
        // Fallback: just pop if possible
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
    });
  }

  void _initializeSocketListeners() {
    _socketService.on('new_message', _handleNewMessage);
    _socketService.on('chat_updated', _handleChatUpdated);
    _socketService.on('offer_accepted', _handleOfferUpdated);
    _socketService.on('offer_rejected', _handleOfferUpdated);
    _socketService.on('offer_created', _handleOfferCreated);
    _socketService.on('deal_completed', _handleChatStatusChanged);
    _socketService.on('deal_cancelled', _handleChatStatusChanged);
  }

  void _handleChatUpdated(dynamic data) {
    if (!mounted) return;
    try {
      final chatId = data['chatId'];
      final chatData = data['chat'];
      if (chatData != null) {
        final updatedChat = TradeChat.fromJson(chatData);
        _updateChatInLists(updatedChat);
      } else {
        _refreshSingleChat(chatId);
      }
    } catch (e) {
      print('Error handling chat updated: $e');
    }
  }

  void _handleOfferUpdated(dynamic data) {
    if (!mounted) return;
    try {
      final chatId = data['chatId'];
      _refreshSingleChat(chatId);
    } catch (e) {
      print('Error handling offer update: $e');
    }
  }

  void _handleOfferCreated(dynamic data) {
    if (!mounted) return;
    try {
      final chatId = data['chatId'];
      _refreshSingleChat(chatId);
    } catch (e) {
      print('Error handling offer created: $e');
    }
  }

  void _handleNewMessage(dynamic data) {
    if (!mounted) return;
    try {
      final chatId = data?['chatId']?.toString();
      if (chatId == null || chatId.isEmpty) return;
      _refreshSingleChat(chatId);
    } catch (e) {
      debugPrint('Error handling new message in list screen: $e');
    }
  }

  void _joinLoadedChatRooms(List<TradeChat> chats) {
    for (final chat in chats) {
      if (chat.id.isNotEmpty) {
        _socketService.joinChat(chat.id);
      }
    }
  }

  void _handleChatStatusChanged(dynamic data) {
    if (!mounted) return;
    try {
      final chatId = data['chatId'];
      _refreshSingleChat(chatId);
    } catch (e) {
      print('Error handling chat status change: $e');
    }
  }

  Future<void> _refreshSingleChat(String chatId) async {
    try {
      final updatedChat = await _chatService.getChatById(chatId);
      _updateChatInLists(updatedChat);
    } catch (e) {
      print('Error refreshing single chat: $e');
    }
  }

  void _updateChatInLists(TradeChat updatedChat) {
    setState(() {
      if (_shouldHideChat(updatedChat)) {
        _allChats.removeWhere((c) => c.id == updatedChat.id);
        _inboxChats.removeWhere((c) => c.id == updatedChat.id);
        _outboxChats.removeWhere((c) => c.id == updatedChat.id);
        _lastMessagePreviewCache.remove(updatedChat.id);
        _previewFetchInProgress.remove(updatedChat.id);
        return;
      }

      final allIndex = _allChats.indexWhere((c) => c.id == updatedChat.id);
      if (allIndex != -1) {
        _allChats[allIndex] = updatedChat;
      }

      final inboxIndex = _inboxChats.indexWhere((c) => c.id == updatedChat.id);
      if (inboxIndex != -1) {
        _inboxChats[inboxIndex] = updatedChat;
      }

      final outboxIndex = _outboxChats.indexWhere(
        (c) => c.id == updatedChat.id,
      );
      if (outboxIndex != -1) {
        _outboxChats[outboxIndex] = updatedChat;
      }

      _sortChatsByRecent(_allChats);
      _sortChatsByRecent(_inboxChats);
      _sortChatsByRecent(_outboxChats);

      if (updatedChat.messages.isNotEmpty) {
        _lastMessagePreviewCache[updatedChat.id] = _buildMessagePreview(
          updatedChat.messages,
        );
      }
    });

    _hydrateMessagePreviews([updatedChat]);
  }

  void _sortChatsByRecent(List<TradeChat> chats) {
    chats.sort((a, b) => b.lastInteraction.compareTo(a.lastInteraction));
  }

  // Only an explicit archive should remove a chat from the list. Hiding on
  // COMPLETED/INACTIVE/CANCELLED here used to make the chat vanish for the
  // other user as soon as one side acted, before they'd had a chance to
  // respond (e.g. give their own deal-completion consent).
  bool _shouldHideChat(TradeChat chat) {
    return chat.status == ChatStatus.ARCHIVED;
  }

  String _buildMessagePreview(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'No messages yet';

    final sorted = [...messages]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final lastMessage = sorted.last;

    if (lastMessage.isImage ||
        (lastMessage.imageUrl != null &&
            lastMessage.imageUrl!.trim().isNotEmpty)) {
      return '📷 Image';
    }

    if (lastMessage.isOffer) {
      return '💰 Offer update';
    }

    final content = lastMessage.messageText.trim();
    if (content.isEmpty) {
      return lastMessage.isSystem ? '🔔 System update' : 'No messages yet';
    }

    if (lastMessage.isSystem) {
      return '🔔 $content';
    }

    return content;
  }

  void _hydrateMessagePreviews(List<TradeChat> chats) {
    for (final chat in chats) {
      if (chat.id.isEmpty) continue;
      if (_lastMessagePreviewCache.containsKey(chat.id)) continue;
      if (_previewFetchInProgress.contains(chat.id)) continue;

      if (chat.messages.isNotEmpty) {
        _lastMessagePreviewCache[chat.id] = _buildMessagePreview(chat.messages);
        continue;
      }

      if (chat.lastMessageAt == null) continue;
      _fetchAndCacheLatestMessagePreview(chat.id);
    }
  }

  Future<void> _fetchAndCacheLatestMessagePreview(String chatId) async {
    if (_previewFetchInProgress.contains(chatId)) return;
    _previewFetchInProgress.add(chatId);

    try {
      final chat = await _chatService.getChatById(chatId);
      final preview = _buildMessagePreview(chat.messages);

      if (!mounted) return;
      setState(() {
        _lastMessagePreviewCache[chatId] = preview;
      });
    } catch (_) {
      // Keep graceful fallback when details request fails.
    } finally {
      _previewFetchInProgress.remove(chatId);
    }
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      final index = _tabController.index;
      if (index == 0 && _allChats.isEmpty) {
        _loadAllChats();
      } else if (index == 1 && _inboxChats.isEmpty) {
        _loadInboxChats();
      } else if (index == 2 && _outboxChats.isEmpty) {
        _loadOutboxChats();
      }
    }
  }

  Future<void> _refreshChats() async {
    setState(() {
      _allChatsCurrentPage = 1;
      _inboxCurrentPage = 1;
      _outboxCurrentPage = 1;
    });

    final currentIndex = _tabController.index;
    if (currentIndex == 0) {
      await _loadAllChats(refresh: true);
    } else if (currentIndex == 1) {
      await _loadInboxChats(refresh: true);
    } else if (currentIndex == 2) {
      await _loadOutboxChats(refresh: true);
    }
  }

  Future<void> _loadCurrentUser() async {
    debugPrint('👤 TradeChatScreen: Loading current user...');
    try {
      _currentUserId = await _tokenService.getUserId();
      debugPrint(
        '👤 TradeChatScreen: User ID from TokenService: $_currentUserId',
      );

      final token = await _tokenService.getToken();
      debugPrint(
        '🔑 TradeChatScreen: Token exists: ${token != null && token.isNotEmpty}',
      );

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        if (token != null) {
          _socketService.init(token: token);
        }
        debugPrint('✅ TradeChatScreen: User ID found, loading chats...');

        await Future.wait([
          _loadAllChats(refresh: true),
          _loadInboxChats(refresh: true),
          _loadOutboxChats(refresh: true),
        ]);
      } else {
        debugPrint('❌ TradeChatScreen: User ID is null or empty');
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in. Please login to continue.';
        });
      }
    } catch (e) {
      debugPrint('❌ TradeChatScreen: Error loading user: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user: $e';
      });
    }
  }

  Future<void> _loadAllChats({bool refresh = true}) async {
    debugPrint(
      '📥 TradeChatScreen: Loading all chats - refresh: $refresh, page: $_allChatsCurrentPage',
    );
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _allChatsCurrentPage = 1;
      });
    } else {
      setState(() {
        _isLoadingMoreAllChats = true;
      });
    }

    try {
      debugPrint('🌐 TradeChatScreen: Calling getAllChats service...');
      final response = await _chatService.getAllChats(
        page: _allChatsCurrentPage,
        limit: 20,
      );

      debugPrint('✅ TradeChatScreen: Received all chats response');
      debugPrint(
        '📊 TradeChatScreen: Total chats received: ${response.data.chats.length}',
      );

      final visibleChats = response.data.chats
          .where((chat) => !_shouldHideChat(chat))
          .cast<TradeChat>()
          .toList();

      setState(() {
        if (refresh) {
          _allChats = visibleChats;
          _sortChatsByRecent(_allChats);
          debugPrint(
            '🔄 TradeChatScreen: Refreshed all chats, new count: ${_allChats.length}',
          );
        } else {
          _allChats.addAll(visibleChats);
          _sortChatsByRecent(_allChats);
          debugPrint(
            '➕ TradeChatScreen: Added more chats, new total: ${_allChats.length}',
          );
        }
        _allChatsTotalPages = response.data.pagination.pages;
        _isLoading = false;
        _isLoadingMoreAllChats = false;
      });

      _joinLoadedChatRooms(visibleChats);
      _hydrateMessagePreviews(visibleChats);
    } catch (e) {
      debugPrint('❌ TradeChatScreen: Error loading all chats: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isLoadingMoreAllChats = false;
      });
    }
  }

  Future<void> _loadInboxChats({bool refresh = true}) async {
    debugPrint(
      '📥 TradeChatScreen: Loading inbox chats - refresh: $refresh, page: $_inboxCurrentPage, filter: $_selectedProductFilter',
    );
    if (refresh) {
      setState(() {
        _inboxCurrentPage = 1;
      });
    }

    try {
      final response = await _chatService.getInboxChats(
        page: _inboxCurrentPage,
        limit: 20,
        productId: _selectedProductFilter != 'All Products'
            ? _selectedProductFilter
            : null,
      );

      debugPrint('✅ TradeChatScreen: Received inbox chats response');
      debugPrint(
        '📊 TradeChatScreen: Total inbox chats received: ${response.data.chats.length}',
      );

      final visibleChats = response.data.chats
          .where((chat) => !_shouldHideChat(chat))
          .cast<TradeChat>()
          .toList();

      setState(() {
        if (refresh) {
          _inboxChats = visibleChats;
          _sortChatsByRecent(_inboxChats);
          debugPrint(
            '🔄 TradeChatScreen: Refreshed inbox chats, new count: ${_inboxChats.length}',
          );
        } else {
          _inboxChats.addAll(visibleChats);
          _sortChatsByRecent(_inboxChats);
          debugPrint(
            '➕ TradeChatScreen: Added more inbox chats, new total: ${_inboxChats.length}',
          );
        }
        _inboxTotalPages = response.data.pagination.pages;
        _isLoadingMoreInbox = false;
        _loadUserProducts();
      });

      _joinLoadedChatRooms(visibleChats);
      _hydrateMessagePreviews(visibleChats);
    } catch (e) {
      debugPrint('❌ TradeChatScreen: Error loading inbox chats: $e');
      setState(() {
        _isLoadingMoreInbox = false;
      });
    }
  }

  Future<void> _loadOutboxChats({bool refresh = true}) async {
    debugPrint(
      '📥 TradeChatScreen: Loading outbox chats - refresh: $refresh, page: $_outboxCurrentPage',
    );
    if (refresh) {
      setState(() {
        _outboxCurrentPage = 1;
      });
    }

    try {
      final response = await _chatService.getOutboxChats(
        page: _outboxCurrentPage,
        limit: 20,
      );

      debugPrint('✅ TradeChatScreen: Received outbox chats response');
      debugPrint(
        '📊 TradeChatScreen: Total outbox chats received: ${response.data.chats.length}',
      );

      final visibleChats = response.data.chats
          .where((chat) => !_shouldHideChat(chat))
          .cast<TradeChat>()
          .toList();

      setState(() {
        if (refresh) {
          _outboxChats = visibleChats;
          _sortChatsByRecent(_outboxChats);
          debugPrint(
            '🔄 TradeChatScreen: Refreshed outbox chats, new count: ${_outboxChats.length}',
          );
        } else {
          _outboxChats.addAll(visibleChats);
          _sortChatsByRecent(_outboxChats);
          debugPrint(
            '➕ TradeChatScreen: Added more outbox chats, new total: ${_outboxChats.length}',
          );
        }
        _outboxTotalPages = response.data.pagination.pages;
        _isLoadingMoreOutbox = false;
      });

      _joinLoadedChatRooms(visibleChats);
      _hydrateMessagePreviews(visibleChats);
    } catch (e) {
      debugPrint('❌ TradeChatScreen: Error loading outbox chats: $e');
      setState(() {
        _isLoadingMoreOutbox = false;
      });
    }
  }

  void _loadMoreChats() {
    if (_isLoadingMoreAllChats || _isLoadingMoreInbox || _isLoadingMoreOutbox)
      return;

    final currentIndex = _tabController.index;
    if (currentIndex == 0) {
      if (_allChatsCurrentPage < _allChatsTotalPages) {
        setState(() {
          _allChatsCurrentPage++;
          _isLoadingMoreAllChats = true;
        });
        _loadAllChats(refresh: false);
      }
    } else if (currentIndex == 1) {
      if (_inboxCurrentPage < _inboxTotalPages) {
        setState(() {
          _inboxCurrentPage++;
          _isLoadingMoreInbox = true;
        });
        _loadInboxChats(refresh: false);
      }
    } else if (currentIndex == 2) {
      if (_outboxCurrentPage < _outboxTotalPages) {
        setState(() {
          _outboxCurrentPage++;
          _isLoadingMoreOutbox = true;
        });
        _loadOutboxChats(refresh: false);
      }
    }
  }

  void _loadUserProducts() {
    debugPrint('📦 TradeChatScreen: Loading user products from inbox chats...');
    final products = _inboxChats
        .map((chat) => chat.postTitle)
        .where((title) => title.isNotEmpty)
        .toSet()
        .toList();

    setState(() {
      _userProducts = ['All Products', ...products];
    });
    debugPrint(
      '📦 TradeChatScreen: Found ${_userProducts.length - 1} unique products',
    );
  }

  void _showProductFilterDialog() {
    debugPrint('🎯 TradeChatScreen: Showing product filter dialog');
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
              'Filter by Your Product',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ..._userProducts.map((product) {
              return ListTile(
                title: Text(product),
                trailing: _selectedProductFilter == product
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  debugPrint(
                    '🎯 TradeChatScreen: Selected product filter: $product',
                  );
                  setState(() {
                    _selectedProductFilter = product;
                  });
                  Navigator.pop(context);
                  _loadInboxChats(refresh: true);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                debugPrint('🎯 TradeChatScreen: Clearing product filter');
                setState(() {
                  _selectedProductFilter = null;
                });
                Navigator.pop(context);
                _loadInboxChats(refresh: true);
              },
              child: const Text('Clear Filter'),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatDetail(TradeChat chat) {
    if (_currentUserId == null) {
      debugPrint(
        '⚠️ TradeChatScreen: Cannot open chat - currentUserId is null',
      );
      return;
    }

    if (_shouldHideChat(chat)) {
      setState(() {
        _allChats.removeWhere((c) => c.id == chat.id);
        _inboxChats.removeWhere((c) => c.id == chat.id);
        _outboxChats.removeWhere((c) => c.id == chat.id);
        _lastMessagePreviewCache.remove(chat.id);
        _previewFetchInProgress.remove(chat.id);
      });
      return;
    }

    debugPrint(
      '👉 TradeChatScreen: Opening chat detail for chat ID: ${chat.id}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chat: chat,
          currentUserId: _currentUserId!,
          onChatUpdated: _updateChat,
        ),
      ),
    );
  }

  void _updateChat(TradeChat updatedChat) {
    debugPrint('🔄 TradeChatScreen: Updating chat: ${updatedChat.id}');
    _updateChatInLists(updatedChat);
  }

  String _getLastMessagePreview(TradeChat chat) {
    final preview = chat.messages.isNotEmpty
        ? _buildMessagePreview(chat.messages)
        : _lastMessagePreviewCache[chat.id];

    final resolved =
        preview ??
        (chat.lastMessageAt != null ? 'Loading message...' : 'No messages yet');

    return resolved.length > 60 ? '${resolved.substring(0, 60)}...' : resolved;
  }

  Widget _buildChatItem(TradeChat chat) {
    if (_currentUserId == null) {
      return const SizedBox();
    }

    final otherUser = chat.getOtherUserInfo(_currentUserId!);
    final unreadCount = chat.messages
        .where((msg) => !msg.isRead && msg.sentById != _currentUserId)
        .length;

    return InkWell(
      onTap: () => _openChatDetail(chat),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: otherUser.profileImage != null
                      ? NetworkImage(otherUser.profileImage!)
                      : null,
                  child: otherUser.profileImage == null
                      ? Text(otherUser.firstName[0].toUpperCase())
                      : null,
                ),
                if (chat.isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                if (unreadCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUser.firstName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        chat.formattedDate,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    chat.postTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getOfferTypeColor(chat.offerType),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          chat.offerType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (chat.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (chat.isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Cancelled',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getLastMessagePreview(chat),
                    style: TextStyle(
                      fontSize: 12,
                      color: unreadCount > 0 ? Colors.black : Colors.grey,
                      fontWeight: unreadCount > 0
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: chat.postImage.isNotEmpty
                  ? Image.network(
                      chat.postImage,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOfferTypeColor(String offerType) {
    switch (offerType) {
      case 'Product':
        return Colors.orange;
      case 'Service':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '🏗️ TradeChatScreen: Building UI - Loading: $_isLoading, Error: $_errorMessage',
    );

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateToHomeScreen,
          ),
          title: const Text('Trade Chat'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: const Center(child: LoadingWidget()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateToHomeScreen,
          ),
          title: const Text('Trade Chat'),
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
        body: Center(
          child: ErrorDisplayWidget(
            message: _errorMessage!,
            onRetry: () {
              debugPrint('🔄 TradeChatScreen: Retry button pressed');
              _loadCurrentUser();
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToHomeScreen,
        ),
        title: const Text('Trade Chat'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Chats'),
            Tab(text: 'Inbox'),
            Tab(text: 'Outbox'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRefreshWrapper(
            _buildChatList(_allChats, isLoadingMore: _isLoadingMoreAllChats),
          ),
          _buildRefreshWrapper(_buildInboxList()),
          _buildRefreshWrapper(
            _buildChatList(_outboxChats, isLoadingMore: _isLoadingMoreOutbox),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshWrapper(Widget child) {
    return RefreshIndicator(
      onRefresh: _refreshChats,
      color: const Color(0xFF2E5BFF),
      backgroundColor: Colors.transparent,
      elevation: 0,
      strokeWidth: 2.2,
      child: child,
    );
  }

  Widget _buildChatList(List<TradeChat> chats, {required bool isLoadingMore}) {
    debugPrint('📋 Building chat list with ${chats.length} chats');

    if (chats.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No chats yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When you start a conversation,\n it will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!isLoadingMore &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 100) {
          debugPrint('📜 Scroll threshold reached, loading more chats...');
          _loadMoreChats();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        itemCount: chats.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == chats.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildChatItem(chats[index]);
        },
      ),
    );
  }

  Widget _buildInboxList() {
    if (_inboxChats.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No incoming offers',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When someone makes an offer on your items,\n they will appear here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (!_isLoadingMoreInbox &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 100) {
          _loadMoreChats();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: _inboxChats.length + (_isLoadingMoreInbox ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _inboxChats.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildChatItem(_inboxChats[index]);
        },
      ),
    );
  }
}
