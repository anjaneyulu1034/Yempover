// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart';
// import 'package:Yempover_app/models/chats/trade_chat.dart';
// import 'package:Yempover_app/services/trade_chat_service/trade_chat_service.dart';
// import 'package:Yempover_app/utils/loading_widget.dart';

// class ChatDetailScreen extends StatefulWidget {
//   final TradeChat chat;
//   final String currentUserId;
//   final void Function(TradeChat) onChatUpdated;

//   const ChatDetailScreen({
//     super.key,
//     required this.chat,
//     required this.currentUserId,
//     required this.onChatUpdated,
//   });

//   @override
//   State<ChatDetailScreen> createState() => _ChatDetailScreenState();
// }

// class _ChatDetailScreenState extends State<ChatDetailScreen> {
//   final TradeChatService _chatService = TradeChatService();
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final ImagePicker _imagePicker = ImagePicker();

//   late TradeChat _currentChat;
//   List<ChatMessage> _messages = [];
//   bool _isLoading = false;
//   bool _isSendingImage = false;

//   @override
//   void initState() {
//     super.initState();
//     _currentChat = widget.chat;
//     _messages = List.from(_currentChat.messages);
//     _markMessagesAsRead();
//     _scrollToBottom();
//     _refreshChat(); // Add this line to refresh messages on load
//   }

//   @override
//   void dispose() {
//     _messageController.dispose();
//     _scrollController.dispose();
//     _chatService.dispose();
//     super.dispose();
//   }

//   Future<void> _markMessagesAsRead() async {
//     try {
//       await _chatService.markMessagesAsRead(_currentChat.id);
//     } catch (e) {
//       print('Error marking messages as read: $e');
//     }
//   }

//   Future<void> _sendMessage() async {
//     if (_messageController.text.trim().isEmpty) return;

//     final content = _messageController.text.trim();
//     _messageController.clear();

//     // Optimistically add message
//     final tempMessage = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       tradeChatId: _currentChat.id,
//       sentById: widget.currentUserId,
//       messageText: content,
//       messageType: MessageType.TEXT,
//       isRead: false,
//       createdAt: DateTime.now(),
//       sentBy: null,
//       imageUrl: null,
//       readAt: null,
//       offerId: null,
//     );

//     setState(() {
//       _messages.add(tempMessage);
//     });
//     _scrollToBottom();

//     try {
//       final sentMessage = await _chatService.sendMessage(
//         chatId: _currentChat.id,
//         messageText: content,
//         content: '',
//       );

//       // Replace temp message with actual
//       setState(() {
//         final index = _messages.indexWhere((m) => m.id == tempMessage.id);
//         if (index != -1) {
//           _messages[index] = sentMessage;
//         }
//       });

//       // Update last message in chat
//       _currentChat = TradeChat(
//         id: _currentChat.id,
//         initiatorId: _currentChat.initiatorId,
//         responderId: _currentChat.responderId,
//         productId: _currentChat.productId,
//         serviceId: _currentChat.serviceId,
//         status: _currentChat.status,
//         lastMessageAt: DateTime.now(),
//         createdAt: _currentChat.createdAt,
//         updatedAt: DateTime.now(),
//         initiator: _currentChat.initiator,
//         responder: _currentChat.responder,
//         product: _currentChat.product,
//         service: _currentChat.service,
//         messages: _messages,
//         offers: _currentChat.offers,
//       );

//       widget.onChatUpdated(_currentChat);
//     } catch (e) {
//       // Show error and remove temp message
//       setState(() {
//         _messages.removeWhere((m) => m.id == tempMessage.id);
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send message: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   // Add this method to ChatDetailScreen
//   Future<void> _refreshChat() async {
//     try {
//       final updatedChat = await _chatService.getChatById(_currentChat.id);
//       setState(() {
//         _currentChat = updatedChat;
//         _messages = List.from(updatedChat.messages);
//       });
//       _scrollToBottom();
//     } catch (e) {
//       print('Error refreshing chat: $e');
//     }
//   }

//   Future<void> _pickAndSendImage() async {
//     try {
//       final XFile? pickedFile = await _imagePicker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 80,
//       );

//       if (pickedFile == null) return;

//       setState(() {
//         _isSendingImage = true;
//       });

//       final imageFile = File(pickedFile.path);

//       // Optimistically add a loading message
//       final tempMessage = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         tradeChatId: _currentChat.id,
//         sentById: widget.currentUserId,
//         messageText: 'Sending image...',
//         messageType: MessageType.IMAGE,
//         isRead: false,
//         createdAt: DateTime.now(),
//         sentBy: null,
//         imageUrl: null,
//         readAt: null,
//         offerId: null,
//       );

