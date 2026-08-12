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

// Deal PIN verification enums — mirror DealVerificationMode /
// DealVerificationStatus from the backend exactly (see
// GET /trade-chat/{chatId}/deal/verification).
enum DealMode { MUTUAL, SEQUENTIAL }

extension DealModeExtension on DealMode {
  String get value {
    switch (this) {
      case DealMode.MUTUAL:
        return 'MUTUAL';
      case DealMode.SEQUENTIAL:
        return 'SEQUENTIAL';
    }
  }

  static DealMode fromString(String mode) {
    switch (mode) {
      case 'MUTUAL':
        return DealMode.MUTUAL;
      case 'SEQUENTIAL':
        return DealMode.SEQUENTIAL;
      default:
        return DealMode.MUTUAL;
    }
  }
}

enum DealStatus {
  INSPECTION,
  AWAITING_START,
  IN_PROGRESS,
  AWAITING_HANDOVER,
  COMPLETED,
  CANCELLED,
}

extension DealStatusExtension on DealStatus {
  String get value {
    switch (this) {
      case DealStatus.INSPECTION:
        return 'INSPECTION';
      case DealStatus.AWAITING_START:
        return 'AWAITING_START';
      case DealStatus.IN_PROGRESS:
        return 'IN_PROGRESS';
      case DealStatus.AWAITING_HANDOVER:
        return 'AWAITING_HANDOVER';
      case DealStatus.COMPLETED:
        return 'COMPLETED';
      case DealStatus.CANCELLED:
        return 'CANCELLED';
    }
  }

  static DealStatus fromString(String status) {
    switch (status) {
      case 'INSPECTION':
        return DealStatus.INSPECTION;
      case 'AWAITING_START':
        return DealStatus.AWAITING_START;
      case 'IN_PROGRESS':
        return DealStatus.IN_PROGRESS;
      case 'AWAITING_HANDOVER':
        return DealStatus.AWAITING_HANDOVER;
      case 'COMPLETED':
        return DealStatus.COMPLETED;
      case 'CANCELLED':
        return DealStatus.CANCELLED;
      default:
        return DealStatus.AWAITING_HANDOVER;
    }
  }
}

enum DealRole { INITIATOR, RESPONDER, PROVIDER, CONSUMER }

extension DealRoleExtension on DealRole {
  String get value {
    switch (this) {
      case DealRole.INITIATOR:
        return 'INITIATOR';
      case DealRole.RESPONDER:
        return 'RESPONDER';
      case DealRole.PROVIDER:
        return 'PROVIDER';
      case DealRole.CONSUMER:
        return 'CONSUMER';
    }
  }

