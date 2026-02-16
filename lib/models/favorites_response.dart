// lib/models/favorites_response.dart
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

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data.toJson()};
  }
}

class FavoritesData {
  final List<FavoriteItem> favorites;
  final PaginationInfo pagination;

  FavoritesData({required this.favorites, required this.pagination});

  factory FavoritesData.fromJson(Map<String, dynamic> json) {
    return FavoritesData(
      favorites:
          (json['favorites'] as List?)
              ?.map((item) => FavoriteItem.fromJson(item))
              .toList() ??
          [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorites': favorites.map((item) => item.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }
}

class FavoriteItem {
  final String? id;
  final String? title;
  final String? description;
  final double? price;
  final String? currency;
  final List<String>? images;
  final String? category;
  final String? condition;
  final String? location;
  final String? sellerId;
  final String? sellerName;
  final String? sellerImage;
  final double? sellerRating;
  final DateTime? createdAt;
  final bool? isAvailable;
  final String? type; // 'product' or 'service'

  FavoriteItem({
    this.id,
    this.title,
    this.description,
    this.price,
    this.currency,
    this.images,
    this.category,
    this.condition,
    this.location,
    this.sellerId,
    this.sellerName,
    this.sellerImage,
    this.sellerRating,
    this.createdAt,
    this.isAvailable,
    this.type,
  });

  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      id: json['id']?.toString(),
      title: json['title'] ?? json['name'],
      description: json['description'],
      price: json['price'] != null ? json['price'].toDouble() : null,
      currency: json['currency'] ?? 'USD',
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      category: json['category'],
      condition: json['condition'],
      location: json['location'],
      sellerId: json['sellerId']?.toString(),
      sellerName: json['sellerName'],
      sellerImage: json['sellerImage'],
      sellerRating: json['sellerRating']?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      isAvailable: json['isAvailable'] ?? true,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'images': images,
      'category': category,
      'condition': condition,
      'location': location,
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerImage': sellerImage,
      'sellerRating': sellerRating,
      'createdAt': createdAt?.toIso8601String(),
      'isAvailable': isAvailable,
      'type': type,
    };
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
      pages: json['pages'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total, 'page': page, 'limit': limit, 'pages': pages};
  }

  bool get hasNextPage => page < pages;
  bool get hasPreviousPage => page > 1;
}