//       setState(() {
//         _messages.add(tempMessage);
//       });
//       _scrollToBottom();

//       // Upload image
//       final sentMessage = await _chatService.uploadImageMessage(
//         chatId: _currentChat.id,
//         imageFile: imageFile,
//       );

//       // Replace temp message with actual
//       setState(() {
//         final index = _messages.indexWhere((m) => m.id == tempMessage.id);
//         if (index != -1) {
//           _messages[index] = sentMessage;
//         }
//         _isSendingImage = false;
//       });

//       _scrollToBottom();
//     } catch (e) {
//       setState(() {
//         _isSendingImage = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to send image: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _showMakeOfferDialog() async {
//     final result = await showDialog<Map<String, dynamic>>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Make an Offer'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.attach_money, color: Colors.green),
//               title: const Text('Price Offer'),
//               subtitle: const Text('Make a cash offer'),
//               onTap: () => Navigator.pop(context, {'type': 'price'}),
//             ),
//             ListTile(
//               leading: const Icon(Icons.sync_alt, color: Colors.orange),
//               title: const Text('Barter Offer'),
//               subtitle: const Text('Offer an item for trade'),
//               onTap: () => Navigator.pop(context, {'type': 'barter'}),
//             ),
//           ],
//         ),
//       ),
//     );

//     if (result == null) return;

//     if (result['type'] == 'price') {
//       _showPriceOfferDialog();
//     } else if (result['type'] == 'barter') {
//       _showBarterOfferDialog();
//     }
//   }

//   Future<void> _showPriceOfferDialog() async {
//     final priceController = TextEditingController();
//     final currencyController = TextEditingController(text: 'USD');

//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Price Offer'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: priceController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: 'Price',
//                 prefixText: '\$ ',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: currencyController,
//               decoration: const InputDecoration(
//                 labelText: 'Currency',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (priceController.text.isNotEmpty) {
//                 Navigator.pop(context, true);
//               }
//             },
//             child: const Text('Create Offer'),
//           ),
//         ],
//       ),
//     );

//     if (result == true && priceController.text.isNotEmpty) {
//       await _createPriceOffer(
//         price: double.parse(priceController.text),
//         currency: currencyController.text,
//       );
//     }
//   }

//   Future<void> _showBarterOfferDialog() async {
//     final titleController = TextEditingController();
//     final descriptionController = TextEditingController();

//     final result = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Barter Offer'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: titleController,
//               decoration: const InputDecoration(
//                 labelText: 'Item Title',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: descriptionController,
//               maxLines: 3,
//               decoration: const InputDecoration(
//                 labelText: 'Description (Optional)',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               if (titleController.text.isNotEmpty) {
//                 Navigator.pop(context, true);
//               }
//             },
//             child: const Text('Create Offer'),
//           ),
//         ],
//       ),
//     );

//     if (result == true && titleController.text.isNotEmpty) {
//       await _createBarterOffer(
//         title: titleController.text,
//         description: descriptionController.text.isNotEmpty
//             ? descriptionController.text
//             : null,
//       );
//     }
//   }

//   Future<void> _createPriceOffer({
//     required double price,
//     required String currency,
//   }) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final offer = await _chatService.createPriceOffer(
//         chatId: _currentChat.id,
//         price: price,
//         currency: currency,
//       );

//       // Add offer as a system message
//       final systemMessage = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         tradeChatId: _currentChat.id,
//         sentById: 'system',
//         messageText:
//             'Price offer created: \$${price.toStringAsFixed(2)} $currency',
//         messageType: MessageType.SYSTEM,
//         isRead: true,
//         createdAt: DateTime.now(),
//         sentBy: null,
//         imageUrl: null,
//         readAt: null,
//         offerId: offer.id,
//       );

//       setState(() {
//         _currentChat.offers.add(offer);
//         _messages.add(systemMessage);
//         _isLoading = false;
//       });

//       _scrollToBottom();
//       widget.onChatUpdated(_currentChat);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create offer: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _createBarterOffer({
//     required String title,
//     String? description,
//   }) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final offer = await _chatService.createBarterOffer(
//         chatId: _currentChat.id,
//         barterItemTitle: title,
//         barterItemDescription: description,
//       );

//       // Add offer as a system message
//       final systemMessage = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         tradeChatId: _currentChat.id,
//         sentById: 'system',
//         messageText: 'Barter offer created: $title',
//         messageType: MessageType.SYSTEM,
//         isRead: true,
//         createdAt: DateTime.now(),
//         sentBy: null,
//         imageUrl: null,
//         readAt: null,
//         offerId: offer.id,
//       );

//       setState(() {
//         _currentChat.offers.add(offer);
//         _messages.add(systemMessage);
//         _isLoading = false;
//       });

