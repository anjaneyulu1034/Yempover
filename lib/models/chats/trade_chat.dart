import 'package:intl/intl.dart';

// ==================== ENUMS ====================

enum ChatStatus { ACTIVE, COMPLETED, CANCELLED, ARCHIVED, INACTIVE, ACCEPTED }

extension ChatStatusExtension on ChatStatus {
  String get value {
    switch (this) {
      case ChatStatus.ACTIVE:
        return 'ACTIVE';
      case ChatStatus.COMPLETED:
        return 'COMPLETED';
      case ChatStatus.CANCELLED:
        return 'CANCELLED';
      case ChatStatus.ARCHIVED:
        return 'ARCHIVED';
      case ChatStatus.INACTIVE:
        return 'INACTIVE';
      case ChatStatus.ACCEPTED:
        return 'ACCEPTED';
    }
  }

  static ChatStatus fromString(String status) {
    switch (status) {
      case 'ACTIVE':
        return ChatStatus.ACTIVE;
      case 'COMPLETED':
        return ChatStatus.COMPLETED;
      case 'CANCELLED':
        return ChatStatus.CANCELLED;
      case 'ARCHIVED':
        return ChatStatus.ARCHIVED;
      case 'INACTIVE':
        return ChatStatus.INACTIVE;
      case 'ACCEPTED':
        return ChatStatus.ACCEPTED;
      default:
        return ChatStatus.ACTIVE;
    }
  }
}

enum OfferType { PRICE, BARTER, BOTH, SERVICE }

extension OfferTypeExtension on OfferType {
  String get value {
    switch (this) {
      case OfferType.PRICE:
        return 'PRICE';
      case OfferType.BARTER:
        return 'BARTER';
      case OfferType.BOTH:
        return 'BOTH';
      case OfferType.SERVICE:
        return 'SERVICE';
    }
  }

  static OfferType fromString(String type) {
    switch (type) {
      case 'PRICE':
        return OfferType.PRICE;
      case 'BARTER':
        return OfferType.BARTER;
      case 'BOTH':
        return OfferType.BOTH;
      case 'SERVICE':
        return OfferType.SERVICE;
      default:
        return OfferType.PRICE;
    }
  }
}

enum OfferStatus { PENDING, ACCEPTED, REJECTED, COUNTERED, WITHDRAWN }

extension OfferStatusExtension on OfferStatus {
  String get value {
    switch (this) {
      case OfferStatus.PENDING:
        return 'PENDING';
      case OfferStatus.ACCEPTED:
        return 'ACCEPTED';
      case OfferStatus.REJECTED:
        return 'REJECTED';
      case OfferStatus.COUNTERED:
        return 'COUNTERED';
      case OfferStatus.WITHDRAWN:
        return 'WITHDRAWN';
    }
  }

  static OfferStatus fromString(String status) {
    switch (status) {
      case 'PENDING':
        return OfferStatus.PENDING;
      case 'ACCEPTED':
        return OfferStatus.ACCEPTED;
      case 'REJECTED':
        return OfferStatus.REJECTED;
      case 'COUNTERED':
        return OfferStatus.COUNTERED;
      case 'WITHDRAWN':
        return OfferStatus.WITHDRAWN;
      default:
        return OfferStatus.PENDING;
    }
  }
}

enum MessageType { TEXT, IMAGE, OFFER, SYSTEM }

extension MessageTypeExtension on MessageType {
  String get value {
    switch (this) {
      case MessageType.TEXT:
        return 'TEXT';
      case MessageType.IMAGE:
        return 'IMAGE';
      case MessageType.OFFER:
        return 'OFFER';
      case MessageType.SYSTEM:
        return 'SYSTEM';
    }
  }

  static MessageType fromString(String type) {
    switch (type) {
      case 'TEXT':
        return MessageType.TEXT;
      case 'IMAGE':
        return MessageType.IMAGE;
      case 'OFFER':
        return MessageType.OFFER;
      case 'SYSTEM':
        return MessageType.SYSTEM;
      default:
        return MessageType.TEXT;
    }
  }
}

