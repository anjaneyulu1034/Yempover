class Post {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final String status;
  final String? barterStatus;
  final double? price;
  final String categoryId;
  final String location;
  final String postedById;
  final DateTime postedDate;
  final int viewCount;
  final bool isListed;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Category? category;
  final PostedBy? postedBy;
  final BarterDetails? barterDetails;
  final String type;
  final double? distance;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    this.barterStatus,
    this.price,
    required this.categoryId,
    required this.location,
    required this.postedById,
    required this.postedDate,
    required this.viewCount,
    required this.isListed,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.postedBy,
    this.barterDetails,
    required this.type,
    this.distance,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      status: json['status'] ?? '',
      barterStatus: json['barterStatus'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      categoryId: json['categoryId'] ?? '',
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
      category: json['category'] != null
          ? Category.fromJson(json['category'])
          : null,
      postedBy: json['postedBy'] != null
          ? PostedBy.fromJson(json['postedBy'])
          : null,
      barterDetails: json['barterDetails'] != null
          ? BarterDetails.fromJson(json['barterDetails'])
          : null,
      type: json['type'] ?? 'product',
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
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
      'location': location,
      'postedById': postedById,
      'postedDate': postedDate.toIso8601String(),
      'viewCount': viewCount,
      'isListed': isListed,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category?.toJson(),
      'postedBy': postedBy?.toJson(),
      'barterDetails': barterDetails?.toJson(),
      'type': type,
      'distance': distance,
    };
  }
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String type;
  final bool isActive;
  final String? parentId;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    required this.type,
    required this.isActive,
    this.parentId,
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
    };
  }
}

class PostedBy {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? homeAddress;
  final double? latitude;
  final double? longitude;

  PostedBy({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.homeAddress,
    this.latitude,
    this.longitude,
  });

  factory PostedBy.fromJson(Map<String, dynamic> json) {
    return PostedBy(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      homeAddress: json['homeAddress'],
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'profileImage': profileImage,
      'homeAddress': homeAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

class BarterDetails {
  final String id;
  final String productId;
  final List<BarterCategory> barterCategories;
  final DateTime createdAt;
  final DateTime updatedAt;

  BarterDetails({
    required this.id,
    required this.productId,
    required this.barterCategories,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BarterDetails.fromJson(Map<String, dynamic> json) {
    return BarterDetails(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      barterCategories: json['barterCategories'] != null
          ? List<BarterCategory>.from(
              json['barterCategories'].map((x) => BarterCategory.fromJson(x)),
            )
          : [],
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
      'productId': productId,
      'barterCategories': barterCategories.map((x) => x.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class BarterCategory {
  final String id;
  final String barterDetailId;
  final String categoryId;
  final Category category;
  final DateTime createdAt;

  BarterCategory({
    required this.id,
    required this.barterDetailId,
    required this.categoryId,
    required this.category,
    required this.createdAt,
  });

  factory BarterCategory.fromJson(Map<String, dynamic> json) {
    return BarterCategory(
      id: json['id'] ?? '',
      barterDetailId: json['barterDetailId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      category: Category.fromJson(json['category']),
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'barterDetailId': barterDetailId,
      'categoryId': categoryId,
      'category': category.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CategoryWithChildren {
  final String id;
  final String name;
  final String type;
  final int itemsCount;
  final List<CategoryChild> children;

  CategoryWithChildren({
    required this.id,
    required this.name,
    required this.type,
    required this.itemsCount,
    required this.children,
  });

  factory CategoryWithChildren.fromJson(Map<String, dynamic> json) {
    return CategoryWithChildren(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'product',
      itemsCount: json['itemsCount'] ?? 0,
      children: json['children'] != null
          ? List<CategoryChild>.from(
              json['children'].map((x) => CategoryChild.fromJson(x)),
            )
          : [],
    );
  }
}

class CategoryChild {
  final String id;
  final String name;
  final int itemsCount;

  CategoryChild({
    required this.id,
    required this.name,
    required this.itemsCount,
  });

  factory CategoryChild.fromJson(Map<String, dynamic> json) {
    return CategoryChild(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      itemsCount: json['itemsCount'] ?? 0,
    );
  }
}

class PostsResponse {
  final String status;
  final String message;
  final PostsData data;

  PostsResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory PostsResponse.fromJson(Map<String, dynamic> json) {
    return PostsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: PostsData.fromJson(json['data']),
    );
  }
}

class PostsData {
  final List<Post> posts;
  final Pagination pagination;

  PostsData({required this.posts, required this.pagination});

  factory PostsData.fromJson(Map<String, dynamic> json) {
    return PostsData(
      posts: List<Post>.from(json['posts'].map((x) => Post.fromJson(x))),
      pagination: Pagination.fromJson(json['pagination']),
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
