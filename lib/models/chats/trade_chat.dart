import 'package:intl/intl.dart';

// Server timestamps arrive as UTC ISO-8601 strings. DateTime.parse keeps
// them tagged as UTC, and every display call site in this app formats the
// DateTime's own field values directly (no .toLocal()) — so without
// converting here, every chat/offer timestamp renders in UTC clock time
// instead of the device's local time, off by the local UTC offset.
// Converting once at parse time fixes every display site app-wide.
DateTime _parseLocal(String value) => DateTime.parse(value).toLocal();
DateTime? _tryParseLocal(String? value) =>
    value == null ? null : DateTime.tryParse(value)?.toLocal();

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
// Deal status from the backend exactly (see
// GET /trade-chat/{chatId}/deal/verification). No PIN, no photos: a deal is
// either awaiting mutual "Deal Completed" consent, or completed.
enum DealStatus { AWAITING_HANDOVER, COMPLETED }

extension DealStatusExtension on DealStatus {
  String get value {
    switch (this) {
      case DealStatus.AWAITING_HANDOVER:
        return 'AWAITING_HANDOVER';
      case DealStatus.COMPLETED:
        return 'COMPLETED';
    }
  }

  static DealStatus fromString(String status) {
    switch (status) {
      case 'COMPLETED':
        return DealStatus.COMPLETED;
      default:
        return DealStatus.AWAITING_HANDOVER;
    }
  }
}

enum DealRole { INITIATOR, RESPONDER }

extension DealRoleExtension on DealRole {
  String get value {
    switch (this) {
      case DealRole.INITIATOR:
        return 'INITIATOR';
      case DealRole.RESPONDER:
        return 'RESPONDER';
    }
  }

