// lib/models/my_post_model.dart
import 'package:yempover_app/utils/post_availability_utils.dart';

class MyPostsResponse {
  final String status;
  final String message;
  final MyPostsData data;

  MyPostsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory MyPostsResponse.fromJson(Map<String, dynamic> json) {
    return MyPostsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: MyPostsData.fromJson(json['data']),
    );
  }
}

class MyPostsData {
  final List<MyPost> posts;
  final Pagination pagination;

  MyPostsData({required this.posts, required this.pagination});

  factory MyPostsData.fromJson(Map<String, dynamic> json) {
    return MyPostsData(
      posts: (json['posts'] as List)
          .map((post) => MyPost.fromJson(post))
          .toList(),
      pagination: Pagination.fromJson(json['pagination']),
    );
  }

  void operator [](String other) {}
}

class MyPost {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String status;
  final String barterStatus;
  final double? price;
  final String categoryId;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String postedById;
  final DateTime postedDate;
  final int viewCount;
  final bool isListed;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? remainingTime;
  final bool hasExpired;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category category;
  final dynamic barterDetails;
  final Count count;
  final String type;
  final int openOffersCount;
  final bool isClubbable;
  // Distinct-offerer count (Point 4) — how many different users have made an
  // offer on this post. Distinct from openOffersCount, which counts
  // transactions. Tap-through target for the offerers list.
  final int offerCount;
  final DateTime? soldAt;
  final DateTime? expiredAt;

  MyPost({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    required this.barterStatus,
    this.price,
    required this.categoryId,
    this.latitude,
    this.longitude,
    this.location,
    required this.postedById,
    required this.postedDate,
    required this.viewCount,
    required this.isListed,
    this.validFrom,
    this.validUntil,
    this.remainingTime,
    this.hasExpired = false,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.barterDetails,
    required this.count,
    required this.type,
    required this.openOffersCount,
    this.isClubbable = false,
    this.offerCount = 0,
    this.soldAt,
    this.expiredAt,
  });

  factory MyPost.fromJson(Map<String, dynamic> json) {
    return MyPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      status: json['status'] ?? '',
      barterStatus: json['barterStatus'] ?? 'NO_BARTER',
      price: json['price'] != null
          ? (json['price'] is int
                ? (json['price'] as int).toDouble()
                : json['price']?.toDouble())
          : null,
      categoryId: json['categoryId'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      location: json['location'],
      postedById: json['postedById'] ?? '',
      postedDate: DateTime.parse(
        json['postedDate'] ?? DateTime.now().toIso8601String(),
      ),
      viewCount: json['viewCount'] ?? 0,
      isListed: json['isListed'] ?? true,
      validFrom: _parseOptionalDateTime(json['validFrom']),
      validUntil: _parseOptionalDateTime(json['validUntil']),
      remainingTime: _parseRemainingTime(json['remainingTime']),
      hasExpired: _parseFlexibleBool(json, const [
        'hasExpired',
        'isExpired',
      ], defaultValue: false),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      category: Category.fromJson(json['category'] ?? {}),
      barterDetails: json['barterDetails'],
      count: Count.fromJson(json['_count'] ?? {}),
      type: json['type'] ?? 'product',
      openOffersCount: json['openOffersCount'] ?? 0,
      isClubbable: _parseFlexibleBool(json, const [
        'isClubbable',
        'canClubItems',
        'canBeClubbed',
      ], defaultValue: false),
      offerCount: json['offerCount'] is int
          ? json['offerCount'] as int
          : int.tryParse('${json['offerCount'] ?? ''}') ?? 0,
      soldAt: _parseOptionalDateTime(json['soldAt']),
      expiredAt: _parseOptionalDateTime(json['expiredAt']),
    );
  }