  static DealRole fromString(String role) {
    switch (role) {
      case 'INITIATOR':
        return DealRole.INITIATOR;
      case 'RESPONDER':
        return DealRole.RESPONDER;
      case 'PROVIDER':
        return DealRole.PROVIDER;
      case 'CONSUMER':
        return DealRole.CONSUMER;
      default:
        return DealRole.INITIATOR;
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

// ==================== DEAL PIN VERIFICATION MODELS ====================

// Tolerant numeric parse — escrow amounts come from a Prisma Decimal field,
// which some backend responses pass through raw (serializing as a JSON
// string, e.g. "50.0000") while others explicitly convert to a number
// first. Handles either shape instead of assuming a native JSON number.
num? _parseFlexibleNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

// A single inspection proof photo.
class InspectionImage {
  final String url;
  final String uploadedById;
  final DateTime? uploadedAt;

  InspectionImage({
    required this.url,
    required this.uploadedById,
    this.uploadedAt,
  });

  factory InspectionImage.fromJson(Map<String, dynamic> json) {
    return InspectionImage(
      url: json['url'] ?? '',
      uploadedById: json['uploadedById'] ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'].toString())
          : null,
    );
  }

  static List<InspectionImage> listFromJson(dynamic images) {
    return (images as List? ?? [])
        .whereType<Map>()
        .map((img) => InspectionImage.fromJson(Map<String, dynamic>.from(img)))
        .toList();
  }
}

// Coin payment state for the deal's price leg, from the current user's view.
// Coins are now secured automatically in the background (when the payer
// confirms satisfied, or enters the Start PIN for a service) — there is no
// separate "fund" action for the UI to offer; `message` is reassurance copy
// to display, not a call to action.
class DealPayment {
  final bool required;
  final num? amount;
  final bool iAmPayer;
  final bool iAmPayee;
  final bool secured;
  final bool released;
  final String? message;

  DealPayment({
    required this.required,
    this.amount,
    required this.iAmPayer,
    required this.iAmPayee,
    required this.secured,
    required this.released,
    this.message,
  });

  factory DealPayment.fromJson(Map<String, dynamic> json) {
    return DealPayment(
      required: json['required'] == true,
      amount: _parseFlexibleNum(json['amount']),
      iAmPayer: json['iAmPayer'] == true,
      iAmPayee: json['iAmPayee'] == true,
      secured: json['secured'] == true,
      released: json['released'] == true,
      message: json['message'] as String?,
    );
  }
}

// Goods-inspection stage state, from the current user's view.
class DealInspection {
  final bool required;
  final bool active;
  // Only the inspector(s) for this scenario should see photo/satisfied UI —
  // e.g. only the buyer on a pure-price deal, both sides on a barter deal.
  final bool iAmInspector;
  // True while I'm an inspector, inspection is active, and I haven't
  // uploaded a photo yet — the "I'm satisfied" action must stay disabled.
  final bool mustAddPhoto;
  final int myPhotoCount;
  final List<InspectionImage> images;
  final bool iAmReady;
  // Null when the other party isn't an inspector at all for this scenario
  // (e.g. the seller on a pure-price deal) — not the same as "not ready".
  final bool? otherReady;
  final bool allReady;
  final bool waitingForOther;

  DealInspection({
    required this.required,
    required this.active,
    required this.iAmInspector,
    required this.mustAddPhoto,
    required this.myPhotoCount,
    required this.images,
    required this.iAmReady,
    this.otherReady,
    required this.allReady,
    required this.waitingForOther,
  });

  factory DealInspection.fromJson(Map<String, dynamic> json) {
    return DealInspection(
      required: json['required'] == true,
      active: json['active'] == true,
      iAmInspector: json['iAmInspector'] == true,
      mustAddPhoto: json['mustAddPhoto'] == true,
      myPhotoCount: json['myPhotoCount'] is int
          ? json['myPhotoCount'] as int
          : int.tryParse('${json['myPhotoCount'] ?? ''}') ?? 0,
      images: InspectionImage.listFromJson(json['images']),
      iAmReady: json['iAmReady'] == true,
      otherReady: json['otherReady'] as bool?,
      allReady: json['allReady'] == true,
      waitingForOther: json['waitingForOther'] == true,
    );
  }
}

// Which Deal PIN(s) have already been verified, from the current user's view.
class DealFlags {
  final bool initiatorPinVerified;
  final bool responderPinVerified;
  final bool startVerified;
  final bool completionVerified;

  DealFlags({
    required this.initiatorPinVerified,
    required this.responderPinVerified,
    required this.startVerified,
    required this.completionVerified,
  });

  factory DealFlags.fromJson(Map<String, dynamic> json) {
    return DealFlags(
      initiatorPinVerified: json['initiatorPinVerified'] == true,
      responderPinVerified: json['responderPinVerified'] == true,
      startVerified: json['startVerified'] == true,
      completionVerified: json['completionVerified'] == true,
    );
  }
}

// The full, per-user Deal PIN verification view — GET
// /trade-chat/{chatId}/deal/verification, and the same shape returned by
// every deal/* POST action (fund, inspection images/ready). This is the
// single source of truth for the Deal panel: drive all UI off
// mode/status/role, never hardcode per-scenario branches — the backend
// has already derived everything the client needs into this view.
class DealVerification {
  final String chatId;
  final String scenario;
  // Friendly exchange-mode descriptor fixed at the post-agreement point
  // (e.g. mode "BARTER_PLUS_COINS", label "Barter + Coins") — show
  // exchangeModeLabel as the deal header.
  final String? exchangeMode;
  final String? exchangeModeLabel;
  final DealMode mode;
  final DealStatus status;
  final bool completed;
  final DealRole role;
  final String? myPin;
  final String? myPinLabel;
  final bool awaitingMyEntry;
  final String? entryLabel;
  final DealFlags flags;
  final DealPayment payment;
  final DealInspection inspection;

  DealVerification({
    required this.chatId,
    required this.scenario,
    this.exchangeMode,
    this.exchangeModeLabel,
    required this.mode,
    required this.status,
    required this.completed,
    required this.role,
    this.myPin,
    this.myPinLabel,
    required this.awaitingMyEntry,
    this.entryLabel,
    required this.flags,
    required this.payment,
    required this.inspection,
  });

  factory DealVerification.fromJson(Map<String, dynamic> json) {
    return DealVerification(
      chatId: json['chatId'] ?? '',
      scenario: json['scenario'] ?? '',
      exchangeMode: json['exchangeMode'] as String?,
      exchangeModeLabel: json['exchangeModeLabel'] as String?,
      mode: DealModeExtension.fromString(json['mode'] ?? 'MUTUAL'),
      status: DealStatusExtension.fromString(
        json['status'] ?? 'AWAITING_HANDOVER',
      ),
      completed: json['completed'] == true,
      role: DealRoleExtension.fromString(json['role'] ?? 'INITIATOR'),
      myPin: json['myPin'] as String?,
      myPinLabel: json['myPinLabel'] as String?,
      awaitingMyEntry: json['awaitingMyEntry'] == true,
      entryLabel: json['entryLabel'] as String?,
      flags: DealFlags.fromJson(
        Map<String, dynamic>.from(json['flags'] ?? {}),
      ),
      payment: DealPayment.fromJson(
        Map<String, dynamic>.from(json['payment'] ?? {}),
      ),
      inspection: DealInspection.fromJson(
        Map<String, dynamic>.from(json['inspection'] ?? {}),
      ),
    );
  }

  bool get isGoodsMode => mode == DealMode.MUTUAL;
  bool get isServiceSequential => mode == DealMode.SEQUENTIAL;
}

// Lightweight, PIN-free snapshot embedded on every TradeChat (from the
// shared chat list/detail endpoints) — just enough to know a deal exists
// and roughly what stage it's at. Never carries myPin/awaitingMyEntry/etc;
// fetch DealVerification via TradeChatService.getDealVerification() for
// the actual panel content.
class DealVerificationSummary {
  final DealMode mode;
  final String scenario;
  final DealStatus status;
  final String? providerId;
  final String? consumerId;
  final String? payerId;
  final String? payeeId;
  final num? escrowAmount;
  final bool escrowFunded;
  final bool escrowReleased;
  final bool requiresInspection;
  final List<InspectionImage> inspectionImages;
  final bool initiatorReady;
  final bool responderReady;
  final bool initiatorPinVerified;
  final bool responderPinVerified;
  final bool startVerified;
  final bool completionVerified;
  final DateTime? completedAt;

  DealVerificationSummary({
    required this.mode,
    required this.scenario,
    required this.status,
    this.providerId,
    this.consumerId,
    this.payerId,
    this.payeeId,
    this.escrowAmount,
    required this.escrowFunded,
    required this.escrowReleased,
    required this.requiresInspection,
    required this.inspectionImages,
    required this.initiatorReady,
    required this.responderReady,
    required this.initiatorPinVerified,
    required this.responderPinVerified,
    required this.startVerified,
    required this.completionVerified,
    this.completedAt,
  });

  factory DealVerificationSummary.fromJson(Map<String, dynamic> json) {
    return DealVerificationSummary(
      mode: DealModeExtension.fromString(json['mode'] ?? 'MUTUAL'),
      scenario: json['scenario'] ?? '',
      status: DealStatusExtension.fromString(
        json['status'] ?? 'AWAITING_HANDOVER',
      ),
      providerId: json['providerId'] as String?,
      consumerId: json['consumerId'] as String?,
      payerId: json['payerId'] as String?,
      payeeId: json['payeeId'] as String?,
      escrowAmount: _parseFlexibleNum(json['escrowAmount']),
      escrowFunded: json['escrowFunded'] == true,
      escrowReleased: json['escrowReleased'] == true,
      requiresInspection: json['requiresInspection'] == true,
      inspectionImages: InspectionImage.listFromJson(json['inspectionImages']),
      initiatorReady: json['initiatorReady'] == true,
      responderReady: json['responderReady'] == true,
      initiatorPinVerified: json['initiatorPinVerified'] == true,
      responderPinVerified: json['responderPinVerified'] == true,
      startVerified: json['startVerified'] == true,
      completionVerified: json['completionVerified'] == true,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'].toString())
          : null,
    );
  }

  bool get isCompleted => status == DealStatus.COMPLETED;
}

// Result of POST /trade-chat/{chatId}/deal/verify-pin.
class DealPinVerifyResult {
  final bool success;
  final bool completed;
  final String message;

  DealPinVerifyResult({
    required this.success,
    required this.completed,
    required this.message,
  });

  factory DealPinVerifyResult.fromJson(Map<String, dynamic> json) {
    return DealPinVerifyResult(
      success: json['success'] == true,
      completed: json['completed'] == true,
      message: json['message'] ?? '',
    );
  }
}

// Result of POST /trade-chat/{chatId}/deal/close.
class DealCloseResult {
  final bool success;
  final String message;

  DealCloseResult({required this.success, required this.message});

  factory DealCloseResult.fromJson(Map<String, dynamic> json) {
    return DealCloseResult(
      success: json['success'] == true,
      message: json['message'] ?? '',
    );
  }
}

// ==================== EXCHANGE MODE SELECTION ====================
// GET /trade-chat/exchange-modes?productId=xxx|serviceId=xxx — options for
// the "How do you want to exchange?" offer sheet, including cross-mode
// requests (e.g. requesting a barter on a pure-price listing). Render
// entirely off `options`; `nativeMode` is just the listing's own default,
// not a restriction on what can be requested.

// One selectable exchange-mode card.
class ExchangeModeOption {
  final String mode; // PURE_COINS | PURE_BARTER | BARTER_PLUS_COINS | SERVICE_FOR_BARTER
  final String offerType; // PRICE | BARTER | BOTH — send this to the offer endpoint
  final String label;
  final bool requiresPrice;
  final bool requiresProductSelection;
  final String? productSelectionSource; // "MY_PRODUCTS" | null
  final bool isCrossMode;
  final String note;

  ExchangeModeOption({
    required this.mode,
    required this.offerType,
    required this.label,
    required this.requiresPrice,
    required this.requiresProductSelection,
    this.productSelectionSource,
    required this.isCrossMode,
    required this.note,
  });

  factory ExchangeModeOption.fromJson(Map<String, dynamic> json) {
    return ExchangeModeOption(
      mode: json['mode'] ?? '',
      offerType: json['offerType'] ?? 'PRICE',
      label: json['label'] ?? '',
      requiresPrice: json['requiresPrice'] == true,
      requiresProductSelection: json['requiresProductSelection'] == true,
      productSelectionSource: json['productSelectionSource'] as String?,
      isCrossMode: json['isCrossMode'] == true,
      note: json['note'] ?? '',
    );
  }
}

class ExchangeModeOptions {
  final String target; // "product" | "service"
  final String? productId;
  final String? serviceId;
  final String nativeMode; // PURE_PRICE | PURE_BARTER | BARTER_OR_PRICE
  final double? listingPrice;
  final String currency;
  final bool canRequest;
  final bool isOwner;
  final bool available;
  final List<ExchangeModeOption> options;

  ExchangeModeOptions({
    required this.target,
    this.productId,
    this.serviceId,
    required this.nativeMode,
    this.listingPrice,
    required this.currency,
    required this.canRequest,
    required this.isOwner,
    required this.available,
    required this.options,
  });

  factory ExchangeModeOptions.fromJson(Map<String, dynamic> json) {
    return ExchangeModeOptions(
      target: json['target'] ?? 'product',
      productId: json['productId'] as String?,
      serviceId: json['serviceId'] as String?,
      nativeMode: json['nativeMode'] ?? 'PURE_PRICE',
      listingPrice: json['listingPrice'] != null
          ? double.tryParse(json['listingPrice'].toString())
          : null,
      currency: json['currency'] ?? 'USD',
      canRequest: json['canRequest'] == true,
      isOwner: json['isOwner'] == true,
      available: json['available'] == true,
      options: (json['options'] as List? ?? [])
          .whereType<Map>()
          .map((o) => ExchangeModeOption.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
    );
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
  // PIN-free Deal PIN verification snapshot — null until an offer has been
  // accepted (or on chats predating this feature). Presence of this alone
  // is what decides whether ChatDetailScreen shows the Deal panel; the
  // actual PIN/entry content comes from a separate
  // TradeChatService.getDealVerification() call, never from here.
  final DealVerificationSummary? dealVerification;
  // Server-computed offer-eligibility for the requesting user (getChatDetail
  // only — list endpoints don't send these yet). Defaults preserve
  // pre-feature behavior until the first getChatDetail fetch lands.
  final bool canMakeOffer;
  final bool myPendingOffer;

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
    this.dealVerification,
    this.canMakeOffer = true,
    this.myPendingOffer = false,
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
      dealVerification: json['dealVerification'] != null
          ? DealVerificationSummary.fromJson(
              Map<String, dynamic>.from(json['dealVerification']),
            )
          : null,
      canMakeOffer: json.containsKey('canMakeOffer')
          ? json['canMakeOffer'] == true
          : true,
      myPendingOffer: json['myPendingOffer'] == true,
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
  // Whether the new Deal PIN flow applies to this chat — it exists once an
  // offer has been accepted. Chats without it fall back to the legacy
  // "Deal Ready to Complete" banner (see ChatDetailScreen).
  bool get hasDealVerification => dealVerification != null;

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
