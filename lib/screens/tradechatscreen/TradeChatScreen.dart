// import 'package:flutter/material.dart';
// import 'package:yempover_app/models/TradeChat.dart';
// import 'package:intl/intl.dart';

// class TradeChatScreen extends StatefulWidget {
//   const TradeChatScreen({super.key});

//   @override
//   _TradeChatScreenState createState() => _TradeChatScreenState();
// }

// Color _getOfferTypeColor(String offerType) {
//   switch (offerType) {
//     case 'Barter':
//       return Colors.orange;
//     case 'Price':
//       return Colors.blue;
//     case 'Both':
//       return Colors.purple;
//     default:
//       return Colors.grey;
//   }
// }

// class _TradeChatScreenState extends State<TradeChatScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   List<TradeChat> _allChats = [];
//   List<TradeChat> _inboxChats = [];
//   List<TradeChat> _outboxChats = [];
//   List<String> _userProducts = [];
//   String? _selectedProductFilter;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _loadChats();
//     _loadUserProducts();
//   }

//   void _loadChats() {
//     // Sample data - Replace with actual API call
//     _allChats = [
//       TradeChat(
//         id: '1',
//         otherUserId: 'user1',
//         otherUserName: 'Melia K',
//         otherUserProfileImage: 'https://i.pravatar.cc/150?img=1',
//         postId: 'post1',
//         postTitle: 'Sofa - Mint Condition',
//         postImage:
//             'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
//         offerType: 'Barter',
//         messages: [
//           ChatMessage(
//             id: 'msg1',
//             senderId: 'user1',
//             message: 'Hi! I would like to swap with my Mobile and Speaker',
//             timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
//             isOffer: true,
//           ),
//           ChatMessage(
//             id: 'msg2',
//             senderId: 'current_user',
//             message: 'I want to need one more item',
//             timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
//           ),
//           ChatMessage(
//             id: 'msg3',
//             senderId: 'user1',
//             message: 'I agree with this case',
//             timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
//             isOffer: true,
//           ),
//         ],
//         lastInteraction: DateTime.now().subtract(const Duration(minutes: 20)),
//         isActive: true,
//         isOfferIncoming: true,
//         offerStatus: 'pending',
//         barterItems: [
//           OfferedItem(
//             id: 'item1',
//             title: 'iPhone 13 Pro',
//             image:
//                 'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=500&q=80',
//             category: 'Electronics',
//             value: 800,
//             condition: 'Excellent',
//           ),
//           OfferedItem(
//             id: 'item2',
//             title: 'Bluetooth Speaker',
//             image:
//                 'https://images.unsplash.com/photo-1608043152269-423dbba4e7e1?w=500&q=80',
//             category: 'Electronics',
//             value: 100,
//             condition: 'Good',
//           ),
//         ],
//       ),
//       TradeChat(
//         id: '2',
//         otherUserId: 'user2',
//         otherUserName: 'Andrew Danny',
//         otherUserProfileImage: 'https://i.pravatar.cc/150?img=2',
//         postId: 'post2',
//         postTitle: 'Television 55" Smart TV',
//         postImage:
//             'https://images.unsplash.com/photo-1593359677879-a4bb92f829d1?w=500&q=80',
//         offerType: 'Both',
//         messages: [
//           ChatMessage(
//             id: 'msg4',
//             senderId: 'current_user',
//             message: 'Interested in your TV. I can offer \$400 or my Laptop',
//             timestamp: DateTime.now().subtract(const Duration(hours: 2)),
//             isOffer: true,
//           ),
//         ],
//         lastInteraction: DateTime.now().subtract(const Duration(hours: 2)),
//         isActive: true,
//         isOfferIncoming: false,
//         offerStatus: 'pending',
//         priceOffer: 400,
//         barterItems: [
//           OfferedItem(
//             id: 'item3',
//             title: 'Gaming Laptop',
//             image:
//                 'https://images.unsplash.com/photo-1603302576837-37561b2e2302?w=500&q=80',
//             category: 'Electronics',
//             value: 1200,
//             condition: 'Like New',
//           ),
//         ],
//       ),
//       TradeChat(
//         id: '3',
//         otherUserId: 'user3',
//         otherUserName: 'Sarah Johnson',
//         otherUserProfileImage: 'https://i.pravatar.cc/150?img=3',
//         postId: 'post3',
//         postTitle: 'Tap Repairing Service',
//         postImage:
//             'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&q=80',
//         offerType: 'Price',
//         messages: [
//           ChatMessage(
//             id: 'msg5',
//             senderId: 'user3',
//             message: 'I accept your offer of \$100 for the service',
//             timestamp: DateTime.now().subtract(const Duration(days: 1)),
//             isOffer: true,
//           ),
//         ],
//         lastInteraction: DateTime.now().subtract(const Duration(days: 1)),
//         isActive: false,
//         isOfferIncoming: true,
//         isAccepted: true,
//         offerStatus: 'accepted',
//         priceOffer: 100,
//       ),
//     ];

//     _updateFilteredChats();
//   }

//   void _loadUserProducts() {
//     // Sample user products for filtering
//     _userProducts = [
//       'All Products',
//       'Sofa - Mint Condition',
//       'iPhone 13 Pro',
//       'Gaming Laptop',
//       'Bluetooth Speaker',
//     ];
//   }

//   void _updateFilteredChats() {
//     setState(() {
//       _inboxChats = _allChats.where((chat) => chat.isOfferIncoming).toList();
//       _outboxChats = _allChats.where((chat) => !chat.isOfferIncoming).toList();
//     });
//   }

//   List<TradeChat> _getFilteredInboxChats() {
//     if (_selectedProductFilter == null ||
//         _selectedProductFilter == 'All Products') {
//       return _inboxChats;
//     }
//     return _inboxChats
//         .where((chat) => chat.postTitle == _selectedProductFilter)
//         .toList();
//   }

