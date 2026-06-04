import 'package:YemPover_app/models/ProductPostmain.dart';
import 'package:YemPover_app/models/post_model.dart' hide Category;
import 'package:YemPover_app/utils/post_availability_utils.dart';

class FavoritesResponse {
  final String status;
  final String message;
  final FavoritesData data;

  FavoritesResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory FavoritesResponse.fromJson(Map<String, dynamic> json) {
    return FavoritesResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: FavoritesData.fromJson(json['data'] ?? {}),
    );
  }
}

class FavoritesData {
  final List<FavoriteItem> favorites;
  final Pagination pagination;

  FavoritesData({required this.favorites, required this.pagination});

  factory FavoritesData.fromJson(Map<String, dynamic> json) {
    return FavoritesData(
      favorites:
          (json['favorites'] as List?)
              ?.map((item) => FavoriteItem.fromJson(item))
              .toList() ??
          [],
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class FavoriteItem {
  final String id;
  final String type;
  final FavoritePost? post;
  final DateTime createdAt;
  final String? productId;
  final String? serviceId;
  final dynamic product;
  final dynamic service;

  FavoriteItem({
    required this.id,
    required this.type,
    this.post,
    required this.createdAt,
    this.productId,
    this.serviceId,
    this.product,
    this.service,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id'] ?? '',
      type: json['type'] ?? 'product',
      post: json['post'] != null ? FavoritePost.fromJson(json['post']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      productId: json['productId'],
      serviceId: json['serviceId'],
      product: json['product'],
      service: json['service'],
    );
  }

  // Get the actual post ID
  String? get actualPostId {
    if (post != null) return post!.id;
    if (productId != null) return productId;
    if (serviceId != null) return serviceId;
    return null;
  }

  // Get post title
  String get title {
    if (post != null) return post!.title;
    return '';
  }

  // Get post price
  double get price {
    if (post != null) return post!.price;
    return 0.0;
  }

  // Get post images
  List<String> get images {
    if (post != null) return post!.images;
    return [];
  }

  // Get post location
  String get location {
    if (post != null) return post!.location;
    return '';
  }

  // Get post status
  String get status {
    if (post != null) return post!.status;
    return '';
  }

  // Get category
  Category get category {
    if (post != null) return post!.category;
    return Category(id: '', name: '', type: 'product', isActive: true);
  }

  // Get posted by
  PostedBy get postedBy {
    if (post != null) return post!.postedBy;
    return PostedBy(id: '', firstName: '', lastName: '');
  }

  bool get isExpiredOrUnavailable {
    if (post != null) return post!.isExpiredOrUnavailable;

    final nested = _asMap(product) ?? _asMap(service);
    if (nested != null) {
      return PostAvailabilityUtils.isUnavailable(
        hasExpired: _readBool(nested, const ['hasExpired', 'isExpired']),
        validFrom: _readDate(nested['validFrom']),
        validUntil: _readDate(nested['validUntil']),
        remainingTime: nested['remainingTime']?.toString(),
        status: nested['status']?.toString(),
        isListed: _readNullableBool(nested['isListed']),
      );
    }

    return false;
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static bool? _readNullableBool(dynamic value) {
    if (value is bool) return value;
    if (value == null) return null;
    final text = value.toString().trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return null;
  }

  static bool _readBool(
    Map<String, dynamic> json,
    List<String> keys, {
    bool defaultValue = false,
  }) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value != null) {
        final text = value.toString().trim().toLowerCase();
        if (text == 'true') return true;
        if (text == 'false') return false;
      }
    }
    return defaultValue;
  }

  static DateTime? _readDate(dynamic value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }
}

class FavoritePost {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String status;
  final String barterStatus;
  final double price;
  final String categoryId;
  final double? latitude;
  final double? longitude;
  final String location;
  final String postedById;
  final DateTime postedDate;
  final int viewCount;
  final bool isListed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? remainingTime;
  final bool hasExpired;
  final Category category;
  final PostedBy postedBy;

  FavoritePost({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    required this.barterStatus,
    required this.price,
    required this.categoryId,
    this.latitude,
    this.longitude,
    required this.location,
    required this.postedById,
    required this.postedDate,
    required this.viewCount,
    this.isListed = true,
    required this.createdAt,
    required this.updatedAt,
    this.validFrom,
    this.validUntil,
    this.remainingTime,
    this.hasExpired = false,
    required this.category,
    required this.postedBy,
  });

  bool get isExpiredOrUnavailable => PostAvailabilityUtils.isUnavailable(
        hasExpired: hasExpired,
        validFrom: validFrom,
        validUntil: validUntil,
        remainingTime: remainingTime,
        status: status,
        isListed: isListed,
      );

  factory FavoritePost.fromJson(Map<String, dynamic> json) {
    return FavoritePost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images:
          (json['images'] as List?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] ?? '',
      barterStatus: json['barterStatus'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      location: json['location'] ?? '',
      postedById: json['postedById'] ?? '',
      postedDate: json['postedDate'] != null
          ? DateTime.parse(json['postedDate'])
          : DateTime.now(),
      viewCount: json['viewCount'] ?? 0,
      isListed: FavoriteItem._readBool(json, const ['isListed'], defaultValue: true),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      validFrom: FavoriteItem._readDate(json['validFrom']),
      validUntil: FavoriteItem._readDate(json['validUntil']),
      remainingTime: json['remainingTime']?.toString(),
      hasExpired: FavoriteItem._readBool(json, const ['hasExpired', 'isExpired']),
      category: Category.fromJson(json['category'] ?? {}),
      postedBy: PostedBy.fromJson(json['postedBy'] ?? {}),
    );
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

class AddFavoriteResponse {
  final String status;
  final String message;
  final AddFavoriteData data;

  AddFavoriteResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory AddFavoriteResponse.fromJson(Map<String, dynamic> json) {
    return AddFavoriteResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: AddFavoriteData.fromJson(json['data'] ?? {}),
    );
  }
}

class AddFavoriteData {
  final FavoriteItem favorite;

  AddFavoriteData({required this.favorite});

  factory AddFavoriteData.fromJson(Map<String, dynamic> json) {
    return AddFavoriteData(
      favorite: FavoriteItem.fromJson(json['favorite'] ?? {}),
    );
  }
}

class RemoveFavoriteResponse {
  final String status;
  final String message;

  RemoveFavoriteResponse({required this.status, required this.message});

  factory RemoveFavoriteResponse.fromJson(Map<String, dynamic> json) {
    return RemoveFavoriteResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