//       _scrollToBottom();
//       widget.onChatUpdated(_currentChat);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to create offer: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _acceptOffer(TradeOffer offer) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final acceptedOffer = await _chatService.acceptOffer(offer.id);

//       // Add system message
//       final systemMessage = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         tradeChatId: _currentChat.id,
//         sentById: 'system',
//         messageText: 'Offer accepted',
//         messageType: MessageType.SYSTEM,
//         isRead: true,
//         createdAt: DateTime.now(),
//         sentBy: null,
//         imageUrl: null,
//         readAt: null,
//         offerId: acceptedOffer.id,
//       );

//       setState(() {
//         final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
//         if (index != -1) {
//           _currentChat.offers[index] = acceptedOffer;
//         }
//         _messages.add(systemMessage);
//         _isLoading = false;
//       });

//       _scrollToBottom();
//       widget.onChatUpdated(_currentChat);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to accept offer: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _rejectOffer(TradeOffer offer) async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final rejectedOffer = await _chatService.rejectOffer(offer.id);

//       // Add system message
//       final systemMessage = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         tradeChatId: _currentChat.id,
//         sentById: 'system',
//         messageText: 'Offer rejected',
//         messageType: MessageType.SYSTEM,
//         isRead: true,
//         createdAt: DateTime.now(),
//         sentBy: null,
//         imageUrl: null,
//         readAt: null,
//         offerId: rejectedOffer.id,
//       );

//       setState(() {
//         final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
//         if (index != -1) {
//           _currentChat.offers[index] = rejectedOffer;
//         }
//         _messages.add(systemMessage);
//         _isLoading = false;
//       });

//       _scrollToBottom();
//       widget.onChatUpdated(_currentChat);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to reject offer: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _withdrawOffer(TradeOffer offer) async {
//     if (!offer.isPending) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final withdrawnOffer = await _chatService.withdrawOffer(offer.id);

//       // Add system message
//       final systemMessage = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         tradeChatId: _currentChat.id,
//         sentById: 'system',
//         messageText: 'Offer withdrawn',
//         messageType: MessageType.SYSTEM,
//         isRead: true,
//         createdAt: DateTime.now(),
//         sentBy: null,
//         imageUrl: null,
//         readAt: null,
//         offerId: withdrawnOffer.id,
//       );

//       setState(() {
//         final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
//         if (index != -1) {
//           _currentChat.offers[index] = withdrawnOffer;
//         }
//         _messages.add(systemMessage);
//         _isLoading = false;
//       });

//       _scrollToBottom();
//       widget.onChatUpdated(_currentChat);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to withdraw offer: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _completeTrade() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final completedChat = await _chatService.completeTrade(_currentChat.id);

//       // Add system message
//       final systemMessage = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         tradeChatId: _currentChat.id,
//         sentById: 'system',
//         messageText: 'Trade completed successfully',
//         messageType: MessageType.SYSTEM,
//         isRead: true,
//         createdAt: DateTime.now(),
//         sentBy: null,
//         imageUrl: null,
//         readAt: null,
//         offerId: null,
//       );

//       setState(() {
//         _currentChat = completedChat;
//         _messages.add(systemMessage);
//         _isLoading = false;
//       });

//       _scrollToBottom();
//       widget.onChatUpdated(_currentChat);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to complete trade: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _cancelTrade() async {
//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Cancel Trade'),
//         content: const Text('Are you sure you want to cancel this trade?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text('No'),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Yes, Cancel'),
//           ),
//         ],
//       ),
//     );

//     if (confirm != true) return;

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final cancelledChat = await _chatService.cancelTrade(_currentChat.id);

//       // Add system message
//       final systemMessage = ChatMessage(
//         id: DateTime.now().millisecondsSinceEpoch.toString(),
//         tradeChatId: _currentChat.id,
//         sentById: 'system',
//         messageText: 'Trade cancelled',
//         messageType: MessageType.SYSTEM,
//         isRead: true,
//         createdAt: DateTime.now(),
//         sentBy: null,
//         imageUrl: null,
//         readAt: null,
//         offerId: null,
//       );

//       setState(() {
//         _currentChat = cancelledChat;
//         _messages.add(systemMessage);
//         _isLoading = false;
//       });