//   void _showProductFilterDialog() {
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
//               'Filter by Your Product',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             ..._userProducts.map((product) {
//               return ListTile(
//                 title: Text(product),
//                 trailing: _selectedProductFilter == product
//                     ? const Icon(Icons.check, color: Colors.blue)
//                     : null,
//                 onTap: () {
//                   setState(() {
//                     _selectedProductFilter = product;
//                   });
//                   Navigator.pop(context);
//                 },
//               );
//             }).toList(),
//             const SizedBox(height: 20),
//             OutlinedButton(
//               onPressed: () {
//                 setState(() {
//                   _selectedProductFilter = null;
//                 });
//                 Navigator.pop(context);
//               },
//               child: const Text('Clear Filter'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _openChatDetail(TradeChat chat) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => ChatDetailScreen(
//           chat: chat,
//           onChatUpdated: (updatedChat) {
//             _updateChat(updatedChat);
//           },
//         ),
//       ),
//     );
//   }

//   void _updateChat(TradeChat updatedChat) {
//     setState(() {
//       final index = _allChats.indexWhere((c) => c.id == updatedChat.id);
//       if (index != -1) {
//         _allChats[index] = updatedChat;
//         _updateFilteredChats();
//       }
//     });
//   }

//   Widget _buildChatItem(TradeChat chat) {
//     return InkWell(
//       onTap: () => _openChatDetail(chat),
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             // User profile with online status
//             Stack(
//               children: [
//                 CircleAvatar(
//                   radius: 28,
//                   backgroundImage: NetworkImage(chat.otherUserProfileImage),
//                 ),
//                 if (chat.isActive)
//                   Positioned(
//                     right: 0,
//                     bottom: 0,
//                     child: Container(
//                       width: 14,
//                       height: 14,
//                       decoration: BoxDecoration(
//                         color: Colors.green,
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(width: 12),

//             // Chat details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         chat.otherUserName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Text(
//                         chat.formattedDate,
//                         style: const TextStyle(
//                           color: Colors.grey,
//                           fontSize: 12,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     chat.postTitle,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       color: Colors.black87,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),

//                   // Offer type and status
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: _getOfferTypeColor(chat.offerType),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(
//                           chat.offerType,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       if (!chat.isActive)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade200,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Text(
//                             'Inactive',
//                             style: TextStyle(
//                               color: Colors.grey,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ),
//                       if (chat.isAccepted)
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                             horizontal: 8,
//                             vertical: 2,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.green.shade100,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: const Text(
//                             'Accepted',
//                             style: TextStyle(
//                               color: Colors.green,
//                               fontSize: 10,
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),

//                   // Last message preview
//                   const SizedBox(height: 8),
//                   Text(
//                     chat.messages.isNotEmpty
//                         ? chat.messages.last.message
//                         : 'No messages',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       color: Colors.grey,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),

