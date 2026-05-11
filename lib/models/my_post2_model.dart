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
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category category;
  final BarterDetails? barterDetails;

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
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.barterDetails,
  });

  factory MyPost.fromJson(Map<String, dynamic> json) {
    return MyPost(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? '',
      barterStatus: json['barterStatus'] ?? '',
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      categoryId: json['categoryId'] ?? '',
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
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
      category: Category.fromJson(json['category'] ?? {}),
      barterDetails: json['barterDetails'] != null
          ? BarterDetails.fromJson(json['barterDetails'])
          : null,
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
      'category': category.toJson(),
      'barterDetails': barterDetails?.toJson(),
    };
  }

  MyPost copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? images,
    String? status,
    String? barterStatus,
    double? price,
    String? categoryId,
    double? latitude,
    double? longitude,
    String? location,
    String? postedById,
    DateTime? postedDate,
    int? viewCount,
    bool? isListed,
    DateTime? createdAt,
    DateTime? updatedAt,
    Category? category,
    BarterDetails? barterDetails,
  }) {
    return MyPost(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      status: status ?? this.status,
      barterStatus: barterStatus ?? this.barterStatus,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      postedById: postedById ?? this.postedById,
      postedDate: postedDate ?? this.postedDate,
      viewCount: viewCount ?? this.viewCount,
      isListed: isListed ?? this.isListed,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      barterDetails: barterDetails ?? this.barterDetails,
    );
  }

  // Computed properties
  bool get isForSale => status == 'FOR_SALE';
  bool get isSold => status == 'SOLD';
  bool get isProvidingService => category.type == 'service';
  bool get isOpenForBarter => barterStatus == 'OPEN_FOR_BARTER';
  bool get hasAcceptedOffer =>
      false; // You'll need to implement this based on your data
  int get openOffersCount =>
      0; // You'll need to implement this based on your data
  String get type => category.type;
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String type;
  final bool isActive;
  final String? parentId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
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

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      icon: json['icon'],
      type: json['type'] ?? 'product',
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type,
      'isActive': isActive,
      'parentId': parentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class BarterDetails {
  final String? preferredItems;
  final double? estimatedValue;

  BarterDetails({this.preferredItems, this.estimatedValue});

  factory BarterDetails.fromJson(Map<String, dynamic> json) {
    return BarterDetails(
      preferredItems: json['preferredItems'],
      estimatedValue: json['estimatedValue'] != null
          ? (json['estimatedValue'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {'preferredItems': preferredItems, 'estimatedValue': estimatedValue};
  }
}

class PostsResponse {
  final List<MyPost> posts;
  final Pagination pagination;

  PostsResponse({required this.posts, required this.pagination});

  factory PostsResponse.fromJson(Map<String, dynamic> json) {
    return PostsResponse(
      posts: (json['posts'] as List? ?? [])
          .map((post) => MyPost.fromJson(post))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

class Pagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  Pagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory Pagination.fromJson(Map<String, dynamic> json) {
    return Pagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 1,
    );
  }
}

class ApiResponse {
  final String status;
  final String? message;
  final Map<String, dynamic>? data;

  ApiResponse({required this.status, this.message, this.data});

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      status: json['status'] ?? '',
      message: json['message'],
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}