  static DealRole fromString(String role) {
    switch (role) {
      case 'RESPONDER':
        return DealRole.RESPONDER;
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

// The actual product being OFFERED in a barter (as opposed to ProductInfo,
// which is the listing being bartered FOR). Resolved server-side from an
// offer's barterProductIds — see TradeOffer.barterProducts.
class BarterProductInfo {
  final String id;
  final String title;
  final List<String> images;
  final double? price;
  final String status;
  final String? postedById;

  BarterProductInfo({
    required this.id,
    required this.title,
    required this.images,
    this.price,
    required this.status,
    this.postedById,
  });

  factory BarterProductInfo.fromJson(Map<String, dynamic> json) {
    return BarterProductInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      images: (json['images'] as List? ?? []).map((e) => e.toString()).toList(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
      status: json['status'] ?? '',
      postedById: json['postedById'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'images': images,
      'price': price,
      'status': status,
      'postedById': postedById,
    };
  }

  String get firstImage => images.isNotEmpty ? images.first : '';
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

// The product/service the whole negotiation is anchored to — present on
// every offer/counter-offer, including coins-only counters with no barter
// items of their own. Distinct from BarterProductInfo, which is the item(s)
// actually offered in exchange.
class OfferListing {
  final String postType; // 'product' | 'service'
  final String? productId;
  final String? serviceId;
  final String title;
  final String? image;
  final double? price;

  OfferListing({
    required this.postType,
    this.productId,
    this.serviceId,
    required this.title,
    this.image,
    this.price,
  });

  factory OfferListing.fromJson(Map<String, dynamic> json) {
    return OfferListing(
      postType: json['postType'] ?? '',
      productId: json['productId'] as String?,
      serviceId: json['serviceId'] as String?,
      title: json['title'] ?? '',
      image: json['image'] as String?,
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postType': postType,
      'productId': productId,
      'serviceId': serviceId,
      'title': title,
      'image': image,
      'price': price,
    };
  }
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
  // Structured discriminator for SYSTEM messages — lets the client render a
  // distinct styled card per lifecycle event instead of plain text. Null for
  // TEXT/IMAGE/OFFER messages, and for older SYSTEM messages predating this.
  final String? eventType;
  final Map<String, dynamic>? eventData;

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
    this.eventType,
    this.eventData,
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
      readAt: _tryParseLocal(json['readAt']),
      createdAt: _parseLocal(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      offerId: json['offerId'],
      eventType: json['eventType'] as String?,
      eventData: json['eventData'] is Map
          ? Map<String, dynamic>.from(json['eventData'] as Map)
          : null,
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
      'eventType': eventType,
      'eventData': eventData,
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

// Pull the wall-clock date/time straight out of the ISO string's TEXT — the
// server stores/returns the picked slot as a naive wall clock (not a real
// timezone-aware instant), so parsing it as a DateTime and calling
// .toLocal()/.toUtc() re-interprets those digits against the device's
// timezone and silently shifts them (a 12:30 booking reading back as
// 5:30). Regex-extracting the digits as printed is the only safe way to
// display it. Falls back to '--' if the string doesn't parse at all.
String? _extractDatePart(String? iso) {
  if (iso == null) return null;
  final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(iso);
  return match?.group(1);
}

String? _extractTimePart(String? iso) {
  if (iso == null) return null;
  final match = RegExp(r'T(\d{2}:\d{2})').firstMatch(iso);
  return match?.group(1);
}

String? _addMinutesToHHmm(String? hhmm, int? minutes) {
  if (hhmm == null || minutes == null) return null;
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  final total = (h * 60 + m + minutes) % (24 * 60);
  final endH = total ~/ 60;
  final endM = total % 60;
  return '${endH.toString().padLeft(2, '0')}:${endM.toString().padLeft(2, '0')}';
}

// A booked slot attached to a scheduled (Pure Coins) service offer — either
// on the offer itself (serviceAppointment) or the lightweight snapshot on
// TradeChat.appointment (same shape, sourced from the live/accepted offer).
class ServiceAppointmentSnapshot {
  final String id;
  // Raw ISO string, kept only as a fallback/for sorting — NEVER call
  // .toLocal()/.toUtc() on it for display. Use slotDate/slotTime/slotEndTime
  // (or the display getters below) instead.
  final String? appointmentDateRaw;
  final int? duration;
  final String? location;
  final String? status;
  final int rescheduleCount;
  final String? previousAppointmentDateRaw;
  // Server-provided wall-clock strings when the endpoint decorates them
  // (appointment list/reschedule endpoints); regex-derived from the raw ISO
  // string otherwise so display never depends on device timezone.
  final String? slotDate;
  final String? slotTime;
  final String? slotEndTime;

  ServiceAppointmentSnapshot({
    required this.id,
    this.appointmentDateRaw,
    this.duration,
    this.location,
    this.status,
    this.rescheduleCount = 0,
    this.previousAppointmentDateRaw,
    this.slotDate,
    this.slotTime,
    this.slotEndTime,
  });

  factory ServiceAppointmentSnapshot.fromJson(Map<String, dynamic> json) {
    final rawDate = json['appointmentDate']?.toString();
    final slotTime = json['slotTime']?.toString() ?? _extractTimePart(rawDate);
    final duration = json['duration'] is num ? (json['duration'] as num).toInt() : null;
    return ServiceAppointmentSnapshot(
      id: json['id']?.toString() ?? '',
      appointmentDateRaw: rawDate,
      duration: duration,
      location: json['location']?.toString(),
      status: json['status']?.toString(),
      rescheduleCount: json['rescheduleCount'] is num
          ? (json['rescheduleCount'] as num).toInt()
          : 0,
      previousAppointmentDateRaw: json['previousAppointmentDate']?.toString(),
      slotDate: json['slotDate']?.toString() ?? _extractDatePart(rawDate),
      slotTime: slotTime,
      slotEndTime:
          json['slotEndTime']?.toString() ?? _addMinutesToHHmm(slotTime, duration),
    );
  }

  // "2026-09-03" -> "Sep 3, 2026". Falls back to the raw key if it doesn't
  // parse (never via DateTime timezone conversion — just a display format).
  String get displayDate {
    if (slotDate == null) return '--';
    final parts = slotDate!.split('-');
    if (parts.length != 3) return slotDate!;
    final y = int.tryParse(parts[0]);
    final mo = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || mo == null || d == null) return slotDate!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (mo < 1 || mo > 12) return slotDate!;
    return '${months[mo - 1]} $d, $y';
  }

  // "14:30" -> "2:30 PM".
  static String _displayTimeOf(String? hhmm) {
    if (hhmm == null) return '--';
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return hhmm;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayHour = h % 12 == 0 ? 12 : h % 12;
    return '$displayHour:${m.toString().padLeft(2, '0')} $period';
  }

  String get displayTime => _displayTimeOf(slotTime);
  String get displayEndTime => _displayTimeOf(slotEndTime);
  String get displayDateTime => '$displayDate • $displayTime';
}

// One product or service on either side of the trade — used for display
// only (thumbnail + title + price), never to validate the deal.
class TradeExchangeItem {
  final String type; // "product" | "service"
  final String id;
  final String title;
  final String? image;
  final double? price;

  TradeExchangeItem({
    required this.type,
    required this.id,
    required this.title,
    this.image,
    this.price,
  });

  factory TradeExchangeItem.fromJson(Map<String, dynamic> json) {
    return TradeExchangeItem(
      type: json['type']?.toString() ?? '',
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      image: json['image']?.toString(),
      price: json['price'] != null
          ? double.tryParse(json['price'].toString())
          : null,
    );
  }
}

// One half of a trade — what one side is putting on the table (products,
// services, coins) or, for `askedFor`, the listing itself. Values are never
// compared/validated here; this is purely a "here's what's on the table"
// snapshot for the receiver to look at and accept or reject.
class TradeExchangeSide {
  final String? userId;
  final List<TradeExchangeItem> products;
  final List<TradeExchangeItem> services;
  final double coins;
  // Free text: for a service, the offerer's description of the work they
  // will do (e.g. "I will rewire two rooms") — the only sensible
  // description for something that isn't a listed item.
  final String? note;
  final String? itemTitle;
  final OfferListing? listing;
  final String summary;

  TradeExchangeSide({
    this.userId,
    this.products = const [],
    this.services = const [],
    this.coins = 0,
    this.note,
    this.itemTitle,
    this.listing,
    required this.summary,
  });

  factory TradeExchangeSide.fromJson(Map<String, dynamic> json) {
    return TradeExchangeSide(
      userId: json['userId']?.toString(),
      products: (json['products'] as List? ?? [])
          .whereType<Map>()
          .map((p) => TradeExchangeItem.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      services: (json['services'] as List? ?? [])
          .whereType<Map>()
          .map((s) => TradeExchangeItem.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      coins: double.tryParse(json['coins']?.toString() ?? '') ?? 0,
      note: json['note']?.toString(),
      itemTitle: json['itemTitle']?.toString(),
      listing: json['listing'] is Map
          ? OfferListing.fromJson(Map<String, dynamic>.from(json['listing'] as Map))
          : null,
      summary: json['summary']?.toString() ?? '',
    );
  }

  // Every item on this side, products and services together, for a single
  // "one tile per item" render.
  List<TradeExchangeItem> get allItems => [...products, ...services];
}

// Both halves of the trade, spelled out — offer.exchange.offeredBy /
// .askedFor. See TradeOffer.youGive/.youGet for the viewer-relative version.
class TradeExchange {
  final TradeExchangeSide offeredBy;
  final TradeExchangeSide askedFor;

  TradeExchange({required this.offeredBy, required this.askedFor});

  factory TradeExchange.fromJson(Map<String, dynamic> json) {
    return TradeExchange(
      offeredBy: TradeExchangeSide.fromJson(
        Map<String, dynamic>.from(json['offeredBy'] ?? {}),
      ),
      askedFor: TradeExchangeSide.fromJson(
        Map<String, dynamic>.from(json['askedFor'] ?? {}),
      ),
    );
  }
}

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
  // Real Product ids (owned by madeBy) offered in exchange — lets the
  // client look up the offered item's actual listed price and deep-link to
  // its post detail, the same way the chat's own product/service already does.
  final List<String> barterProductIds;
  // The actually-OFFERED products, resolved server-side from
  // barterProductIds — distinct from chat.product (the listing being
  // bartered FOR). Render these for the offer preview instead of
  // barterItemTitle/barterItemImages so the chat never shows the listing
  // product as if it were the offered item. Empty for free-text-only offers.
  final List<BarterProductInfo> barterProducts;
  // Combined coin value of every product in barterProducts.
  final double barterProductsTotalValue;
  // Same idea as barterProductIds/barterProducts, but for the offerer's own
  // SERVICES offered in exchange (service-only barter/both offers).
  final List<String> barterServiceIds;
  final List<BarterProductInfo> barterServices;
  final double barterServicesTotalValue;
  // barterProductsTotalValue + barterServicesTotalValue + the coin top-up
  // (price) for a Barter + Coins offer — the grand total value of the offer.
  final double offerTotalValue;
  final int counterOfferCount;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;
  // A "no coins involved" request — item-for-item, or asking/giving for
  // free. Never carries a price, and (per product decision) can't be
  // countered — only accepted or rejected.
  final bool isZeroCoin;
  // The listing this offer/counter is anchored to — see OfferListing. Null
  // only for offers fetched before the backend started sending this field.
  final OfferListing? listing;
  // The booked slot for a scheduled (Pure Coins) service offer. Null for
  // every other offer type/flow.
  final ServiceAppointmentSnapshot? serviceAppointment;
  // Both halves of the trade spelled out server-side (offeredBy/askedFor).
  // Prefer youGive/youGet for display — same data, already swapped to this
  // viewer's perspective.
  final TradeExchange? exchange;
  // Viewer-relative: youGive is whichever side (offeredBy/askedFor) THIS
  // user is giving up, youGet is the other. Null until the backend
  // computes it (needs to know who's viewing), which it does whenever this
  // offer is fetched as part of a chat for a specific user.
  final TradeExchangeSide? youGive;
  final TradeExchangeSide? youGet;
  // Ready-made copy: "You give X · You get Y". Render as-is.
  final String? exchangeSummary;

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
    this.barterProductIds = const [],
    this.barterProducts = const [],
    this.barterProductsTotalValue = 0,
    this.barterServiceIds = const [],
    this.barterServices = const [],
    this.barterServicesTotalValue = 0,
    this.offerTotalValue = 0,
    required this.counterOfferCount,
    required this.createdAt,
    this.acceptedAt,
    this.rejectedAt,
    this.isZeroCoin = false,
    this.listing,
    this.serviceAppointment,
    this.exchange,
    this.youGive,
    this.youGet,
    this.exchangeSummary,
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
      barterProductIds: (json['barterProductIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      barterProducts: (json['barterProducts'] as List? ?? [])
          .whereType<Map>()
          .map((p) => BarterProductInfo.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      barterProductsTotalValue:
          double.tryParse(json['barterProductsTotalValue']?.toString() ?? '') ??
              0,
      barterServiceIds: (json['barterServiceIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      barterServices: (json['barterServices'] as List? ?? [])
          .whereType<Map>()
          .map((s) => BarterProductInfo.fromJson(Map<String, dynamic>.from(s)))
          .toList(),
      barterServicesTotalValue:
          double.tryParse(json['barterServicesTotalValue']?.toString() ?? '') ??
              0,
      offerTotalValue:
          double.tryParse(json['offerTotalValue']?.toString() ?? '') ?? 0,
      counterOfferCount: json['counterOfferCount'] ?? 0,
      createdAt: _parseLocal(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      acceptedAt: _tryParseLocal(json['acceptedAt']),
      rejectedAt: _tryParseLocal(json['rejectedAt']),
      isZeroCoin: json['isZeroCoin'] == true,
      listing: json['listing'] is Map
          ? OfferListing.fromJson(Map<String, dynamic>.from(json['listing'] as Map))
          : null,
      serviceAppointment: json['serviceAppointment'] is Map
          ? ServiceAppointmentSnapshot.fromJson(
              Map<String, dynamic>.from(json['serviceAppointment'] as Map),
            )
          : null,
      exchange: json['exchange'] is Map
          ? TradeExchange.fromJson(Map<String, dynamic>.from(json['exchange'] as Map))
          : null,
      youGive: json['youGive'] is Map
          ? TradeExchangeSide.fromJson(Map<String, dynamic>.from(json['youGive'] as Map))
          : null,
      youGet: json['youGet'] is Map
          ? TradeExchangeSide.fromJson(Map<String, dynamic>.from(json['youGet'] as Map))
          : null,
      exchangeSummary: json['exchangeSummary']?.toString(),
    );
  }

  // Preserves every field not explicitly overridden — see TradeChat.copyWith
  // for why: patching just offerStatus/acceptedAt/rejectedAt via the plain
  // TradeOffer(...) constructor silently resets any field the call site
  // forgets to list (isZeroCoin included) back to its default.
  TradeOffer copyWith({
    String? id,
    String? tradeChatId,
    String? madeById,
    UserInfo? madeBy,
    OfferType? offerType,
    OfferStatus? offerStatus,
    double? price,
    String? currency,
    String? barterItemTitle,
    String? barterItemDescription,
    List<String>? barterItemImages,
    List<String>? barterWishCategories,
    List<String>? barterProductIds,
    List<BarterProductInfo>? barterProducts,
    double? barterProductsTotalValue,
    List<String>? barterServiceIds,
    List<BarterProductInfo>? barterServices,
    double? barterServicesTotalValue,
    double? offerTotalValue,
    int? counterOfferCount,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
    bool? isZeroCoin,
    OfferListing? listing,
    ServiceAppointmentSnapshot? serviceAppointment,
    TradeExchange? exchange,
    TradeExchangeSide? youGive,
    TradeExchangeSide? youGet,
    String? exchangeSummary,
  }) {
    return TradeOffer(
      id: id ?? this.id,
      tradeChatId: tradeChatId ?? this.tradeChatId,
      madeById: madeById ?? this.madeById,
      madeBy: madeBy ?? this.madeBy,
      offerType: offerType ?? this.offerType,
      offerStatus: offerStatus ?? this.offerStatus,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      barterItemTitle: barterItemTitle ?? this.barterItemTitle,
      barterItemDescription:
          barterItemDescription ?? this.barterItemDescription,
      barterItemImages: barterItemImages ?? this.barterItemImages,
      barterWishCategories: barterWishCategories ?? this.barterWishCategories,
      barterProductIds: barterProductIds ?? this.barterProductIds,
      barterProducts: barterProducts ?? this.barterProducts,
      barterProductsTotalValue:
          barterProductsTotalValue ?? this.barterProductsTotalValue,
      barterServiceIds: barterServiceIds ?? this.barterServiceIds,
      barterServices: barterServices ?? this.barterServices,
      barterServicesTotalValue:
          barterServicesTotalValue ?? this.barterServicesTotalValue,
      offerTotalValue: offerTotalValue ?? this.offerTotalValue,
      counterOfferCount: counterOfferCount ?? this.counterOfferCount,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      isZeroCoin: isZeroCoin ?? this.isZeroCoin,
      listing: listing ?? this.listing,
      serviceAppointment: serviceAppointment ?? this.serviceAppointment,
      exchange: exchange ?? this.exchange,
      youGive: youGive ?? this.youGive,
      youGet: youGet ?? this.youGet,
      exchangeSummary: exchangeSummary ?? this.exchangeSummary,
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
      'barterProductIds': barterProductIds,
      'barterProducts': barterProducts.map((p) => p.toJson()).toList(),
      'barterProductsTotalValue': barterProductsTotalValue,
      'barterServiceIds': barterServiceIds,
      'barterServices': barterServices.map((s) => s.toJson()).toList(),
      'barterServicesTotalValue': barterServicesTotalValue,
      'offerTotalValue': offerTotalValue,
      'counterOfferCount': counterOfferCount,
      'createdAt': createdAt.toIso8601String(),
      'acceptedAt': acceptedAt?.toIso8601String(),
      'rejectedAt': rejectedAt?.toIso8601String(),
      'isZeroCoin': isZeroCoin,
      'listing': listing?.toJson(),
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

  // Offered products AND services together — render with the same tile,
  // per the service-flow spec ("Render offered services with the same tile
  // as products").
  List<BarterProductInfo> get combinedBarterItems => [
    ...barterProducts,
    ...barterServices,
  ];
  double get combinedBarterItemsTotalValue =>
      barterProductsTotalValue + barterServicesTotalValue;

  // Plain number, no $/USD — whole numbers with no decimals (130), up to 2
  // decimals only when fractional (135.5), "coin" singular for exactly 1.
  static String _coinsLabel(double value) {
    final formatted = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(2);
    final isSingular = value == 1 || value == -1;
    return '$formatted ${isSingular ? 'coin' : 'coins'}';
  }

  String get offerSummary {
    if (isPriceOffer && price != null) {
      return 'Price: ${_coinsLabel(price!)}';
    } else if (isBarterOffer || isBothOffer) {
      final itemSummary = 'Barter: ${barterItemTitle ?? 'Item'}';
      if (isBothOffer && price != null && price! > 0) {
        return '$itemSummary + ${_coinsLabel(price!)}';
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
      initiatorCompletedAt:
          _tryParseLocal(json['initiatorCompletedAt']?.toString()),
      responderCompleted: json['responderCompleted'] == true,
      responderCompletedAt:
          _tryParseLocal(json['responderCompletedAt']?.toString()),
      dealCompletedAt: _tryParseLocal(json['dealCompletedAt']?.toString()),
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

// Mutual completion progress for the deal — drives the "Deal Completed"
// button. Both users must tap it (canComplete flips false for a user once
// they have); either user's "Deal Not Completed" cancels at any time.
class DealCompletion {
  final bool iCompleted;
  final bool otherCompleted;
  final bool bothCompleted;
  final DateTime? completedAt;
  final bool canComplete;

  DealCompletion({
    required this.iCompleted,
    required this.otherCompleted,
    required this.bothCompleted,
    this.completedAt,
    required this.canComplete,
  });

  factory DealCompletion.fromJson(Map<String, dynamic> json) {
    return DealCompletion(
      iCompleted: json['iCompleted'] == true,
      otherCompleted: json['otherCompleted'] == true,
      bothCompleted: json['bothCompleted'] == true,
      completedAt: _tryParseLocal(json['completedAt']?.toString()),
      canComplete: json['canComplete'] == true,
    );
  }
}

// The per-user deal summary — GET /trade-chat/{chatId}/deal/verification.
// PIN-free, photo-free: single source of truth for the Deal panel, which is
// just an exchange-mode header, a background payment info banner, and the
// mutual "Deal Completed" / "Deal Not Completed" buttons.
// Server-computed copy for the "Deal Not Completed" reason dialog — already
// worded per product vs service and provider vs client side, so render it
// verbatim rather than re-deriving wording client-side.
class CloseDealPrompt {
  final String title;
  final String placeholder;
  final String helperText;
  final bool required;
  final int maxLength;
  final List<String> suggestions;

  CloseDealPrompt({
    required this.title,
    required this.placeholder,
    required this.helperText,
    required this.required,
    required this.maxLength,
    required this.suggestions,
  });

  factory CloseDealPrompt.fromJson(Map<String, dynamic> json) {
    return CloseDealPrompt(
      title: json['title']?.toString() ?? 'Deal Not Completed',
      placeholder: json['placeholder']?.toString() ?? '',
      helperText: json['helperText']?.toString() ?? '',
      required: json['required'] == true,
      maxLength: json['maxLength'] is num
          ? (json['maxLength'] as num).toInt()
          : 500,
      suggestions: (json['suggestions'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

class DealVerification {
  final String chatId;
  final String scenario;
  // Friendly exchange-mode descriptor fixed at the post-agreement point
  // (e.g. mode "BARTER_PLUS_COINS", label "Barter + Coins") — show
  // exchangeModeLabel as the deal header.
  final String? exchangeMode;
  final String? exchangeModeLabel;
  final DealStatus status;
  final bool completed;
  final DealRole role;
  final DealPayment payment;
  final DealCompletion completion;
  final CloseDealPrompt? closeDealPrompt;

  DealVerification({
    required this.chatId,
    required this.scenario,
    this.exchangeMode,
    this.exchangeModeLabel,
    required this.status,
    required this.completed,
    required this.role,
    required this.payment,
    required this.completion,
    this.closeDealPrompt,
  });

  factory DealVerification.fromJson(Map<String, dynamic> json) {
    return DealVerification(
      chatId: json['chatId'] ?? '',
      scenario: json['scenario'] ?? '',
      exchangeMode: json['exchangeMode'] as String?,
      exchangeModeLabel: json['exchangeModeLabel'] as String?,
      status: DealStatusExtension.fromString(
        json['status'] ?? 'AWAITING_HANDOVER',
      ),
      completed: json['completed'] == true,
      role: DealRoleExtension.fromString(json['role'] ?? 'INITIATOR'),
      payment: DealPayment.fromJson(
        Map<String, dynamic>.from(json['payment'] ?? {}),
      ),
      completion: DealCompletion.fromJson(
        Map<String, dynamic>.from(json['completion'] ?? {}),
      ),
      closeDealPrompt: json['closeDealPrompt'] is Map
          ? CloseDealPrompt.fromJson(
              Map<String, dynamic>.from(json['closeDealPrompt'] as Map),
            )
          : null,
    );
  }
}

// Lightweight, no-PIN snapshot embedded on every TradeChat (from the shared
// chat list/detail endpoints) — just enough to know a deal exists and its
// coarse status. Fetch DealVerification via
// TradeChatService.getDealVerification() for the actual panel content.
class DealVerificationSummary {
  final String scenario;
  final DealStatus status;
  final String? payerId;
  final String? payeeId;
  final num? escrowAmount;
  final bool escrowFunded;
  final bool escrowReleased;
  final DateTime? completedAt;

  DealVerificationSummary({
    required this.scenario,
    required this.status,
    this.payerId,
    this.payeeId,
    this.escrowAmount,
    required this.escrowFunded,
    required this.escrowReleased,
    this.completedAt,
  });

  factory DealVerificationSummary.fromJson(Map<String, dynamic> json) {
    return DealVerificationSummary(
      scenario: json['scenario'] ?? '',
      status: DealStatusExtension.fromString(
        json['status'] ?? 'AWAITING_HANDOVER',
      ),
      payerId: json['payerId'] as String?,
      payeeId: json['payeeId'] as String?,
      escrowAmount: _parseFlexibleNum(json['escrowAmount']),
      escrowFunded: json['escrowFunded'] == true,
      escrowReleased: json['escrowReleased'] == true,
      completedAt: _tryParseLocal(json['completedAt']?.toString()),
    );
  }

  bool get isCompleted => status == DealStatus.COMPLETED;
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
  // Services only — a barter/both option may let the requester offer one of
  // their own SERVICES in addition to (or instead of) a product.
  final bool requiresServiceSelection;
  final String? serviceSelectionSource; // "MY_SERVICES" | null
  // SCHEDULED = pick a slot, owner confirms (Pure Coins on a service).
  // DIRECT = barter/both, no slot, owner just accepts/rejects. Null for
  // product options, which don't carry this concept.
  final String? flow;
  final bool requiresSlotSelection;
  // Only meaningful when requiresSlotSelection is true — false means the
  // provider hasn't saved a weekly schedule yet, so the slot step should be
  // disabled and `note` explains why.
  final bool schedulingConfigured;
  // Minimum combined count across product + service selections required
  // (services only — e.g. "at least one of either list").
  final int? selectionMinimum;
  // True on Pure Coins (and Barter/Service + Coins) for a service: the coin
  // amount is entirely free-form — the requester types whatever they want to
  // offer, never pre-filled read-only from the listing price, never capped
  // or validated against it. The owner decides whether it's enough.
  final bool priceIsNegotiable;
  // Per-mode: whether an offer made in THIS mode can later be countered.
  // Distinct from the top-level ExchangeModeOptions.supportsCounterOffer,
  // which is just "is any mode on this listing counterable at all" — a
  // service's Pure Coins and pure-barter modes are still accept/reject only
  // even though Barter/Service + Coins on the same listing is counterable.
  final bool supportsCounterOffer;

  ExchangeModeOption({
    required this.mode,
    required this.offerType,
    required this.label,
    required this.requiresPrice,
    required this.requiresProductSelection,
    this.productSelectionSource,
    required this.isCrossMode,
    required this.note,
    this.requiresServiceSelection = false,
    this.serviceSelectionSource,
    this.flow,
    this.requiresSlotSelection = false,
    this.schedulingConfigured = true,
    this.selectionMinimum,
    this.priceIsNegotiable = false,
    this.supportsCounterOffer = false,
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
      requiresServiceSelection: json['requiresServiceSelection'] == true,
      serviceSelectionSource: json['serviceSelectionSource'] as String?,
      priceIsNegotiable: json['priceIsNegotiable'] == true,
      supportsCounterOffer: json['supportsCounterOffer'] == true,
      flow: json['flow'] as String?,
      requiresSlotSelection: json['requiresSlotSelection'] == true,
      schedulingConfigured: json.containsKey('schedulingConfigured')
          ? json['schedulingConfigured'] == true
          : true,
      selectionMinimum: json['selectionMinimum'] is num
          ? (json['selectionMinimum'] as num).toInt()
          : null,
    );
  }

  bool get isScheduled => flow == 'SCHEDULED';
  bool get isDirect => flow == 'DIRECT';
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
  // Services only — whether the provider has saved a weekly schedule at
  // all. When false, the Pure Coins option's slot step should be disabled
  // (its own `note` already explains this to the user).
  final bool schedulingConfigured;
  // Services never support countering an offer — the owner accepts or
  // rejects, and the requester may then offer again in any mode. Defaults
  // true (the product behavior) for responses that predate this field.
  final bool supportsCounterOffer;
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
    this.schedulingConfigured = true,
    this.supportsCounterOffer = true,
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
      schedulingConfigured: json.containsKey('schedulingConfigured')
          ? json['schedulingConfigured'] == true
          : true,
      supportsCounterOffer: json.containsKey('supportsCounterOffer')
          ? json['supportsCounterOffer'] == true
          : true,
      options: (json['options'] as List? ?? [])
          .whereType<Map>()
          .map((o) => ExchangeModeOption.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
    );
  }

  bool get isService => target == 'service';
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
  // The other participant's id — sent on both getChatDetail and every list
  // endpoint (all/inbox/outbox) alongside otherUserOnline. Prefer this over
  // getOtherUserInfo() when only the id is needed (e.g. list rows).
  final String? otherUserId;
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
  // getChatDetail only: true once the listing itself is gone because a deal
  // completed in a *different* chat on the same item — distinct from
  // canMakeOffer being false for this chat's own reasons (pending/accepted).
  final bool listingUnavailable;
  // getChatDetail only: true when the current user is the listing owner
  // (responder) — server-authoritative version of what the client used to
  // derive itself from responderId. The owner only accepts/rejects/counters;
  // they never start a fresh offer, so canMakeOffer is already false for
  // them, but this flag lets other owner-only UI decisions (e.g. skipping
  // the buyer's wallet check) key off it directly.
  final bool isOwner;
  // getChatDetail only: true while ANY offer (either party) is PENDING —
  // i.e. a negotiation is currently in progress. canMakeOffer already
  // factors this in, but exposed separately for UI that wants to explain
  // *why* offering again isn't available right now.
  final bool hasPendingOffer;
  // getChatDetail only: true when either side has blocked the other.
  // canMakeOffer already factors this in, but the client needs this
  // separately to hide the composer/gallery/accept/reject/counter/deal
  // actions entirely (not just the offer button) while blocked.
  final bool isBlocked;
  // getChatDetail only: product ids already committed to the live pending
  // offer (sourced from the newest PENDING offer's barterProductIds). The
  // counter-offer product picker should exclude these so a product already
  // being bartered can't be selected again. Empty when there's no pending
  // offer.
  final List<String> activeBarterProductIds;
  // Same idea, for services offered on the live pending offer.
  final List<String> activeBarterServiceIds;
  // getChatDetail only: true whenever this chat is on a service (serviceId
  // set) — server-authoritative, prefer this over deriving it locally.
  final bool isServiceChat;
  // SCHEDULED (Pure Coins, slot-based) | DIRECT (barter/both, no slot) |
  // null until the first offer exists. Derived from the live/accepted offer.
  final String? serviceFlow;
  // Services never support countering — the owner only accepts/rejects, and
  // the API 400s a counter attempt. Always false for a non-service chat too
  // (counter offers on products use canMakeOffer/hasPendingOffer instead).
  final bool canCounterOffer;
  // True when there's a pending offer awaiting THIS user's response
  // (accept/reject) — use pendingOfferIdForMe for the actual API call
  // rather than inferring which offer that is client-side.
  final bool canRespondToOffer;
  final String? pendingOfferIdForMe;
  // The booked slot for the scheduled service flow, sourced from the
  // live/accepted offer — lets the chat header show it without a second
  // call. Null for non-scheduled chats or before any offer exists.
  final ServiceAppointmentSnapshot? appointment;
  // List endpoints only (getChatDetail doesn't send these): server-derived
  // status chip for the chat row — PENDING | ACTIVE | COMPLETED |
  // NOT_COMPLETED, with badgeLabel as ready-to-render display copy.
  final String? badge;
  final String? badgeLabel;

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
    this.otherUserId,
    this.unreadCount,
    this.dealVerification,
    this.canMakeOffer = true,
    this.myPendingOffer = false,
    this.isOwner = false,
    this.hasPendingOffer = false,
    this.isBlocked = false,
    this.activeBarterProductIds = const [],
    this.activeBarterServiceIds = const [],
    this.isServiceChat = false,
    this.serviceFlow,
    this.canCounterOffer = false,
    this.canRespondToOffer = false,
    this.pendingOfferIdForMe,
    this.appointment,
    this.listingUnavailable = false,
    this.badge,
    this.badgeLabel,
  });

  factory TradeChat.fromJson(Map<String, dynamic> json) {
    return TradeChat(
      id: json['id'] ?? '',
      initiatorId: json['initiatorId'] ?? '',
      responderId: json['responderId'] ?? '',
      productId: json['productId'],
      serviceId: json['serviceId'],
      status: ChatStatusExtension.fromString(json['status'] ?? 'ACTIVE'),
      lastMessageAt: _tryParseLocal(json['lastMessageAt']),
      createdAt: _parseLocal(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: _parseLocal(
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
      otherUserId: json['otherUserId'] as String?,
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
      listingUnavailable: json['listingUnavailable'] == true,
      isOwner: json['isOwner'] == true,
      hasPendingOffer: json['hasPendingOffer'] == true,
      isBlocked: json['isBlocked'] == true,
      activeBarterProductIds: (json['activeBarterProductIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      activeBarterServiceIds: (json['activeBarterServiceIds'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      isServiceChat: json['isServiceChat'] == true ||
          (json['serviceId'] != null &&
              json['serviceId'].toString().isNotEmpty),
      serviceFlow: json['serviceFlow'] as String?,
      canCounterOffer: json['canCounterOffer'] == true,
      canRespondToOffer: json['canRespondToOffer'] == true,
      pendingOfferIdForMe: json['pendingOfferIdForMe'] as String?,
      appointment: json['appointment'] is Map
          ? ServiceAppointmentSnapshot.fromJson(
              Map<String, dynamic>.from(json['appointment'] as Map),
            )
          : null,
      badge: json['badge'] as String?,
      badgeLabel: json['badgeLabel'] as String?,
    );
  }

  // Preserves every field not explicitly overridden — used when a socket
  // handler needs to patch just one or two fields (e.g. append a message,
  // bump lastMessageAt) without silently resetting every other
  // server-computed flag (canMakeOffer, isOwner, isBlocked, otherUserOnline,
  // ...) back to its constructor default the way rebuilding via the plain
  // TradeChat(...) constructor field-by-field does if a field is missed.
  TradeChat copyWith({
    String? id,
    String? initiatorId,
    String? responderId,
    String? productId,
    String? serviceId,
    ChatStatus? status,
    DateTime? lastMessageAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserInfo? initiator,
    UserInfo? responder,
    ProductInfo? product,
    ServiceInfo? service,
    DealCompletionInfo? dealCompletion,
    List<ChatMessage>? messages,
    List<TradeOffer>? offers,
    bool? otherUserOnline,
    String? otherUserId,
    int? unreadCount,
    DealVerificationSummary? dealVerification,
    bool? canMakeOffer,
    bool? myPendingOffer,
    bool? isOwner,
    bool? hasPendingOffer,
    bool? isBlocked,
    List<String>? activeBarterProductIds,
    List<String>? activeBarterServiceIds,
    bool? isServiceChat,
    String? serviceFlow,
    bool? canCounterOffer,
    bool? canRespondToOffer,
    String? pendingOfferIdForMe,
    ServiceAppointmentSnapshot? appointment,
    bool? listingUnavailable,
    String? badge,
    String? badgeLabel,
  }) {
    return TradeChat(
      id: id ?? this.id,
      initiatorId: initiatorId ?? this.initiatorId,
      responderId: responderId ?? this.responderId,
      productId: productId ?? this.productId,
      serviceId: serviceId ?? this.serviceId,
      status: status ?? this.status,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      initiator: initiator ?? this.initiator,
      responder: responder ?? this.responder,
      product: product ?? this.product,
      service: service ?? this.service,
      dealCompletion: dealCompletion ?? this.dealCompletion,
      messages: messages ?? this.messages,
      offers: offers ?? this.offers,
      otherUserOnline: otherUserOnline ?? this.otherUserOnline,
      otherUserId: otherUserId ?? this.otherUserId,
      unreadCount: unreadCount ?? this.unreadCount,
      dealVerification: dealVerification ?? this.dealVerification,
      canMakeOffer: canMakeOffer ?? this.canMakeOffer,
      myPendingOffer: myPendingOffer ?? this.myPendingOffer,
      isOwner: isOwner ?? this.isOwner,
      hasPendingOffer: hasPendingOffer ?? this.hasPendingOffer,
      isBlocked: isBlocked ?? this.isBlocked,
      activeBarterProductIds:
          activeBarterProductIds ?? this.activeBarterProductIds,
      activeBarterServiceIds:
          activeBarterServiceIds ?? this.activeBarterServiceIds,
      isServiceChat: isServiceChat ?? this.isServiceChat,
      serviceFlow: serviceFlow ?? this.serviceFlow,
      canCounterOffer: canCounterOffer ?? this.canCounterOffer,
      canRespondToOffer: canRespondToOffer ?? this.canRespondToOffer,
      pendingOfferIdForMe: pendingOfferIdForMe ?? this.pendingOfferIdForMe,
      appointment: appointment ?? this.appointment,
      listingUnavailable: listingUnavailable ?? this.listingUnavailable,
      badge: badge ?? this.badge,
      badgeLabel: badgeLabel ?? this.badgeLabel,
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