//       _scrollToBottom();
//       widget.onChatUpdated(_currentChat);
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to cancel trade: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   Future<void> _archiveChat() async {
//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       final archivedChat = await _chatService.archiveChat(_currentChat.id);

//       setState(() {
//         _currentChat = archivedChat;
//         _isLoading = false;
//       });

//       widget.onChatUpdated(_currentChat);

//       if (mounted) {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Chat archived'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Failed to archive chat: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   UserInfo _getOtherUser() {
//     return _currentChat.getOtherUserInfo(widget.currentUserId);
//   }

//   bool _isMessageFromCurrentUser(ChatMessage message) {
//     return message.sentById == widget.currentUserId;
//   }

//   String _formatMessageTime(DateTime dateTime) {
//     final now = DateTime.now();
//     final difference = now.difference(dateTime);

//     if (difference.inDays > 0) {
//       return DateFormat('MMM d').format(dateTime);
//     } else {
//       return DateFormat('h:mm a').format(dateTime);
//     }
//   }

//   Widget _buildMessageBubble(ChatMessage message) {
//     final isCurrentUser = _isMessageFromCurrentUser(message);
//     final isSystemMessage = message.messageType == MessageType.SYSTEM;
//     final isImageMessage = message.messageType == MessageType.IMAGE;
//     final isOfferMessage = message.messageType == MessageType.OFFER;
//     final otherUser = _getOtherUser();

//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Row(
//         mainAxisAlignment: isSystemMessage
//             ? MainAxisAlignment.center
//             : isCurrentUser
//             ? MainAxisAlignment.end
//             : MainAxisAlignment.start,
//         children: [
//           if (!isCurrentUser && !isSystemMessage)
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: otherUser.profileImage != null
//                   ? NetworkImage(otherUser.profileImage!)
//                   : null,
//               child: otherUser.profileImage == null
//                   ? Text(otherUser.firstName[0].toUpperCase())
//                   : null,
//             ),
//           const SizedBox(width: 8),
//           Flexible(
//             child: Container(
//               constraints: BoxConstraints(
//                 maxWidth: MediaQuery.of(context).size.width * 0.7,
//               ),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: isSystemMessage
//                     ? Colors.grey.shade200
//                     : isCurrentUser
//                     ? Colors.blue.shade100
//                     : Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (isOfferMessage)
//                     Padding(
//                       padding: const EdgeInsets.only(bottom: 4),
//                       child: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           const Icon(
//                             Icons.request_page,
//                             size: 14,
//                             color: Colors.blue,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             'Offer',
//                             style: TextStyle(
//                               fontSize: 12,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.blue.shade700,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                   if (isImageMessage && message.imageUrl != null)
//                     GestureDetector(
//                       onTap: () {
//                         // Show full screen image
//                         showDialog(
//                           context: context,
//                           builder: (context) => Dialog(
//                             child: InteractiveViewer(
//                               child: Image.network(
//                                 message.imageUrl!,
//                                 fit: BoxFit.contain,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                       child: ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: Image.network(
//                           message.imageUrl!,
//                           width: 200,
//                           height: 200,
//                           fit: BoxFit.cover,
//                           errorBuilder: (context, error, stackTrace) {
//                             return Container(
//                               width: 200,
//                               height: 200,
//                               color: Colors.grey.shade300,
//                               child: const Icon(Icons.broken_image),
//                             );
//                           },
//                         ),
//                       ),
//                     )
//                   else
//                     Text(
//                       message.messageText,
//                       style: const TextStyle(fontSize: 14),
//                     ),

//                   const SizedBox(height: 4),

//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         _formatMessageTime(message.createdAt),
//                         style: const TextStyle(
//                           fontSize: 10,
//                           color: Colors.grey,
//                         ),
//                       ),
//                       if (isCurrentUser && !isSystemMessage) ...[
//                         const SizedBox(width: 4),
//                         Icon(
//                           message.isRead ? Icons.done_all : Icons.done,
//                           size: 12,
//                           color: message.isRead ? Colors.blue : Colors.grey,
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (isCurrentUser) const SizedBox(width: 8),
//         ],
//       ),
//     );
//   }

//   Widget _buildOfferBanner() {
//     if (_currentChat.offers.isEmpty) return const SizedBox();

//     // Find the latest pending offer
//     final pendingOffers = _currentChat.offers
//         .where((offer) => offer.isPending)
//         .toList();

//     if (pendingOffers.isEmpty) return const SizedBox();

//     final latestOffer = pendingOffers.last;
//     final isIncoming = latestOffer.madeById != widget.currentUserId;

//     if (!isIncoming) return const SizedBox();

//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.request_page, color: Colors.blue.shade700),
//               const SizedBox(width: 8),
//               Text(
//                 'Pending Offer',
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.blue.shade700,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),

//           if (latestOffer.isPriceOffer) ...[
//             Text(
//               'Price: ${latestOffer.currency ?? '\$'} ${latestOffer.price!.toStringAsFixed(2)}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ] else if (latestOffer.isBarterOffer) ...[
//             Text(
//               'Item: ${latestOffer.barterItemTitle ?? 'Unknown'}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//             if (latestOffer.barterItemDescription != null)
//               Text(
//                 latestOffer.barterItemDescription!,
//                 style: const TextStyle(fontSize: 12),
//               ),
//           ],

