class FavoriteResponse {
  final String status;
  final String message;
  final FavoriteData data;

  FavoriteResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory FavoriteResponse.fromJson(Map<String, dynamic> json) {
    return FavoriteResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: FavoriteData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data.toJson()};
  }
}

class FavoriteData {
  final Favorite favorite;

  FavoriteData({required this.favorite});

  factory FavoriteData.fromJson(Map<String, dynamic> json) {
    return FavoriteData(favorite: Favorite.fromJson(json['favorite'] ?? {}));
  }

  Map<String, dynamic> toJson() {
    return {'favorite': favorite.toJson()};
  }
}

class Favorite {
  final String id;
  final String userId;
  final String productId;
  final String? serviceId;
  final DateTime createdAt;
  final FavoriteProduct? product;
  final dynamic service;

  Favorite({
    required this.id,
    required this.userId,
    required this.productId,
    this.serviceId,
    required this.createdAt,
    this.product,
    this.service,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      productId: json['productId'] ?? '',
      serviceId: json['serviceId'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      product: json['product'] != null
          ? FavoriteProduct.fromJson(json['product'])
          : null,
      service: json['service'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'productId': productId,
      'serviceId': serviceId,
      'createdAt': createdAt.toIso8601String(),
      'product': product?.toJson(),
      'service': service,
    };
  }
}

class FavoriteProduct {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String status;
  final String barterStatus;
  final int price;
  final String categoryId;
  final double latitude;
  final double longitude;
  final String location;
  final String postedById;
  final DateTime postedDate;
  final int viewCount;
  final bool isListed;
  final DateTime createdAt;
  final DateTime updatedAt;

  FavoriteProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    required this.barterStatus,
    required this.price,
    required this.categoryId,
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.postedById,
    required this.postedDate,
    required this.viewCount,
    required this.isListed,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) {
    return FavoriteProduct(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? '',
      barterStatus: json['barterStatus'] ?? '',
      price: json['price'] ?? 0,
      categoryId: json['categoryId'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      postedById: json['postedById'] ?? '',
      postedDate: DateTime.parse(
        json['postedDate'] ?? DateTime.now().toIso8601String(),
      ),
      viewCount: json['viewCount'] ?? 0,
      isListed: json['isListed'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'images': images,
      'status': status,
      'barterStatus': barterStatus,
      'price': price,
      'categoryId': categoryId,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'postedById': postedById,
      'postedDate': postedDate.toIso8601String(),
      'viewCount': viewCount,
      'isListed': isListed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
