// lib/models/my_post_model.dart
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
  bool get isSold => status == 'SOLD';
  bool get hasAcceptedOffer =>
      openOffersCount > 0; // Adjust based on actual logic
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
