// // class ProductPost {
// //   String userName;
// //   String timeAgo;
// //   String category;
// //   String title;
// //   String distance;
// //   String returnType;
// //   String barterStatus;
// //   String postType;
// //   String tradeType;
// //   String productLocation;
// //   DateTime postedDate;
// //   String wishListCategory;
// //   bool isFavorite;
// //   bool isHidden;
// //   List<String> images;
// //   int views;
// //   String price;
// //   String description;
// //   String transportationOption;
// //   bool isVerified;

// //   ProductPost({
// //     required this.userName,
// //     required this.timeAgo,
// //     required this.category,
// //     required this.title,
// //     required this.distance,
// //     required this.returnType,
// //     required this.barterStatus,
// //     required this.postType,
// //     required this.tradeType,
// //     required this.productLocation,
// //     required this.postedDate,
// //     required this.wishListCategory,
// //     required this.isFavorite,
// //     required this.isHidden,
// //     required this.images,
// //     this.views = 245,
// //     this.price = '\$299.99',
// //     this.description =
// //         'Barely used sofa for sale. Mint condition Orange color velvet upholstery. Teak wood base',
// //     this.transportationOption =
// //         'This item can be transported to desired location',
// //     this.isVerified = true,
// //   });
// // }

// // class NotificationItem {
// //   final String message;
// //   final DateTime date;
// //   final String type;

// //   NotificationItem({
// //     required this.message,
// //     required this.date,
// //     required this.type,
// //   });
// // }

// // models.dart
// class ProductPost {
//   String userName;
//   String timeAgo;
//   String category;
//   String title;
//   String distance;
//   String returnType;
//   String barterStatus;
//   String postType;
//   String tradeType;
//   String productLocation;
//   DateTime postedDate;
//   String wishListCategory;
//   bool isFavorite;
//   bool isHidden;
//   List<String> images;
//   int views;
//   String price;
//   String description;
//   String transportationOption;
//   bool isVerified;
//   bool canClubItems;

//   ProductPost({
//     required this.userName,
//     required this.timeAgo,
//     required this.category,
//     required this.title,
//     required this.distance,
//     required this.returnType,
//     required this.barterStatus,
//     required this.postType,
//     required this.tradeType,
//     required this.productLocation,
//     required this.postedDate,
//     required this.wishListCategory,
//     required this.isFavorite,
//     required this.isHidden,
//     required this.images,
//     this.views = 245,
//     this.price = '\$299.99',
//     this.description =
//         'Barely used sofa for sale. Mint condition Orange color velvet upholstery. Teak wood base',
//     this.transportationOption =
//         'This item can be transported to desired location',
//     this.isVerified = true,
//     this.canClubItems = true,
//   });
// }

// class UserItem {
//   final String id;
//   final String name;
//   final String category;
//   final String imageUrl;
//   final bool isClubbable;
//   final bool isFromExistingPost;
//   final String? price;
//   final String? description;

//   UserItem({
//     required this.id,
//     required this.name,
//     required this.category,
//     required this.imageUrl,
//     required this.isClubbable,
//     required this.isFromExistingPost,
//     this.price,
//     this.description,
//   });
// }

// class PostItem {
//   final String name;
//   final String category;
//   final String imageUrl;
//   final bool isClubbable;

//   PostItem({
//     required this.name,
//     required this.category,
//     required this.imageUrl,
//     required this.isClubbable,
//   });
// }

// class NotificationItem {
//   final String message;
//   final DateTime date;
//   final String type;

//   NotificationItem({
//     required this.message,
//     required this.date,
//     required this.type,
//   });
// }

import 'package:flutter/foundation.dart';

class ProductPost {
  final String userName;
  final String timeAgo;
  final String category;
  final String title;
  final String distance;
  final String returnType;
  final String barterStatus;
  final String postType;
  final String tradeType;
  final String productLocation;
  final DateTime postedDate;
  final String wishListCategory;
  bool isFavorite;
  bool isHidden;
  final List<String> images;
  final int views;
  final String price;
  final String description;
  final String transportationOption;
  final bool isVerified;
  final bool canClubItems;

  ProductPost({
    required this.userName,
    required this.timeAgo,
    required this.category,
    required this.title,
    required this.distance,
    required this.returnType,
    required this.barterStatus,
    required this.postType,
    required this.tradeType,
    required this.productLocation,
    required this.postedDate,
    required this.wishListCategory,
    required this.isFavorite,
    required this.isHidden,
    required this.images,
    required this.views,
    required this.price,
    required this.description,
    required this.transportationOption,
    required this.isVerified,
    required this.canClubItems,
  });
}

class UserItem {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final bool isClubbable;
  final bool isFromExistingPost;
  final String? price;
  final List<String>? images;
  final String? description;

  UserItem({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.isClubbable,
    required this.isFromExistingPost,
    this.price,
    this.images,
    this.description,
  });
}

class PostItem {
  final String name;
  final String category;
  final String imageUrl;
  final bool isClubbable;

  PostItem({
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.isClubbable,
  });
}

class NotificationItem {
  final String message;
  final DateTime date;
  final String type;

  NotificationItem({
    required this.message,
    required this.date,
    required this.type,
  });
}
