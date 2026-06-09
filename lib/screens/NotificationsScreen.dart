import 'package:yempover_app/models/ProductPostmain.dart' hide AppNotification;
import 'package:yempover_app/screens/PostDetailScreen.dart';
import 'package:yempover_app/screens/notification_preferences_screen.dart';
import 'package:yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:yempover_app/screens/tradechatscreen/TradeChatScreen.dart';
import 'package:yempover_app/services/api_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/utils/CustomErrorWidget.dart';
import 'package:yempover_app/utils/loading_widget.dart';
import 'package:yempover_app/utils/notification_provider.dart';
import 'package:yempover_app/utils/notification_tile.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required List<AppNotification> notifications,
    required Null Function(AppNotification) onNotificationTap,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final TradeChatService _tradeChatService = TradeChatService();
  final TokenService _tokenService = TokenService();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadInitialData();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _apiService.dispose();
    _tradeChatService.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.loadNotifications();
    await provider.loadUnreadCount();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);

    if (!_isLoadingMore && provider.hasMorePages && !provider.isLoading) {
      _setLoadingMoreSafely(true);
      await provider.loadMoreNotifications();
      _setLoadingMoreSafely(false);
    }
  }

  void _setLoadingMoreSafely(bool value) {
    if (!mounted || _isLoadingMore == value) return;

    final phase = SchedulerBinding.instance.schedulerPhase;
    final isBuilding =
        phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.transientCallbacks;

    if (isBuilding) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _isLoadingMore == value) return;
        setState(() => _isLoadingMore = value);
      });
      return;
    }

    setState(() => _isLoadingMore = value);
  }

  Future<void> _refreshNotifications() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    await provider.loadNotifications();
    await provider.loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        // actions: [
        //   IconButton(
        //     tooltip: 'Preferences',
        //     onPressed: () => _navigateToPreferences(context),
        //     icon: const Icon(Icons.tune_rounded),
        //   ),
        //   Consumer<NotificationProvider>(
        //     builder: (context, provider, _) {
        //       return IconButton(
        //         tooltip: 'Clear all',
        //         onPressed: provider.notifications.isEmpty
        //             ? null
        //             : () => _clearAllNotifications(context),
        //         icon: const Icon(Icons.delete_sweep_rounded),
        //       );
        //     },
        //   ),
        // ],
      ),
      backgroundColor: Colors.white,
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return const Center(child: LoadingWidget());
          }

          return Column(
            children: [
              // Notification Statistics
              _buildStatisticsHeader(provider),

              // Notifications List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshNotifications,
                  color: const Color(0xFF2E5BFF),
                  backgroundColor: Colors.white,
                  elevation: 0,
                  strokeWidth: 2.2,
                  child: provider.notifications.isEmpty
                      ? EmptyStateWidget(
                          icon: Icons.notifications_off,
                          title: 'No notifications',
                          message: 'You\'re all caught up!',
                          // buttonText: '',
                          // onButtonPressed: () {},
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.zero,
                          itemCount:
                              provider.notifications.length +
                              (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == provider.notifications.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            }

                            final notification = provider.notifications[index];
                            return NotificationTile(
                              notification: notification,
                              onTap: () => _handleNotificationTap(
                                context,
                                notification,
                                provider,
                              ),
                              onDismissed: () => _dismissNotification(
                                context,
                                notification,
                                provider,
                              ),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsHeader(NotificationProvider provider) {
    final unreadCount = provider.unreadCount;
    final totalCount = provider.totalCount;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.48)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _statCard(
                value: '$unreadCount',
                label: 'Unread',
                accent: const Color(0xFF1A73E8),
              ),
              const SizedBox(width: 10),
              _statCard(
                value: '$totalCount',
                label: 'Total',
                accent: const Color(0xFF2C3E50),
              ),
            ],
          ),
          if (provider.notifications.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markAllAsRead(context),
                icon: const Icon(Icons.done_all, size: 18),
                label: const Text('Mark all as read'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF1A73E8,
                  ).withValues(alpha: 0.9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statCard({
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) async {
    if (!notification.isRead) {
      await provider.markAsRead(notification.id);
    }

    try {
      final chatId = _resolveTradeChatId(notification);
      if (chatId != null) {
        await _openChatDetail(chatId);
        return;
      }

      final postId = _resolvePostId(notification);
      if (postId != null) {
        await _openPostDetail(postId, _isServiceNotification(notification));
        return;
      }

      if (_isTradeNotification(notification)) {
        if (!context.mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TradeChatScreen()),
        );
        return;
      }
    } catch (e) {
      if (!context.mounted) return;
      SnackbarUtils.showError(context, 'Unable to open notification: $e');
      return;
    }

    if (!context.mounted) return;
    SnackbarUtils.showInfo(context, notification.message);
  }

  String? _extractIdFromRoute(String? route, List<String> prefixes) {
    if (route == null || route.trim().isEmpty) return null;

    final trimmedRoute = route.trim();
    Uri? uri;
    try {
      uri = Uri.parse(trimmedRoute);
    } catch (_) {
      uri = null;
    }

    final path = (uri?.path.isNotEmpty == true) ? uri!.path : trimmedRoute;
    for (final prefix in prefixes) {
      if (!path.startsWith(prefix)) continue;

      final remaining = path.substring(prefix.length);
      final segments = remaining
          .split('/')
          .where((segment) => segment.isNotEmpty)
          .toList();
      if (segments.isNotEmpty) {
        return segments.first;
      }
    }

    return null;
  }

  bool _isTradeNotification(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.OFFER_RECEIVED:
      case NotificationType.OFFER_ACCEPTED:
      case NotificationType.OFFER_REJECTED:
      case NotificationType.OFFER_COUNTERED:
      case NotificationType.OFFER_WITHDRAWN:
      case NotificationType.MESSAGE_RECEIVED:
      case NotificationType.DEAL_COMPLETED:
      case NotificationType.DEAL_CANCELLED:
      case NotificationType.TRADE_COMPLETED:
        return true;
      default:
        return false;
    }
  }

  String? _resolveTradeChatId(AppNotification notification) {
    if (notification.tradeChatId != null &&
        notification.tradeChatId!.isNotEmpty) {
      return notification.tradeChatId;
    }

    return _extractIdFromRoute(notification.navigationRoute, [
      '/trade-chat/',
      '/trade-chats/',
      '/chat/',
      '/chats/',
    ]);
  }

  String? _resolvePostId(AppNotification notification) {
    if (notification.productId != null && notification.productId!.isNotEmpty) {
      return notification.productId;
    }

    if (notification.serviceId != null && notification.serviceId!.isNotEmpty) {
      return notification.serviceId;
    }

    return _extractIdFromRoute(notification.navigationRoute, [
      '/product/',
      '/products/',
      '/service/',
      '/services/',
      '/post/',
      '/posts/',
    ]);
  }

  bool _isServiceNotification(AppNotification notification) {
    if (notification.serviceId != null && notification.serviceId!.isNotEmpty) {
      return true;
    }

    if (notification.productId != null && notification.productId!.isNotEmpty) {
      return false;
    }

    final route = notification.navigationRoute ?? '';
    return route.contains('/service/') || route.contains('/services/');
  }

  Future<void> _openChatDetail(String chatId) async {
    final chat = await _tradeChatService.getChatById(chatId);
    final currentUserId = await _tokenService.getUserId();

    if (currentUserId == null || currentUserId.isEmpty) {
      throw Exception('User not found');
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chat: chat,
          currentUserId: currentUserId,
          onChatUpdated: (_) {},
        ),
      ),
    );
  }

  Future<void> _openPostDetail(String postId, bool isService) async {
    final response = await _apiService.getPostDetail(
      postId: postId,
      type: isService ? PostType.service : PostType.product,
    );

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PostDetailScreen(post: response.post, userItems: const []),
      ),
    );
  }

  Future<void> _dismissNotification(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) async {
    final success = await provider.deleteNotification(notification.id);
    if (success && context.mounted) {
      SnackbarUtils.showSuccess(context, 'Notification dismissed');
    }
  }

  Future<void> _markAllAsRead(BuildContext context) async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final success = await provider.markAllAsRead();

    if (success && context.mounted) {
      SnackbarUtils.showSuccess(context, 'All notifications marked as read');
    }
  }

  Future<void> _clearAllNotifications(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              final provider = Provider.of<NotificationProvider>(
                context,
                listen: false,
              );
              final success = await provider.clearAllNotifications();

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications cleared'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _navigateToPreferences(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotificationPreferencesScreen(),
      ),
    );
  }
}
