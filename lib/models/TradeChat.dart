import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Models for Trade Chat
class TradeChat {
  final String id;
  final String otherUserId;
  final String otherUserName;
  final String otherUserProfileImage;
  final String postId;
  final String postTitle;
  final String postImage;
  final String offerType; // 'Barter', 'Price', 'Both'
  final List<ChatMessage> messages;
  final DateTime lastInteraction;
  final bool isActive;
  final bool isOfferIncoming;
  final bool isAccepted;
  final bool isRejected;
  final bool dealCompletedByMe;
  final bool dealCompletedByOther;
  final String offerStatus; // 'pending', 'accepted', 'rejected', 'countered'
  final double? priceOffer;
  final List<OfferedItem>? barterItems;
  final String? counterOfferId;

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
    this.offerStatus = 'pending',
    this.priceOffer,
    this.barterItems,
    this.counterOfferId,
  });

  bool get isDealCompleted => dealCompletedByMe && dealCompletedByOther;
  bool get canBlock => !(isAccepted && !isDealCompleted);
  bool get canChat => isActive && !isRejected && !isDealCompleted;
  String get formattedTime => DateFormat('h:mm a').format(lastInteraction);
  String get formattedDate => DateFormat('MMM d').format(lastInteraction);
}

class ChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime timestamp;
  final bool isOffer;
  final String? offerId;
  final List<String>? attachments;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.timestamp,
    this.isOffer = false,
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