//           const SizedBox(height: 12),

//           Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => _rejectOffer(latestOffer),
//                   style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
//                   child: const Text('Reject'),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => _acceptOffer(latestOffer),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                   ),
//                   child: const Text('Accept'),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMyOfferBanner() {
//     if (_currentChat.offers.isEmpty) return const SizedBox();

//     // Find the latest pending offer made by current user
//     final myPendingOffers = _currentChat.offers
//         .where(
//           (offer) => offer.isPending && offer.madeById == widget.currentUserId,
//         )
//         .toList();

//     if (myPendingOffers.isEmpty) return const SizedBox();

//     final latestOffer = myPendingOffers.last;

//     return Container(
//       margin: const EdgeInsets.all(16),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.orange.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Row(
//                 children: [
//                   Icon(Icons.access_time, color: Colors.orange.shade700),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Your Pending Offer',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       color: Colors.orange.shade700,
//                     ),
//                   ),
//                 ],
//               ),
//               IconButton(
//                 icon: const Icon(Icons.close, size: 20),
//                 onPressed: () => _withdrawOffer(latestOffer),
//                 tooltip: 'Withdraw Offer',
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),

//           if (latestOffer.isPriceOffer) ...[
//             Text(
//               'Price: ${latestOffer.currency ?? '\$'} ${latestOffer.price!.toStringAsFixed(2)}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//           ] else if (latestOffer.isBarterOffer) ...[
//             Text(
//               'Item: ${latestOffer.barterItemTitle ?? 'Unknown'}',
//               style: const TextStyle(fontWeight: FontWeight.w500),
//             ),
//             if (latestOffer.barterItemDescription != null)
//               Text(
//                 latestOffer.barterItemDescription!,
//                 style: const TextStyle(fontSize: 12),
//               ),
//           ],
//         ],
//       ),
//     );
//   }

//   void _showMoreOptions() {
//     final otherUser = _getOtherUser();

//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//       ),
//       builder: (context) => Container(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text(
//               'More Options',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),

//             if (_currentChat.isActive) ...[
//               ListTile(
//                 leading: const Icon(Icons.check_circle, color: Colors.green),
//                 title: const Text('Complete Trade'),
//                 subtitle: const Text('Mark this trade as completed'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _completeTrade();
//                 },
//               ),
//               const Divider(),
//             ],

//             if (_currentChat.isActive || _currentChat.isCompleted) ...[
//               ListTile(
//                 leading: const Icon(Icons.archive, color: Colors.blue),
//                 title: const Text('Archive Chat'),
//                 subtitle: const Text('Move this chat to archive'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _archiveChat();
//                 },
//               ),
//               const Divider(),
//             ],

//             if (_currentChat.isActive) ...[
//               ListTile(
//                 leading: const Icon(Icons.cancel, color: Colors.orange),
//                 title: const Text('Cancel Trade'),
//                 subtitle: const Text('Cancel this trade negotiation'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _cancelTrade();
//                 },
//               ),
//               const Divider(),
//             ],

//             ListTile(
//               leading: const Icon(Icons.block, color: Colors.red),
//               title: const Text('Block User'),
//               subtitle: Text('Block ${otherUser.firstName}'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _blockUser();
//               },
//             ),
//             const Divider(),

//             ListTile(
//               leading: const Icon(Icons.report, color: Colors.orange),
//               title: const Text('Report User'),
//               subtitle: Text('Report ${otherUser.firstName}'),
//               onTap: () {
//                 Navigator.pop(context);
//                 _reportUser();
//               },
//             ),

//             const SizedBox(height: 20),

//             OutlinedButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Cancel'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _blockUser() {
//     final otherUser = _getOtherUser();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Block User'),
//         content: Text(
//           'Are you sure you want to block ${otherUser.firstName}?\n\n'
//           'You will no longer receive messages or offers from them.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text('${otherUser.firstName} has been blocked.'),
//                 ),
//               );
//               Navigator.pop(context); // Close chat screen
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//             child: const Text('Block'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _reportUser() {
//     final otherUser = _getOtherUser();

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Report User'),
//         content: Text(
//           'Are you sure you want to report ${otherUser.firstName}?\n\n'
//           'Our team will review this report.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(
//                   content: Text('User reported. Thank you for your feedback.'),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//             child: const Text('Report'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final otherUser = _getOtherUser();