//             // Post image
//             const SizedBox(width: 12),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(8),
//               child: Image.network(
//                 chat.postImage,
//                 width: 60,
//                 height: 60,
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Color _getOfferTypeColor(String offerType) {
//     switch (offerType) {
//       case 'Barter':
//         return Colors.orange;
//       case 'Price':
//         return Colors.blue;
//       case 'Both':
//         return Colors.purple;
//       default:
//         return Colors.grey;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Trade Chat'),
//         bottom: TabBar(
//           controller: _tabController,
//           tabs: const [
//             Tab(text: 'All Chats'),
//             Tab(text: 'Offers Inbox'),
//             Tab(text: 'Offers Outbox'),
//           ],
//           labelStyle: const TextStyle(fontWeight: FontWeight.bold),
//           indicatorSize: TabBarIndicatorSize.tab,
//           indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
//         ),
//       ),
//       body: TabBarView(
//         controller: _tabController,
//         children: [
//           // All Chats Tab
//           _allChats.isEmpty
//               ? const Center(
//                   child: Text(
//                     'No chats yet',
//                     style: TextStyle(color: Colors.grey, fontSize: 16),
//                   ),
//                 )
//               : ListView.builder(
//                   padding: const EdgeInsets.only(top: 16),
//                   itemCount: _allChats.length,
//                   itemBuilder: (context, index) {
//                     return _buildChatItem(_allChats[index]);
//                   },
//                 ),

//           // Offers Inbox Tab
//           Column(
//             children: [
//               // Filter button
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: OutlinedButton.icon(
//                         onPressed: _showProductFilterDialog,
//                         icon: const Icon(Icons.filter_list, size: 20),
//                         label: Text(
//                           _selectedProductFilter ?? 'Filter by Your Product',
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         style: OutlinedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(
//                             vertical: 12,
//                             horizontal: 16,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Inbox chats list
//               Expanded(
//                 child: _getFilteredInboxChats().isEmpty
//                     ? const Center(
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.inbox,
//                               size: 64,
//                               color: Colors.grey,
//                             ),
//                             SizedBox(height: 16),
//                             Text(
//                               'No incoming offers',
//                               style: TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 18,
//                               ),
//                             ),
//                             SizedBox(height: 8),
//                             Text(
//                               'When someone makes an offer on your items,\n they will appear here',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(
//                                 color: Colors.grey,
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                     : ListView.builder(
//                         padding: const EdgeInsets.only(bottom: 16),
//                         itemCount: _getFilteredInboxChats().length,
//                         itemBuilder: (context, index) {
//                           return _buildChatItem(
//                             _getFilteredInboxChats()[index],
//                           );
//                         },
//                       ),
//               ),
//             ],
//           ),

//           // Offers Outbox Tab
//           _outboxChats.isEmpty
//               ? const Center(
//                   child: Text(
//                     'No outgoing offers',
//                     style: TextStyle(color: Colors.grey, fontSize: 16),
//                   ),
//                 )
//               : ListView.builder(
//                   padding: const EdgeInsets.only(top: 16),
//                   itemCount: _outboxChats.length,
//                   itemBuilder: (context, index) {
//                     return _buildChatItem(_outboxChats[index]);
//                   },
//                 ),
//         ],
//       ),
//     );
//   }
// }

// // Chat Detail Screen
// class ChatDetailScreen extends StatefulWidget {
//   final TradeChat chat;
//   final Function(TradeChat) onChatUpdated;

//   const ChatDetailScreen({
//     super.key,
//     required this.chat,
//     required this.onChatUpdated,
//   });

//   @override
//   _ChatDetailScreenState createState() => _ChatDetailScreenState();
// }

// class _ChatDetailScreenState extends State<ChatDetailScreen> {
//   final TextEditingController _messageController = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   bool _showEmojiPicker = false;
//   List<ChatMessage> _messages = [];
//   TradeChat? _currentChat;

//   @override
//   void initState() {
//     super.initState();
//     _currentChat = widget.chat;
//     _messages = List.from(_currentChat!.messages);
//   }

//   void _sendMessage() {
//     if (_messageController.text.trim().isEmpty) return;

//     final newMessage = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       senderId: 'current_user',
//       message: _messageController.text.trim(),
//       timestamp: DateTime.now(),
//     );

//     setState(() {
//       _messages.add(newMessage);
//       _messageController.clear();
//       _showEmojiPicker = false;
//     });

//     _scrollToBottom();
//   }

//   void _sendOffer() {
//     // Navigate to Offer Deck screen
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => const OfferDeckScreen(),
//       ),
//     ).then((offer) {
//       if (offer != null) {
//         _addOfferMessage(offer);
//       }
//     });
//   }

//   void _addOfferMessage(dynamic offer) {
//     final offerMessage = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       senderId: 'current_user',
//       message: 'New offer sent',
//       timestamp: DateTime.now(),
//       isOffer: true,
//     );

//     setState(() {
//       _messages.add(offerMessage);
//     });

//     _scrollToBottom();
//   }

//   void _viewOfferDetails(OfferedItem item) {
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
//             ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: Image.network(
//                 item.image,
//                 width: double.infinity,
//                 height: 200,
//                 fit: BoxFit.cover,
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               item.title,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Category: ${item.category}',
//               style: const TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 10),
//             if (item.value != null)
//               Text(
//                 'Value: \$${item.value!.toStringAsFixed(2)}',
//                 style: const TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.green,
//                 ),
//               ),
//             const SizedBox(height: 10),
//             Text(
//               'Condition: ${item.condition}',
//               style: const TextStyle(color: Colors.grey),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () => Navigator.pop(context),
//               child: const Text('Close'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _makeCounterOffer() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OfferDeckScreen(
//           initialOffer: _currentChat,
//         ),
//       ),
//     ).then((counterOffer) {
//       if (counterOffer != null) {
//         _addCounterOfferMessage(counterOffer);
//       }
//     });
//   }

//   void _addCounterOfferMessage(dynamic counterOffer) {
//     final counterMessage = ChatMessage(
//       id: DateTime.now().millisecondsSinceEpoch.toString(),
//       senderId: 'current_user',
//       message: 'Counter offer made',
//       timestamp: DateTime.now(),
//       isOffer: true,
//     );

//     setState(() {
//       _messages.add(counterMessage);
//       _currentChat = _currentChat?.copyWith(
//         offerStatus: 'countered',
//         counterOfferId: DateTime.now().millisecondsSinceEpoch.toString(),
//       );
//     });

//     _scrollToBottom();
//   }

//   void _acceptOffer() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Accept Offer'),
//         content: const Text(
//           'Are you sure you want to accept this offer?\n\n'
//           'Accepting will automatically reject other open offers and make '
//           'the products unavailable in the marketplace.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _handleAcceptOffer();
//             },
//             child: const Text('Accept'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleAcceptOffer() {
//     setState(() {
//       _currentChat = _currentChat?.copyWith(
//         isAccepted: true,
//         isActive: false,
//         offerStatus: 'accepted',
//       );
//     });

//     _updateChat();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Offer accepted successfully!'),
//         duration: Duration(seconds: 3),
//       ),
//     );
//   }

//   void _rejectOffer() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Reject Offer'),
//         content: const Text(
//           'Are you sure you want to reject this offer?\n\n'
//           'Rejecting will end the conversation and no further chats or offers '
//           'can be made.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _handleRejectOffer();
//             },
//             child: const Text('Reject'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleRejectOffer() {
//     setState(() {
//       _currentChat = _currentChat?.copyWith(
//         isRejected: true,
//         isActive: false,
//         offerStatus: 'rejected',
//       );
//     });

//     _updateChat();

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(
//         content: Text('Offer rejected. Chat is now inactive.'),
//         duration: Duration(seconds: 3),
//       ),
//     );
//   }

//   void _completeDeal() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => CompleteDealScreen(
//           chat: _currentChat!,
//           onDealCompleted: () {
//             setState(() {
//               _currentChat = _currentChat?.copyWith(
//                 dealCompletedByMe: true,
//               );
//               if (_currentChat?.dealCompletedByOther == true) {
//                 _currentChat = _currentChat?.copyWith(
//                   isActive: false,
//                 );
//               }
//             });
//             _updateChat();
//           },
//         ),
//       ),
//     );
//   }

//   void _blockUser() {
//     if (!_currentChat!.canBlock) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text(
//             'Cannot block user while there is an open accepted deal.',
//           ),
//           duration: Duration(seconds: 3),
//         ),
//       );
//       return;
//     }

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Block User'),
//         content: const Text(
//           'Are you sure you want to block this user?\n\n'
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
//               _handleBlockUser();
//             },
//             child: const Text('Block'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _handleBlockUser() {
//     // Implement block user logic
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('${_currentChat!.otherUserName} has been blocked.'),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//     Navigator.pop(context);
//   }

//   void _updateChat() {
//     if (_currentChat != null) {
//       widget.onChatUpdated(_currentChat!);
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

//   Widget _buildMessageBubble(ChatMessage message) {
//     final isCurrentUser = message.senderId == 'current_user';
//     final isOffer = message.isOffer;

//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       child: Row(
//         mainAxisAlignment:
//             isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         children: [
//           if (!isCurrentUser)
//             CircleAvatar(
//               radius: 16,
//               backgroundImage:
//                   NetworkImage(_currentChat!.otherUserProfileImage),
//             ),
//           const SizedBox(width: 8),
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: isCurrentUser
//                     ? Colors.blue.shade100
//                     : Colors.grey.shade100,
//                 borderRadius: BorderRadius.circular(16),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (isOffer)
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           '📦 Offer Made',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         if (_currentChat!.priceOffer != null)
//                           Text(
//                             'Price: \$${_currentChat!.priceOffer!.toStringAsFixed(2)}',
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         if (_currentChat!.barterItems != null &&
//                             _currentChat!.barterItems!.isNotEmpty)
//                           ..._currentChat!.barterItems!.map((item) {
//                             return InkWell(
//                               onTap: () => _viewOfferDetails(item),
//                               child: Container(
//                                 margin: const EdgeInsets.only(top: 4),
//                                 padding: const EdgeInsets.all(8),
//                                 decoration: BoxDecoration(
//                                   border: Border.all(color: Colors.blue),
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     ClipRRect(
//                                       borderRadius: BorderRadius.circular(4),
//                                       child: Image.network(
//                                         item.image,
//                                         width: 40,
//                                         height: 40,
//                                         fit: BoxFit.cover,
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Text(
//                                             item.title,
//                                             style: const TextStyle(
//                                               fontWeight: FontWeight.bold,
//                                             ),
//                                           ),
//                                           Text(
//                                             item.category,
//                                             style: const TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         const Divider(),
//                       ],
//                     ),
//                   Text(message.message),
//                   const SizedBox(height: 4),
//                   Text(
//                     DateFormat('h:mm a').format(message.timestamp),
//                     style: const TextStyle(
//                       fontSize: 10,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (isCurrentUser) const SizedBox(width: 8),
//           if (isCurrentUser)
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: NetworkImage(
//                   'https://i.pravatar.cc/150?img=11'), // Current user image
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildActionButtons() {
//     if (!_currentChat!.canChat) {
//       return Container();
//     }

//     if (_currentChat!.isOfferIncoming && !_currentChat!.isAccepted) {
//       return Row(
//         children: [
//           Expanded(
//             child: OutlinedButton.icon(
//               onPressed: _makeCounterOffer,
//               icon: const Icon(Icons.countertops),
//               label: const Text('Make Counter Offer'),
//               style: OutlinedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: OutlinedButton.icon(
//               onPressed: _rejectOffer,
//               icon: const Icon(Icons.close, color: Colors.red),
//               label: const Text(
//                 'Reject',
//                 style: TextStyle(color: Colors.red),
//               ),
//               style: OutlinedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//           const SizedBox(width: 10),
//           Expanded(
//             child: ElevatedButton.icon(
//               onPressed: _acceptOffer,
//               icon: const Icon(Icons.check),
//               label: const Text('Accept'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 padding: const EdgeInsets.symmetric(vertical: 12),
//               ),
//             ),
//           ),
//         ],
//       );
//     } else if (_currentChat!.isAccepted && !_currentChat!.dealCompletedByMe) {
//       return ElevatedButton.icon(
//         onPressed: _completeDeal,
//         icon: const Icon(Icons.handshake),
//         label: const Text('Deal Completed'),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Colors.green,
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
//         ),
//       );
//     }

//     return Container();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: NetworkImage(_currentChat!.otherUserProfileImage),
//             ),
//             const SizedBox(width: 12),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(_currentChat!.otherUserName),
//                 Text(
//                   _currentChat!.isActive ? 'Online' : 'Offline',
//                   style: const TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.more_vert),
//             onPressed: () {
//               showModalBottomSheet(
//                 context: context,
//                 shape: const RoundedRectangleBorder(
//                   borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//                 ),
//                 builder: (context) => Container(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ListTile(
//                         leading: const Icon(Icons.block, color: Colors.red),
//                         title: const Text('Block User'),
//                         onTap: _blockUser,
//                       ),
//                       const Divider(),
//                       ListTile(
//                         leading: const Icon(Icons.report, color: Colors.orange),
//                         title: const Text('Report User'),
//                         onTap: () {
//                           Navigator.pop(context);
//                           // Implement report user
//                         },
//                       ),
//                       const SizedBox(height: 20),
//                       OutlinedButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: const Text('Cancel'),
//                       ),
//                     ],
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Post info header
//           Container(
//             padding: const EdgeInsets.all(12),
//             color: Colors.grey.shade50,
//             child: Row(
//               children: [
//                 ClipRRect(
//                   borderRadius: BorderRadius.circular(8),
//                   child: Image.network(
//                     _currentChat!.postImage,
//                     width: 60,
//                     height: 60,
//                     fit: BoxFit.cover,
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         _currentChat!.postTitle,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                           vertical: 2,
//                         ),
//                         decoration: BoxDecoration(
//                           color: _getOfferTypeColor(_currentChat!.offerType),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(
//                           _currentChat!.offerType,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 10,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Action buttons
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: _buildActionButtons(),
//           ),

//           // Messages
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(8),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 return _buildMessageBubble(_messages[index]);
//               },
//             ),
//           ),

//           // Message input
//           if (_currentChat!.canChat) _buildMessageInput(),
//         ],
//       ),
//     );
//   }

//   Widget _buildMessageInput() {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(top: BorderSide(color: Colors.grey.shade200)),
//       ),
//       child: Column(
//         children: [
//           if (_showEmojiPicker) _buildEmojiPicker(),
//           Row(
//             children: [
//               // Attach button
//               IconButton(
//                 icon: const Icon(Icons.attach_file),
//                 onPressed: () {
//                   // Implement attachment functionality
//                 },
//               ),

//               // Message input
//               Expanded(
//                 child: TextField(
//                   controller: _messageController,
//                   decoration: InputDecoration(
//                     hintText: 'Type a message...',
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(25),
//                       borderSide: BorderSide.none,
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey.shade100,
//                     contentPadding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 12,
//                     ),
//                   ),
//                 ),
//               ),

//               // Emoji button
//               IconButton(
//                 icon: const Icon(Icons.emoji_emotions),
//                 onPressed: () {
//                   setState(() {
//                     _showEmojiPicker = !_showEmojiPicker;
//                   });
//                 },
//               ),

//               // Send button
//               IconButton(
//                 icon: const Icon(Icons.send, color: Colors.blue),
//                 onPressed: _sendMessage,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildEmojiPicker() {
//     final emojis = ['😀', '😂', '🥰', '😎', '🤔', '👍', '❤️', '🎉', '🔥', '💯'];

//     return Container(
//       height: 100,
//       padding: const EdgeInsets.all(8),
//       color: Colors.grey.shade50,
//       child: GridView.builder(
//         gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//           crossAxisCount: 10,
//           crossAxisSpacing: 8,
//           mainAxisSpacing: 8,
//         ),
//         itemCount: emojis.length,
//         itemBuilder: (context, index) {
//           return GestureDetector(
//             onTap: () {
//               _messageController.text += emojis[index];
//             },
//             child: Container(
//               alignment: Alignment.center,
//               child: Text(
//                 emojis[index],
//                 style: const TextStyle(fontSize: 24),
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

// // Extension for TradeChat copyWith
// extension TradeChatCopyWith on TradeChat {
//   TradeChat copyWith({
//     String? id,
//     String? otherUserId,
//     String? otherUserName,
//     String? otherUserProfileImage,
//     String? postId,
//     String? postTitle,
//     String? postImage,
//     String? offerType,
//     List<ChatMessage>? messages,
//     DateTime? lastInteraction,
//     bool? isActive,
//     bool? isOfferIncoming,
//     bool? isAccepted,
//     bool? isRejected,
//     bool? dealCompletedByMe,
//     bool? dealCompletedByOther,
//     String? offerStatus,
//     double? priceOffer,
//     List<OfferedItem>? barterItems,
//     String? counterOfferId,
//   }) {
//     return TradeChat(
//       id: id ?? this.id,
//       otherUserId: otherUserId ?? this.otherUserId,
//       otherUserName: otherUserName ?? this.otherUserName,
//       otherUserProfileImage:
//           otherUserProfileImage ?? this.otherUserProfileImage,
//       postId: postId ?? this.postId,
//       postTitle: postTitle ?? this.postTitle,
//       postImage: postImage ?? this.postImage,
//       offerType: offerType ?? this.offerType,
//       messages: messages ?? this.messages,
//       lastInteraction: lastInteraction ?? this.lastInteraction,
//       isActive: isActive ?? this.isActive,
//       isOfferIncoming: isOfferIncoming ?? this.isOfferIncoming,
//       isAccepted: isAccepted ?? this.isAccepted,
//       isRejected: isRejected ?? this.isRejected,
//       dealCompletedByMe: dealCompletedByMe ?? this.dealCompletedByMe,
//       dealCompletedByOther: dealCompletedByOther ?? this.dealCompletedByOther,
//       offerStatus: offerStatus ?? this.offerStatus,
//       priceOffer: priceOffer ?? this.priceOffer,
//       barterItems: barterItems ?? this.barterItems,
//       counterOfferId: counterOfferId ?? this.counterOfferId,
//     );
//   }
// }

// // Offer Deck Screen (simplified)
// class OfferDeckScreen extends StatelessWidget {
//   final TradeChat? initialOffer;

//   const OfferDeckScreen({super.key, this.initialOffer});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Offer Deck')),
//       body: const Center(
//         child: Text('Offer Deck Screen - Implementation depends on your product data'),
//       ),
//     );
//   }
// }

// // Complete Deal Screen
// class CompleteDealScreen extends StatelessWidget {
//   final TradeChat chat;
//   final VoidCallback onDealCompleted;

//   const CompleteDealScreen({
//     super.key,
//     required this.chat,
//     required this.onDealCompleted,
//   });

//   void _completeDeal() {
//     onDealCompleted();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Complete Deal')),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Deal Completion',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'You are completing the deal for:',
//               style: TextStyle(color: Colors.grey.shade600),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               chat.postTitle,
//               style: const TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 30),
//             const Text(
//               'Items involved in this deal:',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             if (chat.barterItems != null)
//               ...chat.barterItems!.map((item) {
//                 return ListTile(
//                   leading: CircleAvatar(
//                     backgroundImage: NetworkImage(item.image),
//                   ),
//                   title: Text(item.title),
//                   subtitle: Text(item.category),
//                   trailing: Text('\$${item.value?.toStringAsFixed(2)}'),
//                 );
//               }),
//             if (chat.priceOffer != null)
//               ListTile(
//                 leading: const CircleAvatar(child: Text('\$')),
//                 title: const Text('Cash Payment'),
//                 subtitle: const Text('Price offer'),
//                 trailing: Text('\$${chat.priceOffer!.toStringAsFixed(2)}'),
//               ),
//             const SizedBox(height: 30),
//             const Text(
//               'By clicking "Mark Deal as Completed":',
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             const Text('• The chat will become inactive'),
//             const Text('• Both items will be marked as traded'),
//             const Text('• The deal will be recorded in your history'),
//             const Spacer(),
//             ElevatedButton(
//               onPressed: () {
//                 _completeDeal();
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Deal marked as completed!'),
//                     duration: Duration(seconds: 3),
//                   ),
//                 );
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 minimumSize: const Size(double.infinity, 50),
//               ),
//               child: const Text(
//                 'Mark Deal as Completed',
//                 style: TextStyle(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:yempover_app/models/TradeChat.dart';
import 'package:intl/intl.dart';

class TradeChatScreen extends StatefulWidget {
  const TradeChatScreen({super.key});

  @override
  _TradeChatScreenState createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<TradeChat> _allChats = [];
  List<TradeChat> _inboxChats = [];
  List<TradeChat> _outboxChats = [];
  List<String> _userProducts = [];
  String? _selectedProductFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChats();
    _loadUserProducts();
  }

  void _loadChats() {
    // Sample data
    _allChats = [
      TradeChat(
        id: '1',
        otherUserId: 'user1',
        otherUserName: 'Melia K',
        otherUserProfileImage: 'https://i.pravatar.cc/150?img=1',
        postId: 'post1',
        postTitle: 'Sofa - Mint Condition',
        postImage:
            'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80',
        offerType: 'Barter',
        messages: [
          ChatMessage(
            id: 'msg1',
            senderId: 'user1',
            message: 'Hi! I would like to swap with my Mobile and Speaker',
            timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
            isOffer: true,
          ),
        ],
        lastInteraction: DateTime.now().subtract(const Duration(minutes: 20)),
        isActive: true,
        isOfferIncoming: true,
        offerStatus: 'accepted',
        barterItems: [
          OfferedItem(
            id: 'item1',
            title: 'iPhone 13 Pro',
            image:
                'https://images.unsplash.com/photo-1632661674596-df8be070a5c5?w=500&q=80',
            category: 'Electronics',
            value: 800,
            condition: 'Excellent',
          ),
        ],
        isAccepted: true,
        dealCompletedByMe: false,
        dealCompletedByOther: false,
      ),
    ];

    _updateFilteredChats();
  }

  void _loadUserProducts() {
    _userProducts = ['All Products', 'Sofa - Mint Condition', 'iPhone 13 Pro'];
  }

  void _updateFilteredChats() {
    setState(() {
      _inboxChats = _allChats.where((chat) => chat.isOfferIncoming).toList();
      _outboxChats = _allChats.where((chat) => !chat.isOfferIncoming).toList();
    });
  }

  List<TradeChat> _getFilteredInboxChats() {
    if (_selectedProductFilter == null ||
        _selectedProductFilter == 'All Products') {
      return _inboxChats;
    }
    return _inboxChats
        .where((chat) => chat.postTitle == _selectedProductFilter)
        .toList();
  }

  void _showProductFilterDialog() {
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
                  setState(() {
                    _selectedProductFilter = product;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedProductFilter = null;
                });
                Navigator.pop(context);
              },
              child: const Text('Clear Filter'),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatDetail(TradeChat chat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailScreen(
          chat: chat,
          onChatUpdated: (updatedChat) {
            _updateChat(updatedChat);
          },
        ),
      ),
    );
  }

  void _updateChat(TradeChat updatedChat) {
    setState(() {
      final index = _allChats.indexWhere((c) => c.id == updatedChat.id);
      if (index != -1) {
        _allChats[index] = updatedChat;
        _updateFilteredChats();
      }
    });
  }

  Widget _buildChatItem(TradeChat chat) {
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
              color: Colors.black.withOpacity(0.05),
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
                  backgroundImage: NetworkImage(chat.otherUserProfileImage),
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
                      Text(
                        chat.otherUserName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
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
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                      if (chat.isDealCompleted)
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
                            'Deal Completed',
                            style: TextStyle(color: Colors.green, fontSize: 10),
                          ),
                        ),
                      if (!chat.isActive && !chat.isDealCompleted)
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
                            'Inactive',
                            style: TextStyle(color: Colors.grey, fontSize: 10),
                          ),
                        ),
                      if (chat.isAccepted && !chat.isDealCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Accepted',
                            style: TextStyle(color: Colors.blue, fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (chat.pendingDealCompletion)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 12,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            chat.dealCompletedByMe
                                ? 'Waiting for ${chat.otherUserName}'
                                : 'Complete Deal',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    chat.messages.isNotEmpty
                        ? chat.messages.last.message
                        : 'No messages',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                chat.postImage,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOfferTypeColor(String offerType) {
    switch (offerType) {
      case 'Barter':
        return Colors.orange;
      case 'Price':
        return Colors.blue;
      case 'Both':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trade Chat'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Chats'),
            Tab(text: 'Offers Inbox'),
            Tab(text: 'Offers Outbox'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _allChats.isEmpty
              ? const Center(
                  child: Text(
                    'No chats yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 16),
                  itemCount: _allChats.length,
                  itemBuilder: (context, index) {
                    return _buildChatItem(_allChats[index]);
                  },
                ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showProductFilterDialog,
                        icon: const Icon(Icons.filter_list, size: 20),
                        label: Text(
                          _selectedProductFilter ?? 'Filter by Your Product',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _getFilteredInboxChats().isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No incoming offers',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'When someone makes an offer on your items,\n they will appear here',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: _getFilteredInboxChats().length,
                        itemBuilder: (context, index) {
                          return _buildChatItem(
                            _getFilteredInboxChats()[index],
                          );
                        },
                      ),
              ),
            ],
          ),
          _outboxChats.isEmpty
              ? const Center(
                  child: Text(
                    'No outgoing offers',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 16),
                  itemCount: _outboxChats.length,
                  itemBuilder: (context, index) {
                    return _buildChatItem(_outboxChats[index]);
                  },
                ),
        ],
      ),
    );
  }
}

// Chat Detail Screen
class ChatDetailScreen extends StatefulWidget {
  final TradeChat chat;
  final Function(TradeChat) onChatUpdated;

  const ChatDetailScreen({
    super.key,
    required this.chat,
    required this.onChatUpdated,
  });

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  Color _getOfferTypeColor(String offerType) {
    switch (offerType) {
      case 'Barter':
        return Colors.orange;
      case 'Price':
        return Colors.blue;
      case 'Both':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmojiPicker = false;
  List<ChatMessage> _messages = [];
  TradeChat? _currentChat;

  @override
  void initState() {
    super.initState();
    _currentChat = widget.chat;
    _messages = List.from(_currentChat!.messages);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current_user',
      message: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
      _showEmojiPicker = false;
    });

    _scrollToBottom();
  }

  void _showDealCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => CompleteDealDialog(
        chat: _currentChat!,
        onDealCompleted: (isCompleted, sellingPrice, remarks) {
          _handleDealCompletion(isCompleted, sellingPrice, remarks);
        },
      ),
    );
  }

  void _handleDealCompletion(
    bool isCompleted,
    double? sellingPrice,
    String remarks,
  ) {
    setState(() {
      _currentChat = _currentChat?.copyWith(
        dealCompletedByMe: true,
        dealCompletedTime: DateTime.now(),
        dealRemarks: remarks,
        dealSellingPrice: sellingPrice,
      );

      if (_currentChat!.dealCompletedByOther) {
        _currentChat = _currentChat?.copyWith(
          isActive: false,
          isDealCompleted: true,
        );
      }
    });

    _updateChat();

    // Add system message
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      message: isCompleted
          ? 'Deal marked as completed by you. Waiting for ${_currentChat!.otherUserName} to confirm.'
          : 'Deal marked as not completed by you. Waiting for ${_currentChat!.otherUserName} to confirm.',
      timestamp: DateTime.now(),
      isSystemMessage: true,
    );

    setState(() {
      _messages.add(systemMessage);
    });

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isCompleted
              ? 'Deal completion request sent!'
              : 'Deal not completed request sent!',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _viewConfirmationDialog() {
    // This would be called when the other user sends a confirmation
    showDialog(
      context: context,
      builder: (context) => DealConfirmationDialog(
        chat: _currentChat!,
        onConfirm: (isAccepted) {
          _handleConfirmationResponse(isAccepted);
        },
      ),
    );
  }

  void _handleConfirmationResponse(bool isAccepted) {
    setState(() {
      if (isAccepted) {
        _currentChat = _currentChat?.copyWith(
          dealConfirmed: true,
          isActive: false,
          isDealCompleted: _currentChat!.dealCompletedByMe,
        );
      } else {
        _currentChat = _currentChat?.copyWith(dealRejected: true);
      }
    });

    _updateChat();

    // Add system message
    final systemMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'system',
      message: isAccepted
          ? 'You accepted the deal completion request.'
          : 'You rejected the deal completion request.',
      timestamp: DateTime.now(),
      isSystemMessage: true,
    );

    setState(() {
      _messages.add(systemMessage);
    });

    Navigator.pop(context);
  }

  void _acceptOffer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Offer'),
        content: const Text(
          'Are you sure you want to accept this offer?\n\n'
          'Accepting will automatically reject other open offers and make '
          'the products unavailable in the marketplace.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAcceptOffer();
            },
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _handleAcceptOffer() {
    setState(() {
      _currentChat = _currentChat?.copyWith(
        isAccepted: true,
        offerStatus: 'accepted',
      );
    });

    _updateChat();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offer accepted successfully!'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _rejectOffer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Offer'),
        content: const Text(
          'Are you sure you want to reject this offer?\n\n'
          'Rejecting will end the conversation and no further chats or offers '
          'can be made.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleRejectOffer();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _handleRejectOffer() {
    setState(() {
      _currentChat = _currentChat?.copyWith(
        isRejected: true,
        isActive: false,
        offerStatus: 'rejected',
      );
    });

    _updateChat();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offer rejected. Chat is now inactive.'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
          'Are you sure you want to block this user?\n\n'
          'You will no longer receive messages or offers from them.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleBlockUser();
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _handleBlockUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_currentChat!.otherUserName} has been blocked.'),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  void _updateChat() {
    if (_currentChat != null) {
      widget.onChatUpdated(_currentChat!);
    }
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentUser = message.senderId == 'current_user';
    final isSystemMessage = message.isSystemMessage;

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
              backgroundImage: NetworkImage(
                _currentChat!.otherUserProfileImage,
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
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
                  if (isSystemMessage)
                    Row(
                      children: [
                        const Icon(Icons.info, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            message.message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.isOffer)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📦 Offer Made',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        Text(message.message),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('h:mm a').format(message.timestamp),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
          if (isCurrentUser && !isSystemMessage)
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (!_currentChat!.canChat) {
      return Container();
    }

    if (_currentChat!.isOfferIncoming && !_currentChat!.isAccepted) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _rejectOffer,
              icon: const Icon(Icons.close, color: Colors.red),
              label: const Text('Reject', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _acceptOffer,
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else if (_currentChat!.isAccepted && _currentChat!.canCompleteDeal) {
      return ElevatedButton.icon(
        onPressed: _showDealCompletionDialog,
        icon: const Icon(Icons.handshake),
        label: const Text('Complete Deal'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      );
    } else if (_currentChat!.dealCompletedByOther &&
        !_currentChat!.dealConfirmed) {
      return ElevatedButton.icon(
        onPressed: _viewConfirmationDialog,
        icon: const Icon(Icons.notifications_active),
        label: const Text('View Confirmation'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        ),
      );
    }

    return Container();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                _currentChat!.otherUserProfileImage,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_currentChat!.otherUserName),
                Text(
                  _currentChat!.isActive ? 'Online' : 'Offline',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        actions: [
          if (_currentChat!.pendingDealCompletion)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    _currentChat!.dealCompletedByMe
                        ? 'Waiting'
                        : 'Action Needed',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
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
                      ListTile(
                        leading: const Icon(Icons.block, color: Colors.red),
                        title: const Text('Block User'),
                        onTap: _blockUser,
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.report, color: Colors.orange),
                        title: const Text('Report User'),
                        onTap: () {
                          Navigator.pop(context);
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
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _currentChat!.postImage,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentChat!.postTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getOfferTypeColor(_currentChat!.offerType),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _currentChat!.offerType,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildActionButtons(),
          ),
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
          if (_currentChat!.canChat) _buildMessageInput(),
        ],
      ),
    );
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
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blue),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

// Complete Deal Dialog
class CompleteDealDialog extends StatefulWidget {
  final TradeChat chat;
  final Function(bool isCompleted, double? sellingPrice, String remarks)
  onDealCompleted;

  const CompleteDealDialog({
    super.key,
    required this.chat,
    required this.onDealCompleted,
  });

  @override
  _CompleteDealDialogState createState() => _CompleteDealDialogState();
}

class _CompleteDealDialogState extends State<CompleteDealDialog> {
  bool _isCompleted = true;
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Deal'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Important Information:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deal Completed:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The trade has been completed. Completing a Deal will close further communication, and the chat becomes inactive. The item will be marked as sold, and the post will be deleted.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deal Not Completed:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'It closes Further Communication with the user and the chat becomes inactive. Since the item is not sold, it will be available on the Marketplace.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Deal Status:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Deal Completed'),
                    selected: _isCompleted,
                    onSelected: (selected) {
                      setState(() {
                        _isCompleted = selected;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Deal Not Completed'),
                    selected: !_isCompleted,
                    onSelected: (selected) {
                      setState(() {
                        _isCompleted = !selected;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _remarksController,
              decoration: const InputDecoration(
                labelText: 'Remarks',
                border: OutlineInputBorder(),
                hintText: 'Enter your remarks about this deal...',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter remarks';
                }
                return null;
              },
            ),
            if (_isCompleted && widget.chat.offerType == 'Price')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _priceController,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price*',
                      border: OutlineInputBorder(),
                      hintText: 'Enter selling price',
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter selling price';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '* Required for price-based deals',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
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
            if (_formKey.currentState!.validate()) {
              double? sellingPrice;
              if (_isCompleted && widget.chat.offerType == 'Price') {
                sellingPrice = double.tryParse(_priceController.text);
              }
              widget.onDealCompleted(
                _isCompleted,
                sellingPrice,
                _remarksController.text,
              );
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

// Deal Confirmation Dialog
class DealConfirmationDialog extends StatefulWidget {
  final TradeChat chat;
  final Function(bool isAccepted) onConfirm;

  const DealConfirmationDialog({
    super.key,
    required this.chat,
    required this.onConfirm,
  });

  @override
  _DealConfirmationDialogState createState() => _DealConfirmationDialogState();
}

class _DealConfirmationDialogState extends State<DealConfirmationDialog> {
  @override
  Widget build(BuildContext context) {
    final isCompleted =
        widget.chat.dealCompletedByOther &&
        widget.chat.dealRemarksByOther != null &&
        widget.chat.dealRemarksByOther!.contains('Completed');

    return AlertDialog(
      title: const Text('Deal Completion Request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.chat.otherUserName} has marked the deal as:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? '✅ Deal Completed' : '⚠️ Deal Not Completed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.chat.dealRemarksByOther != null)
                  Text(
                    'Remarks: ${widget.chat.dealRemarksByOther}',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (widget.chat.dealSellingPriceByOther != null)
                  Text(
                    'Selling Price: \$${widget.chat.dealSellingPriceByOther!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Please confirm or reject this deal completion:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            '• If you accept, the deal will be finalized and items will be marked accordingly',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• If you reject, the chat remains open for further discussion',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => widget.onConfirm(false),
          child: const Text('Reject', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: () => widget.onConfirm(true),
          child: const Text('Accept'),
        ),
      ],
    );
  }
}

// Extension for TradeChat copyWith
extension TradeChatCopyWith on TradeChat {
  TradeChat copyWith({
    String? id,
    String? otherUserId,
    String? otherUserName,
    String? otherUserProfileImage,
    String? postId,
    String? postTitle,
    String? postImage,
    String? offerType,
    List<ChatMessage>? messages,
    DateTime? lastInteraction,
    bool? isActive,
    bool? isOfferIncoming,
    bool? isAccepted,
    bool? isRejected,
    bool? dealCompletedByMe,
    bool? dealCompletedByOther,
    bool? dealConfirmed,
    bool? dealRejected,
    bool? isDealCompleted,
    String? offerStatus,
    double? priceOffer,
    List<OfferedItem>? barterItems,
    String? counterOfferId,
    String? dealRemarks,
    double? dealSellingPrice,
    DateTime? dealCompletedTime,
    String? dealRemarksByOther,
    double? dealSellingPriceByOther,
    DateTime? dealCompletedTimeByOther,
  }) {
    return TradeChat(
      id: id ?? this.id,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserProfileImage:
          otherUserProfileImage ?? this.otherUserProfileImage,
      postId: postId ?? this.postId,
      postTitle: postTitle ?? this.postTitle,
      postImage: postImage ?? this.postImage,
      offerType: offerType ?? this.offerType,
      messages: messages ?? this.messages,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      isActive: isActive ?? this.isActive,
      isOfferIncoming: isOfferIncoming ?? this.isOfferIncoming,
      isAccepted: isAccepted ?? this.isAccepted,
      isRejected: isRejected ?? this.isRejected,
      dealCompletedByMe: dealCompletedByMe ?? this.dealCompletedByMe,
      dealCompletedByOther: dealCompletedByOther ?? this.dealCompletedByOther,
      dealConfirmed: dealConfirmed ?? this.dealConfirmed,
      dealRejected: dealRejected ?? this.dealRejected,
      isDealCompleted: isDealCompleted ?? this.isDealCompleted,
      offerStatus: offerStatus ?? this.offerStatus,
      priceOffer: priceOffer ?? this.priceOffer,
      barterItems: barterItems ?? this.barterItems,
      counterOfferId: counterOfferId ?? this.counterOfferId,
      dealRemarks: dealRemarks ?? this.dealRemarks,
      dealSellingPrice: dealSellingPrice ?? this.dealSellingPrice,
      dealCompletedTime: dealCompletedTime ?? this.dealCompletedTime,
      dealRemarksByOther: dealRemarksByOther ?? this.dealRemarksByOther,
      dealSellingPriceByOther:
          dealSellingPriceByOther ?? this.dealSellingPriceByOther,
      dealCompletedTimeByOther:
          dealCompletedTimeByOther ?? this.dealCompletedTimeByOther,
    );
  }
}

// Models
class TradeChat {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserProfileImage;
  final String postId;
  final String postTitle;
  final String postImage;
  final String offerType;
  final List<ChatMessage> messages;
  final DateTime lastInteraction;
  final bool isActive;
  final bool isOfferIncoming;
  final bool isAccepted;
  final bool isRejected;
  final bool dealCompletedByMe;
  final bool dealCompletedByOther;
  final bool dealConfirmed;
  final bool dealRejected;
  final bool isDealCompleted;
  final String offerStatus;
  final double? priceOffer;
  final List<OfferedItem>? barterItems;
  final String? counterOfferId;
  final String? dealRemarks;
  final double? dealSellingPrice;
  final DateTime? dealCompletedTime;
  final String? dealRemarksByOther;
  final double? dealSellingPriceByOther;
  final DateTime? dealCompletedTimeByOther;

  TradeChat({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserProfileImage,
    required this.postId,
    required this.postTitle,
    required this.postImage,
    required this.offerType,
    required this.messages,
    required this.lastInteraction,
    this.isActive = true,
    this.isOfferIncoming = false,
    this.isAccepted = false,
    this.isRejected = false,
    this.dealCompletedByMe = false,
    this.dealCompletedByOther = false,
    this.dealConfirmed = false,
    this.dealRejected = false,
    this.isDealCompleted = false,
    this.offerStatus = 'pending',
    this.priceOffer,
    this.barterItems,
    this.counterOfferId,
    this.dealRemarks,
    this.dealSellingPrice,
    this.dealCompletedTime,
    this.dealRemarksByOther,
    this.dealSellingPriceByOther,
    this.dealCompletedTimeByOther,
  });

  bool get canBlock => !(isAccepted && !isDealCompleted);
  bool get canChat => isActive && !isRejected && !isDealCompleted;

  bool get canCompleteDeal {
    if (!isAccepted) return false;
    if (isDealCompleted) return false;

    // For price offers, only the poster can complete
    if (offerType == 'Price') {
      return isOfferIncoming && !dealCompletedByMe;
    }

    // For barter/both, both users can complete
    return !dealCompletedByMe;
  }

  bool get pendingDealCompletion {
    return isAccepted &&
        ((dealCompletedByMe && !dealCompletedByOther) ||
            (!dealCompletedByMe && dealCompletedByOther));
  }

  String get formattedTime => DateFormat('h:mm a').format(lastInteraction);
  String get formattedDate => DateFormat('MMM d').format(lastInteraction);
}

class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isOffer;
  final bool isSystemMessage;
  final String? offerId;
  final List<String>? attachments;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.isOffer = false,
    this.isSystemMessage = false,
    this.offerId,
    this.attachments,
    this.isRead = false,
  });
}

class OfferedItem {
  final String id;
  final String title;
  final String image;
  final String category;
  final double? value;
  final String condition;

  OfferedItem({
    required this.id,
    required this.title,
    required this.image,
    required this.category,
    this.value,
    required this.condition,
  });
}
