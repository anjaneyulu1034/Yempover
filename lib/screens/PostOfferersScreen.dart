// GET /me/posts/products/:id/offers | /me/posts/services/:id/offers (Point 4)
// — who has made an offer on one of the owner's posts. Tapping a row opens
// the live chat for that offerer via chatId.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yempover_app/models/my_post_model.dart';
import 'package:yempover_app/screens/tradechatscreen/ChatDetailScreen.dart';
import 'package:yempover_app/services/my_posts_service.dart';
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/services/trade_chat_service/trade_chat_service.dart';
import 'package:yempover_app/utils/error_message_utils.dart';
import 'package:yempover_app/utils/snackbar_utils.dart';
import 'package:yempover_app/widgets/coin_icon.dart';

class PostOfferersScreen extends StatefulWidget {
  final String postId;
  final String postTitle;
  final bool isProduct;

  const PostOfferersScreen({
    super.key,
    required this.postId,
    required this.postTitle,
    required this.isProduct,
  });

  @override
  State<PostOfferersScreen> createState() => _PostOfferersScreenState();
}

class _PostOfferersScreenState extends State<PostOfferersScreen> {
  final MyPostsService _postsService = MyPostsService();
  final TradeChatService _chatService = TradeChatService();
  final TokenService _tokenService = TokenService();

  bool _isLoading = true;
  String? _errorMessage;
  List<PostOfferer> _offerers = [];
  String? _openingChatId;

  @override
  void initState() {
    super.initState();
    _fetchOfferers();
  }

  Future<void> _fetchOfferers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result = await _postsService.getPostOfferers(
        postId: widget.postId,
        isProduct: widget.isProduct,
      );
      if (!mounted) return;
      setState(() {
        _offerers = result.offerers;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorMessageUtils.sanitize(e);
      });
    }
  }

  Future<void> _openChat(PostOfferer offerer) async {
    if (_openingChatId != null) return;
    setState(() => _openingChatId = offerer.chatId);
    try {
      final currentUserId = await _tokenService.getUserId();
      final chat = await _chatService.getChatById(offerer.chatId);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chat: chat,
            currentUserId: currentUserId!,
            onChatUpdated: (_) {},
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Could not open the chat: $e');
    } finally {
      if (mounted) setState(() => _openingChatId = null);
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'COUNTERED':
        return Colors.purple;
      case 'WITHDRAWN':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildOfferStatusChip(String? status) {
    if (status == null) return const SizedBox();
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status[0] + status.substring(1).toLowerCase(),
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Offers on "${widget.postTitle}"',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchOfferers,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E5BFF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _offerers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No offers yet',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchOfferers,
                      color: const Color(0xFF2E5BFF),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _offerers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final offerer = _offerers[index];
                          final isOpening = _openingChatId == offerer.chatId;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: isOpening ? null : () => _openChat(offerer),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: offerer.profileImage != null
                                        ? NetworkImage(offerer.profileImage!)
                                        : null,
                                    child: offerer.profileImage == null
                                        ? Text(
                                            offerer.name.isNotEmpty
                                                ? offerer.name[0].toUpperCase()
                                                : '?',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          offerer.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            if (!offerer.isZeroCoin &&
                                                offerer.amount != null &&
                                                offerer.amount! > 0) ...[
                                              const CoinIcon(size: 14, iconSize: 9),
                                              const SizedBox(width: 3),
                                            ],
                                            Expanded(
                                              child: Text(
                                                offerer.offerSummary,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey.shade700,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (offerer.offeredAt != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat('MMM d, yyyy').format(offerer.offeredAt!),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (isOpening)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  else
                                    _buildOfferStatusChip(offerer.offerStatus),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
