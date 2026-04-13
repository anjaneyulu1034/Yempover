// lib/models/add_post_model.dart
class CreateProductRequest {
  final String title;
  final String description;
  final String categoryId;
  final List<String> images;
  final String location;
  final double? latitude;
  final double? longitude;
  final String barterStatus;
  final bool canClubItems;
  final double price;
  final String? validFrom;
  final String? validUntil;

  CreateProductRequest({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.images,
    required this.location,
    this.latitude,
    this.longitude,
    required this.barterStatus,
    this.canClubItems = true,
    required this.price,
    this.validFrom,
    this.validUntil,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'images': images,
      'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'barterStatus': barterStatus,
      'canClubItems': canClubItems,
      'price': price,
      if (validFrom != null && validFrom!.isNotEmpty) 'validFrom': validFrom,
      if (validUntil != null && validUntil!.isNotEmpty)
        'validUntil': validUntil,
    };
  }
}

class CreateServiceRequest {
  final String title;
  final String description;
  final String categoryId;
  final List<String> images;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? validFrom;
  final String? validUntil;
  final String? barterStatus;
  final String status; // PROVIDE_SERVICE
  final double price;

  CreateServiceRequest({
    required this.title,
    required this.description,
    required this.categoryId,
    required this.images,
    this.location,
    this.latitude,
    this.longitude,
    this.validFrom,
    this.validUntil,
    this.barterStatus,
    required this.status,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'images': images,
      if (location != null && location!.isNotEmpty) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (validFrom != null && validFrom!.isNotEmpty) 'validFrom': validFrom,
      if (validUntil != null && validUntil!.isNotEmpty)
        'validUntil': validUntil,
      if (barterStatus != null && barterStatus!.isNotEmpty)
        'barterStatus': barterStatus,
      'status': status,
      'price': price,
    };
  }
}

class CreateProductResponse {
  final String status;
  final String message;
  final ProductData data;

  CreateProductResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CreateProductResponse.fromJson(Map<String, dynamic> json) {
    return CreateProductResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: ProductData.fromJson(json['data']['product']),
    );
  }
}

class CreateServiceResponse {
  final String status;
  final String message;
  final ServiceData data;

  CreateServiceResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CreateServiceResponse.fromJson(Map<String, dynamic> json) {
    return CreateServiceResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: ServiceData.fromJson(json['data']['service']),
    );
  }
}

class ProductData {
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
  final String? location;
  final String postedById;
  final DateTime postedDate;
  final int viewCount;
  final bool isListed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryInfo category;
  final dynamic barterDetails;

  ProductData({
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
    this.location,
    required this.postedById,
    required this.postedDate,
    required this.viewCount,
    required this.isListed,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.barterDetails,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    return ProductData(
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
          : 0.0,
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
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      category: CategoryInfo.fromJson(json['category'] ?? {}),
      barterDetails: json['barterDetails'],
    );
  }
}

class ServiceData {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String status;
  final String categoryId;
  final double? latitude;
  final double? longitude;
  final String? location;
  final double price;
  final String postedById;
  final DateTime postedDate;
  final int viewCount;
  final bool isListed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CategoryInfo category;

  ServiceData({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    required this.categoryId,
    this.latitude,
    this.longitude,
    this.location,
    required this.price,
    required this.postedById,
    required this.postedDate,
    required this.viewCount,
    required this.isListed,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
  });

  factory ServiceData.fromJson(Map<String, dynamic> json) {
    return ServiceData(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      status: json['status'] ?? '',
      categoryId: json['categoryId'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      location: json['location'],
      price: json['price'] != null
          ? (json['price'] is int
                ? (json['price'] as int).toDouble()
                : json['price']?.toDouble())
          : 0.0,
      postedById: json['postedById'] ?? '',
      postedDate: DateTime.parse(
        json['postedDate'] ?? DateTime.now().toIso8601String(),
      ),
      viewCount: json['viewCount'] ?? 0,
      isListed: json['isListed'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      category: CategoryInfo.fromJson(json['category'] ?? {}),
    );
  }
}

class CategoryInfo {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String type;
  final bool isActive;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryInfo({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.type,
    required this.isActive,
    this.parentId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      type: json['type'] ?? '',
      isActive: json['isActive'] ?? true,
      parentId: json['parentId'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