//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: otherUser.profileImage != null
//                   ? NetworkImage(otherUser.profileImage!)
//                   : null,
//               child: otherUser.profileImage == null
//                   ? Text(otherUser.firstName[0].toUpperCase())
//                   : null,
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(otherUser.firstName),
//                 Text(
//                   _currentChat.isActive ? 'Active' : 'Inactive',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.more_vert),
//             onPressed: _showMoreOptions,
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: LoadingWidget())
//           : Column(
//               children: [
//                 // Product/Service Info Banner
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   color: Colors.grey.shade50,
//                   child: Row(
//                     children: [
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(8),
//                         child: _currentChat.postImage.isNotEmpty
//                             ? Image.network(
//                                 _currentChat.postImage,
//                                 width: 60,
//                                 height: 60,
//                                 fit: BoxFit.cover,
//                                 errorBuilder: (context, error, stackTrace) {
//                                   return Container(
//                                     width: 60,
//                                     height: 60,
//                                     color: Colors.grey.shade300,
//                                     child: const Icon(
//                                       Icons.image_not_supported,
//                                     ),
//                                   );
//                                 },
//                               )
//                             : Container(
//                                 width: 60,
//                                 height: 60,
//                                 color: Colors.grey.shade300,
//                                 child: const Icon(Icons.image),
//                               ),
//                       ),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               _currentChat.postTitle,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 14,
//                               ),
//                               maxLines: 2,
//                               overflow: TextOverflow.ellipsis,
//                             ),
//                             const SizedBox(height: 4),
//                             Container(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 8,
//                                 vertical: 2,
//                               ),
//                               decoration: BoxDecoration(
//                                 color: _getOfferTypeColor(
//                                   _currentChat.offerType,
//                                 ),
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               child: Text(
//                                 _currentChat.offerType,
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Offer Banners
//                 _buildOfferBanner(),
//                 _buildMyOfferBanner(),

//                 // Messages
//                 Expanded(
//                   child: ListView.builder(
//                     controller: _scrollController,
//                     padding: const EdgeInsets.all(8),
//                     itemCount: _messages.length,
//                     itemBuilder: (context, index) {
//                       return _buildMessageBubble(_messages[index]);
//                     },
//                   ),
//                 ),

//                 // Message Input
//                 if (_currentChat.isActive) _buildMessageInput(),
//               ],
//             ),
//     );
//   }

//   Color _getOfferTypeColor(String offerType) {
//     switch (offerType) {
//       case 'Product':
//         return Colors.orange;
//       case 'Service':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }

//   Widget _buildMessageInput() {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Colors.grey.shade200)),
//       ),
//       child: Row(
//         children: [
//           // Attach Image Button
//           IconButton(
//             icon: const Icon(Icons.image, color: Colors.blue),
//             onPressed: _isSendingImage ? null : _pickAndSendImage,
//           ),

//           // Make Offer Button
//           IconButton(
//             icon: const Icon(Icons.request_page, color: Colors.orange),
//             onPressed: _showMakeOfferDialog,
//           ),

//           // Text Field
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               decoration: InputDecoration(
//                 hintText: 'Type a message...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(25),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey.shade100,
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//               ),
//               onSubmitted: (_) => _sendMessage(),
//             ),
//           ),

//           // Send Button
//           IconButton(
//             icon: _isSendingImage
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   )
//                 : const Icon(Icons.send, color: Colors.blue),
//             onPressed: _isSendingImage ? null : _sendMessage,
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:Yempover_app/models/chats/trade_chat.dart';
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

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TradeChatService _chatService = TradeChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  late TradeChat _currentChat;
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isSendingImage = false;
  bool _isShowingDealCompletionDialog = false;

  @override
  void initState() {
    super.initState();
    _currentChat = widget.chat;
    _messages = List.from(_currentChat.messages);
    _markMessagesAsRead();
    _scrollToBottom();
    _refreshChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(_currentChat.id);
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    // Optimistically add message
    final tempMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      tradeChatId: _currentChat.id,
      sentById: widget.currentUserId,
      messageText: content,
      messageType: MessageType.TEXT,
      isRead: false,
      createdAt: DateTime.now(),
      sentBy: null,
      imageUrl: null,
      readAt: null,
      offerId: null,
    );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();

    try {
      final sentMessage = await _chatService.sendMessage(
        chatId: _currentChat.id,
        messageText: content,
        content: '',
      );

      // Replace temp message with actual
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage;
        }
      });

      // Update last message in chat
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

      widget.onChatUpdated(_currentChat);
    } catch (e) {
      // Show error and remove temp message
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

      // Optimistically add a loading message
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: widget.currentUserId,
        messageText: 'Sending image...',
        messageType: MessageType.IMAGE,
        isRead: false,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
        offerId: null,
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

      // Replace temp message with actual
      setState(() {
        final index = _messages.indexWhere((m) => m.id == tempMessage.id);
        if (index != -1) {
          _messages[index] = sentMessage;
        }
        _isSendingImage = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSendingImage = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showMakeOfferDialog() async {
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

  Future<void> _createPriceOffer({
    required double price,
    required String currency,
  }) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offer = await _chatService.createPriceOffer(
        chatId: _currentChat.id,
        price: price,
        currency: currency,
      );

      // Add offer as a system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText:
            'Price offer created: \$${price.toStringAsFixed(2)} $currency',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
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
            content: Text('Failed to create offer: $e'),
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
    setState(() {
      _isLoading = true;
    });

    try {
      final offer = await _chatService.createBarterOffer(
        chatId: _currentChat.id,
        barterItemTitle: title,
        barterItemDescription: description,
      );

      // Add offer as a system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Barter offer created: $title',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
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
            content: Text('Failed to create offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Updated accept offer method to use the new detailed API
  Future<void> _acceptOffer(TradeOffer offer) async {
    // Check if we need to show counter offer dialog for barter offers
    if (offer.isBarterOffer &&
        _currentChat.canCompleteDeal(widget.currentUserId)) {
      _showCounterOfferDialog(offer);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final acceptedOffer = await _chatService.acceptOfferWithDetails(
        chatId: _currentChat.id,
        offerId: offer.id,
        offerType: offer.offerType.value,
        price: offer.price,
        currency: offer.currency,
        barterItemTitle: offer.barterItemTitle,
        barterItemDescription: offer.barterItemDescription,
        barterItemImages: offer.barterItemImages,
        barterWishCategories: offer.barterWishCategories,
      );

      // Add system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Offer accepted',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
        offerId: acceptedOffer.id,
      );

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _currentChat.offers[index] = acceptedOffer;
        }
        _messages.add(systemMessage);
        _isLoading = false;
      });

      // Refresh chat to get updated status
      await _refreshChat();
      _scrollToBottom();
      widget.onChatUpdated(_currentChat);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to accept offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // New method for counter offers
  Future<void> _showCounterOfferDialog(TradeOffer originalOffer) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Counter Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (originalOffer.isPriceOffer) ...[
              const Text('Modify your price offer'),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(
                  text: originalOffer.price?.toString(),
                ),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'New Price',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {},
              ),
            ] else ...[
              const Text('Modify your barter offer'),
              const SizedBox(height: 16),
              TextField(
                controller: TextEditingController(
                  text: originalOffer.barterItemTitle,
                ),
                decoration: const InputDecoration(
                  labelText: 'Item Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(
                  text: originalOffer.barterItemDescription,
                ),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, {'type': 'counter'}),
            child: const Text('Send Counter Offer'),
          ),
        ],
      ),
    );

    if (result != null && result['type'] == 'counter') {
      await _createCounterOffer(originalOffer);
    }
  }

  // New method to create counter offer
  Future<void> _createCounterOffer(TradeOffer originalOffer) async {
    setState(() {
      _isLoading = true;
    });

    try {
      double? newPrice;
      String? newTitle;
      String? newDescription;

      if (originalOffer.isPriceOffer) {
        // In a real implementation, you would get these from dialog inputs
        newPrice = (originalOffer.price ?? 0) * 0.9; // Example: 10% less
      } else {
        newTitle = originalOffer.barterItemTitle;
        newDescription = originalOffer.barterItemDescription;
      }

      final counterOffer = await _chatService.createCounterOffer(
        chatId: _currentChat.id,
        offerId: originalOffer.id,
        offerType: originalOffer.offerType.value,
        price: newPrice,
        currency: originalOffer.currency,
        barterItemTitle: newTitle,
        barterItemDescription: newDescription,
        barterItemImages: originalOffer.barterItemImages,
        barterWishCategories: originalOffer.barterWishCategories,
      );

      // Add system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Counter offer created',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
        offerId: counterOffer.id,
      );

      setState(() {
        _currentChat.offers.add(counterOffer);
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
            content: Text('Failed to create counter offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Updated reject offer method to use the new detailed API
  Future<void> _rejectOffer(TradeOffer offer) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final rejectedOffer = await _chatService.rejectOfferWithDetails(
        chatId: _currentChat.id,
        offerId: offer.id,
        offerType: offer.offerType.value,
        price: offer.price,
        currency: offer.currency,
        barterItemTitle: offer.barterItemTitle,
        barterItemDescription: offer.barterItemDescription,
        barterItemImages: offer.barterItemImages,
        barterWishCategories: offer.barterWishCategories,
      );

      // Add system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Offer rejected',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
        offerId: rejectedOffer.id,
      );

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _currentChat.offers[index] = rejectedOffer;
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
            content: Text('Failed to reject offer: $e'),
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
      final withdrawnOffer = await _chatService.withdrawOffer(offer.id);

      // Add system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Offer withdrawn',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
        offerId: withdrawnOffer.id,
      );

      setState(() {
        final index = _currentChat.offers.indexWhere((o) => o.id == offer.id);
        if (index != -1) {
          _currentChat.offers[index] = withdrawnOffer;
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
            content: Text('Failed to withdraw offer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Updated complete trade method to use the new deal completion API
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
      final completedChat = await _chatService.markDealCompleted(
        chatId: _currentChat.id,
        remarks: result['remarks'] ?? '',
      );

      // Add system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: result['isCompleted'] == true
            ? 'Deal completed successfully'
            : 'Deal marked as not completed',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
        offerId: null,
      );

      setState(() {
        _currentChat = completedChat;
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
            content: Text('Failed to complete deal: $e'),
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

      // Add system message
      final systemMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        tradeChatId: _currentChat.id,
        sentById: 'system',
        messageText: 'Trade cancelled',
        messageType: MessageType.SYSTEM,
        isRead: true,
        createdAt: DateTime.now(),
        sentBy: null,
        imageUrl: null,
        readAt: null,
        offerId: null,
      );

      setState(() {
        _currentChat = cancelledChat;
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
            content: Text('Failed to cancel trade: $e'),
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
            content: Text('Failed to archive chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // New method to block user
  Future<void> _blockUser() async {
    final otherUser = _getOtherUser();

    // Check if there's an open accepted deal
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
        Navigator.pop(context); // Close chat screen
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: $e'),
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
                        // Show full screen image
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

    // Find the latest pending offer
    final pendingOffers = _currentChat.offers
        .where((offer) => offer.isPending)
        .toList();

    if (pendingOffers.isEmpty) return const SizedBox();

    final latestOffer = pendingOffers.last;
    final isIncoming = latestOffer.madeById != widget.currentUserId;

    if (!isIncoming) return const SizedBox();

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
                'Pending Offer',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
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
          ] else if (latestOffer.isBarterOffer) ...[
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

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectOffer(latestOffer),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptOffer(latestOffer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyOfferBanner() {
    if (_currentChat.offers.isEmpty) return const SizedBox();

    // Find the latest pending offer made by current user
    final myPendingOffers = _currentChat.offers
        .where(
          (offer) => offer.isPending && offer.madeById == widget.currentUserId,
        )
        .toList();

    if (myPendingOffers.isEmpty) return const SizedBox();

    final latestOffer = myPendingOffers.last;

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
                    'Your Pending Offer',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _withdrawOffer(latestOffer),
                tooltip: 'Withdraw Offer',
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (latestOffer.isPriceOffer) ...[
            Text(
              'Price: ${latestOffer.currency ?? '\$'} ${latestOffer.price!.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ] else if (latestOffer.isBarterOffer) ...[
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

  // New widget for deal completion banner
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
              SizedBox(width: 8),
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
                  _currentChat.isActive ? 'Active' : 'Inactive',
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
      body: _isLoading
          ? const Center(child: LoadingWidget())
          : Column(
              children: [
                // Product/Service Info Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade50,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _currentChat.postImage.isNotEmpty
                            ? Image.network(
                                _currentChat.postImage,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade300,
                                    child: const Icon(
                                      Icons.image_not_supported,
                                    ),
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentChat.postTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getOfferTypeColor(
                                  _currentChat.offerType,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                _currentChat.offerType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Offer Banners
                _buildOfferBanner(),
                _buildMyOfferBanner(),
                _buildDealCompletionBanner(),

                // Messages
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
                ),

                // Message Input
                if (_currentChat.isActive) _buildMessageInput(),
              ],
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Attach Image Button
          IconButton(
            icon: const Icon(Icons.image, color: Colors.blue),
            onPressed: _isSendingImage ? null : _pickAndSendImage,
          ),

          // Make Offer Button
          IconButton(
            icon: const Icon(Icons.request_page, color: Colors.orange),
            onPressed: _showMakeOfferDialog,
          ),

          // Text Field
          Expanded(
            child: TextField(
              controller: _messageController,
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
              onSubmitted: (_) => _sendMessage(),
            ),
          ),

          // Send Button
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
    );
  }
}

// New Deal Completion Dialog Widget
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
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Deal'),
      content: SingleChildScrollView(
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
            Row(
              children: [
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Deal Completed'),
                    value: true,
                    groupValue: _isDealCompleted,
                    onChanged: (value) {
                      setState(() {
                        _isDealCompleted = value ?? true;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<bool>(
                    title: const Text('Deal Not Completed'),
                    value: false,
                    groupValue: _isDealCompleted,
                    onChanged: (value) {
                      setState(() {
                        _isDealCompleted = value ?? false;
                      });
                    },
                  ),
                ),
              ],
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
