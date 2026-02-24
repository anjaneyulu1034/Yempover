import 'package:flutter/foundation.dart';

// Post Types
enum PostType { product, service }

enum PostStatus {
  FOR_SALE,
  FOR_BARTER,
  PROVIDE_SERVICE,
  LOOKING_FOR_SERVICE,
  DELETED,
  ARCHIVED,
}

enum BarterStatus { NO_BARTER, OPEN_FOR_BARTER }

// User Model
class User {
  final String id;
  final String firstName;
  final String lastName;
  final String? profileImage;
  final String? homeAddress;
  final double? latitude;
  final double? longitude;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profileImage,
    this.homeAddress,
    this.latitude,
    this.longitude,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      profileImage: json['profileImage'],
      homeAddress: json['homeAddress'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }

  String get fullName => '$firstName $lastName';
}

// Category Model
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
}

// Barter Category Model
class BarterCategory {
  final String id;
  final String barterDetailId;
  final String categoryId;
  final Category category;

  BarterCategory({
    required this.id,
    required this.barterDetailId,
    required this.categoryId,
    required this.category,
  });

  factory BarterCategory.fromJson(Map<String, dynamic> json) {
    return BarterCategory(
      id: json['id'] ?? '',
      barterDetailId: json['barterDetailId'] ?? '',
      categoryId: json['categoryId'] ?? '',
      category: Category.fromJson(json['category'] ?? {}),
    );
  }
}

// Barter Details Model
class BarterDetails {
  final String id;
  final String productId;
  final List<BarterCategory> barterCategories;

  BarterDetails({
    required this.id,
    required this.productId,
    required this.barterCategories,
  });

  factory BarterDetails.fromJson(Map<String, dynamic> json) {
    return BarterDetails(
      id: json['id'] ?? '',
      productId: json['productId'] ?? '',
      barterCategories: (json['barterCategories'] as List? ?? [])
          .map((item) => BarterCategory.fromJson(item))
          .toList(),
    );
  }
}