// ==================== BASE MODELS ====================

// User Info Model (for chat participants)
class UserInfo {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? mobileNumber;

  UserInfo({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.mobileNumber,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      mobileNumber: json['mobileNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
      'mobileNumber': mobileNumber,
    };
  }

  String get fullName => '$firstName $lastName';
  String get initials =>
      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';
}

// Product Info Model
class ProductInfo {
  final String id;
  final String title;
  final List<String> images;
  final double? price;
  final String status;
  final String barterStatus;

  ProductInfo({
    required this.id,
    required this.title,
    required this.images,
    this.price,
    required this.status,
    this.barterStatus = 'NO_BARTER',
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      status: json['status'] ?? '',
      barterStatus: json['barterStatus'] ?? 'NO_BARTER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'images': images,
      'price': price,
      'status': status,
      'barterStatus': barterStatus,
    };
  }

  String get firstImage => images.isNotEmpty ? images.first : '';
  String get formattedPrice {
    if (price == null || price! <= 0) return 'Free';
    if (price! == price!.roundToDouble()) return price!.toInt().toString();
    return price!.toStringAsFixed(2);
  }

  bool get allowsPrice => price != null && price! > 0;
  bool get allowsBarter =>
      barterStatus == 'OPEN_FOR_BARTER' || status == 'FOR_BARTER';
}

// Service Info Model
class ServiceInfo {
  final String id;
  final String title;
  final List<String> images;
  final double? price;
  final String status;
  final String barterStatus;

  ServiceInfo({
    required this.id,
    required this.title,
    required this.images,
    this.price,
    required this.status,
    this.barterStatus = 'NO_BARTER',
  });

  factory ServiceInfo.fromJson(Map<String, dynamic> json) {
    return ServiceInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      status: json['status'] ?? '',
      barterStatus: json['barterStatus'] ?? 'NO_BARTER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'images': images,
      'price': price,
      'status': status,
      'barterStatus': barterStatus,
    };
  }

  String get firstImage => images.isNotEmpty ? images.first : '';

  bool get allowsPrice => price != null && price! > 0;
  bool get allowsBarter =>
      barterStatus == 'OPEN_FOR_BARTER' || status == 'FOR_BARTER';
}

// ==================== CHAT MESSAGE MODEL ====================

class ChatMessage {
  final String id;
  final String tradeChatId;
  final String sentById;
  final UserInfo? sentBy;
  final String messageText;
  final String? imageUrl;
  final MessageType messageType;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;
  final String? offerId;

  ChatMessage({
    required this.id,
    required this.tradeChatId,
    required this.sentById,
    this.sentBy,
    required this.messageText,
    this.imageUrl,
    required this.messageType,
    required this.isRead,
    this.readAt,
    required this.createdAt,
    this.offerId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      tradeChatId: json['tradeChatId'] ?? '',
      sentById: json['sentById'] ?? '',
      sentBy: json['sentBy'] != null ? UserInfo.fromJson(json['sentBy']) : null,
      messageText: json['messageText'] ?? '',
      imageUrl: json['imageUrl'],
      messageType: MessageTypeExtension.fromString(
        json['messageType'] ?? 'TEXT',
      ),
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      offerId: json['offerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tradeChatId': tradeChatId,
      'sentById': sentById,
      'sentBy': sentBy?.toJson(),
      'messageText': messageText,
      'imageUrl': imageUrl,
      'messageType': messageType.value,
      'isRead': isRead,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'offerId': offerId,
    };
  }

  // Helper getters
  bool get isOffer => messageType == MessageType.OFFER;
  bool get isImage => messageType == MessageType.IMAGE;
  bool get isSystem => messageType == MessageType.SYSTEM;
  bool get isText => messageType == MessageType.TEXT;

  String get formattedTime {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return DateFormat('MMM d').format(createdAt);
    } else {
      return DateFormat('h:mm a').format(createdAt);
    }
  }
}