  static bool _parseFlexibleBool(
    Map<String, dynamic> json,
    List<String> keys, {
    required bool defaultValue,
  }) {
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      final value = json[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
        if (normalized == 'false' || normalized == '0' || normalized == 'no') {
          return false;
        }
      }
    }
    return defaultValue;
  }

  static DateTime? _parseOptionalDateTime(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String? _parseRemainingTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  bool get isForSale => status == 'FOR_SALE';
  bool get isProvidingService => status == 'PROVIDE_SERVICE';
  bool get isOpenForBarter => barterStatus == 'OPEN_FOR_BARTER';
  // A trade can complete on either side of a deal: the listing itself is
  // marked SOLD, while the item the other party bartered in exchange for it
  // is marked BARTERED. A service is never "sold" — completing a deal on it
  // doesn't take it out of circulation, so COMPLETED only reads as sold for
  // products (where it never actually occurs).
  bool get isSold =>
      type.toLowerCase() != 'service' &&
      (status == 'SOLD' || status == 'BARTERED' || status == 'COMPLETED');
  bool get hasAcceptedOffer =>
      openOffersCount > 0; // Adjust based on actual logic

  bool get isExpiredOrUnavailable => PostAvailabilityUtils.isUnavailable(
        hasExpired: hasExpired,
        validFrom: validFrom,
        validUntil: validUntil,
        remainingTime: remainingTime,
        status: status,
        isListed: isListed,
      );
}

class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(id: json['id'] ?? '', name: json['name'] ?? '');
  }
}

class Count {
  final int transactions;

  Count({required this.transactions});

  factory Count.fromJson(Map<String, dynamic> json) {
    return Count(transactions: json['transactions'] ?? 0);
  }
}

class Pagination {
  final int total;
  final int page;
  final int limit;
  final int pages;

  Pagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      pages: json['pages'] ?? 1,
    );
  }
}

// GET /me/posts/products/:id/offers | /me/posts/services/:id/offers (Point 4)
// — owner-scoped list of who has made an offer on one of the owner's posts.
class PostOfferersResult {
  final int offerCount;
  final List<PostOfferer> offerers;

  PostOfferersResult({required this.offerCount, required this.offerers});

  factory PostOfferersResult.fromJson(Map<String, dynamic> json) {
    return PostOfferersResult(
      offerCount: json['offerCount'] is int
          ? json['offerCount'] as int
          : int.tryParse('${json['offerCount'] ?? ''}') ?? 0,
      offerers: (json['offerers'] as List? ?? [])
          .whereType<Map>()
          .map((o) => PostOfferer.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
    );
  }
}

class PostOfferer {
  final String chatId;
  final String? chatStatus;
  final String? userId;
  final String name;
  final String? profileImage;
  final String? offerId;
  final String? offerType;
  final String? offerStatus;
  final double? amount;
  final String? currency;
  final String? barterItemTitle;
  final bool isZeroCoin;
  final String offerSummary;
  final DateTime? offeredAt;

  PostOfferer({
    required this.chatId,
    this.chatStatus,
    this.userId,
    required this.name,
    this.profileImage,
    this.offerId,
    this.offerType,
    this.offerStatus,
    this.amount,
    this.currency,
    this.barterItemTitle,
    required this.isZeroCoin,
    required this.offerSummary,
    this.offeredAt,
  });

  factory PostOfferer.fromJson(Map<String, dynamic> json) {
    return PostOfferer(
      chatId: json['chatId'] ?? '',
      chatStatus: json['chatStatus'] as String?,
      userId: json['userId'] as String?,
      name: json['name'] ?? 'User',
      profileImage: json['profileImage'] as String?,
      offerId: json['offerId'] as String?,
      offerType: json['offerType'] as String?,
      offerStatus: json['offerStatus'] as String?,
      amount: json['amount'] != null
          ? double.tryParse(json['amount'].toString())
          : null,
      currency: json['currency'] as String?,
      barterItemTitle: json['barterItemTitle'] as String?,
      isZeroCoin: json['isZeroCoin'] == true,
      offerSummary: json['offerSummary'] ?? '',
      offeredAt: json['offeredAt'] != null
          ? DateTime.tryParse(json['offeredAt'].toString())
          : null,
    );
  }
}