// Post Model
class Post {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final PostStatus status;
  final BarterStatus? barterStatus;
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
  final Category category;
  final User postedBy;
  final BarterDetails? barterDetails;
  final PostType type;
  final double? distance;
  bool isFavorite;
  bool isHidden;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    this.barterStatus,
    required this.price,
    required this.categoryId,
    this.latitude,
    this.longitude,
    required this.location,
    required this.postedById,
    required this.postedDate,
    required this.viewCount,
    required this.isListed,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    required this.postedBy,
    this.barterDetails,
    required this.type,
    this.distance,
    this.isFavorite = false,
    this.isHidden = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      images: (json['images'] as List? ?? [])
          .map((item) => item.toString())
          .where((image) => image.isNotEmpty)
          .toList(),
      status: _parsePostStatus(json['status']),
      barterStatus: _parseBarterStatus(json['barterStatus']),
      price: (json['price'] != null)
          ? double.tryParse(json['price'].toString()) ?? 0.0
          : 0.0,
      categoryId: json['categoryId'] ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      location: json['location'] ?? '',
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
      postedBy: User.fromJson(json['postedBy'] ?? {}),
      barterDetails: json['barterDetails'] != null
          ? BarterDetails.fromJson(json['barterDetails'])
          : null,
      type: json['type'] == 'service' ? PostType.service : PostType.product,
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
    );
  }

  static PostStatus _parsePostStatus(String status) {
    switch (status) {
      case 'FOR_SALE':
        return PostStatus.FOR_SALE;
      case 'FOR_BARTER':
        return PostStatus.FOR_BARTER;
      case 'PROVIDE_SERVICE':
        return PostStatus.PROVIDE_SERVICE;
      case 'LOOKING_FOR_SERVICE':
        return PostStatus.LOOKING_FOR_SERVICE;
      default:
        return PostStatus.FOR_SALE;
    }
  }

  static BarterStatus? _parseBarterStatus(String? status) {
    if (status == null) return null;
    switch (status) {
      case 'OPEN_FOR_BARTER':
        return BarterStatus.OPEN_FOR_BARTER;
      case 'NO_BARTER':
        return BarterStatus.NO_BARTER;
      default:
        return BarterStatus.NO_BARTER;
    }
  }

  String get statusText {
    switch (status) {
      case PostStatus.FOR_SALE:
        return 'For Sale';
      case PostStatus.FOR_BARTER:
        return 'For Barter';
      case PostStatus.PROVIDE_SERVICE:
        return 'Providing Service';
      case PostStatus.LOOKING_FOR_SERVICE:
        return 'Looking for Service';
      default:
        return 'For Sale';
    }
  }

  String get barterStatusText {
    switch (barterStatus) {
      case BarterStatus.OPEN_FOR_BARTER:
        return 'Open for Barter';
      case BarterStatus.NO_BARTER:
        return 'No Barter';
      default:
        return '';
    }
  }

  String get formattedPrice =>
      price > 0 ? '\$${price.toStringAsFixed(2)}' : 'Free';

  List<String> get processedImages {
    if (images.isEmpty) {
      return [getDefaultImageUrl()];
    }
    return images.map((image) {
      if (image.startsWith('http')) {
        return image;
      } else if (image.contains('.')) {
        // If it has an extension but no full URL, construct a proper URL
        return 'https://lionlike-flavourlessly-neida.ngrok-free.dev/uploads/$image';
      } else {
        return getDefaultImageUrl();
      }
    }).toList();
  }

  String getDefaultImageUrl() {
    // Provide default images based on category
    switch (category.name.toLowerCase()) {
      case 'electronics':
        return 'https://images.unsplash.com/photo-1498049794561-7780e7231661?w=500&q=80';
      case 'furniture':
        return 'https://images.unsplash.com/photo-1555041469-a586c61ea9bc?w=500&q=80';
      case 'fashion':
        return 'https://images.unsplash.com/photo-1490481651871-ab68de25d43d?w=500&q=80';
      case 'books':
        return 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500&q=80';
      default:
        return 'https://images.unsplash.com/photo-1545235617-9465d2a55698?w=500&q=80';
    }
  }

  String get distanceText {
    if (distance == null) return 'Distance not available';
    if (distance! < 1) {
      return '${(distance! * 1000).toStringAsFixed(0)} m away';
    } else {
      return '${distance!.toStringAsFixed(1)} km away';
    }
  }

  String get postTypeText {
    switch (status) {
      case PostStatus.LOOKING_FOR_SERVICE:
        return 'Looking for a service';
      case PostStatus.PROVIDE_SERVICE:
        return 'Providing a service';
      case PostStatus.FOR_BARTER:
        return 'Bartering a product';
      default:
        return 'Selling a product';
    }
  }

  bool get isForBarter => barterStatus == BarterStatus.OPEN_FOR_BARTER;
  bool get isForSale => status == PostStatus.FOR_SALE && price > 0;
}

// Posts Response Model
class PostsResponse {
  final List<Post> posts;
  final Pagination pagination;

  PostsResponse({required this.posts, required this.pagination});

  factory PostsResponse.fromJson(Map<String, dynamic> json) {
    final postsData = json['data']['posts'] as List;
    final paginationData = json['data']['pagination'];

    return PostsResponse(
      posts: postsData.map((postJson) => Post.fromJson(postJson)).toList(),
      pagination: Pagination.fromJson(paginationData),
    );
  }
}

// Post Detail Response Model
class PostDetailResponse {
  final Post post;

  PostDetailResponse({required this.post});

  factory PostDetailResponse.fromJson(Map<String, dynamic> json) {
    return PostDetailResponse(post: Post.fromJson(json['data']['post']));
  }
}

// Pagination Model
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

  bool get hasNextPage => page < pages;
  bool get hasPreviousPage => page > 1;
}

// Notification Model (for HomeScreen)
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime date;
  bool read;
  final String action;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.date,
    required this.read,
    required this.action,
    this.data,
  });
}

// User Item Model (for Offer Deck)
class UserItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double value;
  final bool isSelected;

  UserItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.value,
    this.isSelected = false,
    required description,
    required price,
  });
}