// ==================== TRADE OFFER MODEL ====================

class TradeOffer {
  final String id;
  final String tradeChatId;
  final String madeById;
  final UserInfo? madeBy;
  final OfferType offerType;
  final OfferStatus offerStatus;
  final double? price;
  final String? currency;
  final String? barterItemTitle;
  final String? barterItemDescription;
  final List<String> barterItemImages;
  final List<String> barterWishCategories;
  final int counterOfferCount;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;

  TradeOffer({
    required this.id,
    required this.tradeChatId,
    required this.madeById,
    this.madeBy,
    required this.offerType,
    required this.offerStatus,
    this.price,
    this.currency,
    this.barterItemTitle,
    this.barterItemDescription,
    required this.barterItemImages,
    required this.barterWishCategories,
    required this.counterOfferCount,
    required this.createdAt,
    this.acceptedAt,
    this.rejectedAt,
  });

  factory TradeOffer.fromJson(Map<String, dynamic> json) {
    return TradeOffer(
      id: json['id'] ?? '',
      tradeChatId: json['tradeChatId'] ?? '',
      madeById: json['madeById'] ?? '',
      madeBy: json['madeBy'] != null ? UserInfo.fromJson(json['madeBy']) : null,
      offerType: OfferTypeExtension.fromString(json['offerType'] ?? 'PRICE'),
      offerStatus: OfferStatusExtension.fromString(
        json['offerStatus'] ?? 'PENDING',
      ),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      currency: json['currency'],
      barterItemTitle: json['barterItemTitle'],
      barterItemDescription: json['barterItemDescription'],
      barterItemImages: (json['barterItemImages'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      barterWishCategories: (json['barterWishCategories'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      counterOfferCount: json['counterOfferCount'] ?? 0,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.parse(json['rejectedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tradeChatId': tradeChatId,
      'madeById': madeById,
      'madeBy': madeBy?.toJson(),
      'offerType': offerType.value,
      'offerStatus': offerStatus.value,
      'price': price,
      'currency': currency,
      'barterItemTitle': barterItemTitle,
      'barterItemDescription': barterItemDescription,
      'barterItemImages': barterItemImages,
      'barterWishCategories': barterWishCategories,
      'counterOfferCount': counterOfferCount,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
    };
  }

  // Helper getters
  bool get isPending => offerStatus == OfferStatus.PENDING;
  bool get isAccepted => offerStatus == OfferStatus.ACCEPTED;
  bool get isRejected => offerStatus == OfferStatus.REJECTED;
  bool get isCountered => offerStatus == OfferStatus.COUNTERED;
  bool get isWithdrawn => offerStatus == OfferStatus.WITHDRAWN;

  bool get isPriceOffer => offerType == OfferType.PRICE;
  bool get isBarterOffer => offerType == OfferType.BARTER;
  bool get isBothOffer => offerType == OfferType.BOTH;
  bool get isServiceOffer => offerType == OfferType.SERVICE;

  String get offerSummary {
    if (isPriceOffer && price != null) {
      final amount = price! == price!.roundToDouble()
          ? price!.toInt().toString()
          : price!.toStringAsFixed(2);
      return 'Price: $amount coins';
    } else if (isBarterOffer || isBothOffer) {
      final itemSummary = 'Barter: ${barterItemTitle ?? 'Item'}';
      if (isBothOffer && price != null && price! > 0) {
        final amount = price! == price!.roundToDouble()
            ? price!.toInt().toString()
            : price!.toStringAsFixed(2);
        return '$itemSummary + $amount coins';
      }
      return itemSummary;
    } else if (isServiceOffer) {
      return 'Service Offer';
    }
    return 'Unknown Offer';
  }
}

class DealCompletionInfo {
  final bool initiatorCompleted;
  final DateTime? initiatorCompletedAt;
  final bool responderCompleted;
  final DateTime? responderCompletedAt;
  final DateTime? dealCompletedAt;

  DealCompletionInfo({
    required this.initiatorCompleted,
    this.initiatorCompletedAt,
    required this.responderCompleted,
    this.responderCompletedAt,
    this.dealCompletedAt,
  });

  factory DealCompletionInfo.fromJson(Map<String, dynamic> json) {
    return DealCompletionInfo(
      initiatorCompleted: json['initiatorCompleted'] == true,
      initiatorCompletedAt: json['initiatorCompletedAt'] != null
          ? DateTime.tryParse(json['initiatorCompletedAt'].toString())
          : null,
      responderCompleted: json['responderCompleted'] == true,
      responderCompletedAt: json['responderCompletedAt'] != null
          ? DateTime.tryParse(json['responderCompletedAt'].toString())
          : null,
      dealCompletedAt: json['dealCompletedAt'] != null
          ? DateTime.tryParse(json['dealCompletedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'initiatorCompleted': initiatorCompleted,
      'initiatorCompletedAt': initiatorCompletedAt?.toIso8601String(),
      'responderCompleted': responderCompleted,
      'responderCompletedAt': responderCompletedAt?.toIso8601String(),
      'dealCompletedAt': dealCompletedAt?.toIso8601String(),
    };
  }

  bool hasUserCompleted(String userId, String initiatorId, String responderId) {
    if (userId == initiatorId) return initiatorCompleted;
    if (userId == responderId) return responderCompleted;
    return false;
  }
}

// ==================== TRADE CHAT MODEL ====================

class TradeChat {
  final String id;
  final String initiatorId;
  final String responderId;
  final String? productId;
  final String? serviceId;
  final ChatStatus status;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserInfo initiator;
  final UserInfo responder;
  final ProductInfo? product;
  final ServiceInfo? service;
  final DealCompletionInfo? dealCompletion;
  final List<ChatMessage> messages;
  final List<TradeOffer> offers;
  // Server-computed snapshot as of this fetch: whether the other party is
  // currently connected, and how many of their messages are unread. Null
  // when the backend response didn't include them (older cached data) —
  // callers should treat null as "unknown", not "offline"/"zero".
  final bool? otherUserOnline;
  final int? unreadCount;

  TradeChat({
    required this.id,
    required this.initiatorId,
    required this.responderId,
    this.productId,
    this.serviceId,
    required this.status,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
    required this.initiator,
    required this.responder,
    this.product,
    this.service,
    this.dealCompletion,
    required this.messages,
    required this.offers,
    this.otherUserOnline,
    this.unreadCount,
  });

  factory TradeChat.fromJson(Map<String, dynamic> json) {
    return TradeChat(
      id: json['id'] ?? '',
      initiatorId: json['initiatorId'] ?? '',
      responderId: json['responderId'] ?? '',
      productId: json['productId'],
      serviceId: json['serviceId'],
      status: ChatStatusExtension.fromString(json['status'] ?? 'ACTIVE'),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      initiator: UserInfo.fromJson(json['initiator'] ?? {}),
      responder: UserInfo.fromJson(json['responder'] ?? {}),
      product: json['product'] != null
          ? ProductInfo.fromJson(json['product'])
          : null,
      service: json['service'] != null
          ? ServiceInfo.fromJson(json['service'])
          : null,
      dealCompletion: json['dealCompletion'] != null
          ? DealCompletionInfo.fromJson(json['dealCompletion'])
          : null,
      messages: (json['messages'] as List? ?? [])
          .map((msg) => ChatMessage.fromJson(msg))
          .toList(),
      offers: (json['offers'] as List? ?? [])
          .map((offer) => TradeOffer.fromJson(offer))
          .toList(),
      otherUserOnline: json['otherUserOnline'] as bool?,
      unreadCount: json['unreadCount'] is int
          ? json['unreadCount'] as int
          : int.tryParse('${json['unreadCount'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'initiatorId': initiatorId,
      'responderId': responderId,
      'productId': productId,
      'serviceId': serviceId,
      'status': status.value,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'initiator': initiator.toJson(),
      'responder': responder.toJson(),
      'product': product?.toJson(),
      'service': service?.toJson(),
      'dealCompletion': dealCompletion?.toJson(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
      'offers': offers.map((offer) => offer.toJson()).toList(),
    };
  }

  // Helper getters
  bool get isActive =>
      status == ChatStatus.ACTIVE || status == ChatStatus.ACCEPTED;
  // Only truly complete once both sides have given completion consent
  // (dealCompletedAt is set by the backend at that point) — a single user
  // completing their side must not flip this, or the chat looks "done" and
  // disappears for the other user before they've had a chance to respond.
  bool get isCompleted =>
      status == ChatStatus.COMPLETED ||
      (dealCompletion != null && dealCompletion!.dealCompletedAt != null);
  bool get isCancelled => status == ChatStatus.CANCELLED;
  bool get isArchived => status == ChatStatus.ARCHIVED;
  bool get isInactive => status == ChatStatus.INACTIVE && !isCompleted;

  String get postTitle {
    if (product != null) return product!.title;
    if (service != null) return service!.title;
    return 'Unknown Item';
  }

  String get postImage {
    if (product != null && product!.images.isNotEmpty) {
      return product!.firstImage;
    }
    if (service != null && service!.images.isNotEmpty) {
      return service!.firstImage;
    }
    return '';
  }

  String get offerType {
    if (product != null && service != null) return 'Both';
    if (product != null) return 'Product';
    if (service != null) return 'Service';
    return 'Unknown';
  }

  DateTime get lastInteraction => lastMessageAt ?? updatedAt;

  String get formattedDate {
    final date = lastInteraction;
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM d').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Get other user info based on current user
  UserInfo getOtherUserInfo(String currentUserId) {
    return currentUserId == initiatorId ? responder : initiator;
  }

  // Check if offer is incoming (current user is the responder/post owner)
  bool isOfferIncoming(String currentUserId) {
    return currentUserId == responderId;
  }

  // Check if current user is the post owner
  bool isPostOwner(String currentUserId) {
    return currentUserId == responderId;
  }

  // Get unread count for a user. Prefers the server-computed snapshot
  // (accurate even when `messages` wasn't hydrated on this fetch); falls
  // back to counting locally-loaded messages when the server didn't send one.
  int getUnreadCount(String userId) {
    if (unreadCount != null) return unreadCount!;
    return messages
        .where((msg) => !msg.isRead && msg.sentById != userId)
        .length;
  }

  // Get pending offers
  List<TradeOffer> get pendingOffers {
    return offers.where((offer) => offer.isPending).toList();
  }

  // Get accepted offers
  List<TradeOffer> get acceptedOffers {
    return offers.where((offer) => offer.isAccepted).toList();
  }

  // Check if there's any accepted offer
  bool get hasAcceptedOffer {
    return offers.any((offer) => offer.isAccepted);
  }

  // Get the latest accepted offer
  TradeOffer? get latestAcceptedOffer {
    final accepted = offers.where((offer) => offer.isAccepted).toList();
    if (accepted.isEmpty) return null;
    accepted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return accepted.first;
  }

  // Check if deal can be completed
  bool canCompleteDeal(String currentUserId) {
    if (!isActive) return false;
    if (!hasAcceptedOffer) return false;

    if (dealCompletion?.hasUserCompleted(
          currentUserId,
          initiatorId,
          responderId,
        ) ==
        true) {
      return false;
    }

    // After acceptance, both users can provide completion consent.
    return currentUserId == initiatorId || currentUserId == responderId;
  }

  // Check if both users have completed the deal
  bool get isDealFullyCompleted {
    return status == ChatStatus.COMPLETED;
  }
}

// ==================== API RESPONSE MODELS ====================

class TradeChatResponse {
  final String status;
  final String message;
  final TradeChat data;

  TradeChatResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TradeChatResponse.fromJson(Map<String, dynamic> json) {
    return TradeChatResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: TradeChat.fromJson(json['data'] ?? {}),
    );
  }
}

class TradeChatsResponse {
  final String status;
  final String message;
  final TradeChatListData data;

  TradeChatsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TradeChatsResponse.fromJson(Map<String, dynamic> json) {
    return TradeChatsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: TradeChatListData.fromJson(json['data'] ?? {}),
    );
  }
}

class InboxOutboxResponse {
  final String status;
  final String message;
  final InboxOutboxData data;

  InboxOutboxResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory InboxOutboxResponse.fromJson(Map<String, dynamic> json) {
    return InboxOutboxResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: InboxOutboxData.fromJson(json['data'] ?? {}),
    );
  }
}

class InboxOutboxData {
  final List<TradeChat> chats;
  final PaginationInfo pagination;

  InboxOutboxData({required this.chats, required this.pagination});

  factory InboxOutboxData.fromJson(Map<String, dynamic> json) {
    return InboxOutboxData(
      chats: (json['chats'] as List? ?? [])
          .map((chat) => TradeChat.fromJson(chat))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class TradeChatListData {
  final List<TradeChat> chats;
  final PaginationInfo pagination;

  TradeChatListData({required this.chats, required this.pagination});

  factory TradeChatListData.fromJson(Map<String, dynamic> json) {
    return TradeChatListData(
      chats: (json['chats'] as List? ?? [])
          .map((chat) => TradeChat.fromJson(chat))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

class PaginationInfo {
  final int total;
  final int page;
  final int limit;
  final int pages;

  PaginationInfo({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      pages: json['pages'] ?? 1,
    );
  }

  bool get hasNextPage => page < pages;
  bool get hasPreviousPage => page > 1;
}

class MessageResponse {
  final String status;
  final String message;
  final ChatMessage data;

  MessageResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: ChatMessage.fromJson(json['data'] ?? {}),
    );
  }
}

class OfferResponse {
  final String status;
  final String message;
  final TradeOffer data;

  OfferResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OfferResponse.fromJson(Map<String, dynamic> json) {
    return OfferResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: TradeOffer.fromJson(json['data'] ?? {}),
    );
  }
}

class SuccessResponse {
  final String status;
  final String message;
  final Map<String, dynamic>? data;

  SuccessResponse({required this.status, required this.message, this.data});

  factory SuccessResponse.fromJson(Map<String, dynamic> json) {
    return SuccessResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'],
    );
  }

  bool get isSuccess => status == 'success';
}

// ==================== REQUEST MODELS ====================

class InitiateChatRequest {
  final String responderId;
  final String productId;
  final String? serviceId;

  InitiateChatRequest({
    required this.responderId,
    required this.productId,
    this.serviceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'responderId': responderId,
      'productId': productId,
      if (serviceId != null) 'serviceId': serviceId,
    };
  }
}

class SendMessageRequest {
  final String messageText;
  final String? imageUrl;

  SendMessageRequest({required this.messageText, this.imageUrl});

  Map<String, dynamic> toJson() {
    return {
      'messageText': messageText,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class CreateOfferRequest {
  final OfferType offerType;
  final double? price;
  final String? currency;
  final String? barterItemTitle;
  final String? barterItemDescription;
  final List<String> barterItemImages;
  final List<String> barterWishCategories;

  CreateOfferRequest({
    required this.offerType,
    this.price,
    this.currency,
    this.barterItemTitle,
    this.barterItemDescription,
    this.barterItemImages = const [],
    this.barterWishCategories = const [],
  });

  Map<String, dynamic> toJson() {
    final json = {
      'offerType': offerType.value,
      'barterItemImages': barterItemImages,
      'barterWishCategories': barterWishCategories,
    };

    if (offerType == OfferType.PRICE) {
      json['price'] = price as Object;
      json['currency'] = currency ?? 'USD';
      json['barterItemTitle'] = '';
      json['barterItemDescription'] = '';
    } else {
      json['price'] = '';
      json['barterItemTitle'] = barterItemTitle ?? '';
      json['barterItemDescription'] = barterItemDescription ?? '';
    }

    return json;
  }
}

class CounterOfferRequest {
  final OfferType offerType;
  final double? price;
  final String? currency;
  final String? barterItemTitle;
  final String? barterItemDescription;
  final List<String> barterItemImages;
  final List<String> barterWishCategories;

  CounterOfferRequest({
    required this.offerType,
    this.price,
    this.currency,
    this.barterItemTitle,
    this.barterItemDescription,
    this.barterItemImages = const [],
    this.barterWishCategories = const [],
  });

  Map<String, dynamic> toJson() {
    final json = {
      'offerType': offerType.value,
      'barterItemImages': barterItemImages,
      'barterWishCategories': barterWishCategories,
    };

    if (offerType == OfferType.PRICE) {
      json['price'] = price ?? '';
      json['currency'] = currency ?? 'USD';
      json['barterItemTitle'] = '';
      json['barterItemDescription'] = '';
    } else {
      json['price'] = '';
      json['barterItemTitle'] = barterItemTitle ?? '';
      json['barterItemDescription'] = barterItemDescription ?? '';
    }

    return json;
  }
}

class AcceptOfferRequest {
  final OfferType offerType;
  final double? price;
  final String? currency;
  final String? barterItemTitle;
  final String? barterItemDescription;
  final List<String> barterItemImages;
  final List<String> barterWishCategories;

  AcceptOfferRequest({
    required this.offerType,
    this.price,
    this.currency,
    this.barterItemTitle,
    this.barterItemDescription,
    this.barterItemImages = const [],
    this.barterWishCategories = const [],
  });

  Map<String, dynamic> toJson() {
    final json = {
      'offerType': offerType.value,
      'barterItemImages': barterItemImages,
      'barterWishCategories': barterWishCategories,
    };

    if (offerType == OfferType.PRICE) {
      json['price'] = price ?? '';
      json['currency'] = currency ?? 'USD';
      json['barterItemTitle'] = '';
      json['barterItemDescription'] = '';
    } else {
      json['price'] = '';
      json['barterItemTitle'] = barterItemTitle ?? '';
      json['barterItemDescription'] = barterItemDescription ?? '';
    }

    return json;
  }
}

class RejectOfferRequest {
  final OfferType offerType;
  final double? price;
  final String? currency;
  final String? barterItemTitle;
  final String? barterItemDescription;
  final List<String> barterItemImages;
  final List<String> barterWishCategories;

  RejectOfferRequest({
    required this.offerType,
    this.price,
    this.currency,
    this.barterItemTitle,
    this.barterItemDescription,
    this.barterItemImages = const [],
    this.barterWishCategories = const [],
  });

  Map<String, dynamic> toJson() {
    final json = {
      'offerType': offerType.value,
      'barterItemImages': barterItemImages,
      'barterWishCategories': barterWishCategories,
    };

    if (offerType == OfferType.PRICE) {
      json['price'] = price ?? '';
      json['currency'] = currency ?? 'USD';
      json['barterItemTitle'] = '';
      json['barterItemDescription'] = '';
    } else {
      json['price'] = '';
      json['barterItemTitle'] = barterItemTitle ?? '';
      json['barterItemDescription'] = barterItemDescription ?? '';
    }

    return json;
  }
}

class CompleteDealRequest {
  final String remarks;

  CompleteDealRequest({required this.remarks});

  Map<String, dynamic> toJson() {
    return {'remarks': remarks};
  }
}

class BlockUserRequest {
  final String userIdToBlock;

  BlockUserRequest({required this.userIdToBlock});

  Map<String, dynamic> toJson() {
    return {'userIdToBlock': userIdToBlock};
  }
}
