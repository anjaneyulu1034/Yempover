import 'package:YemPover_app/models/my_post2_model.dart';

class EditProductRequest {
  String title;
  String description;
  List<String> images;
  String status;
  String barterStatus;
  double? price;
  String categoryId;
  String? location;
  bool isListed;

  EditProductRequest({
    required this.title,
    required this.description,
    required this.images,
    required this.status,
    required this.barterStatus,
    this.price,
    required this.categoryId,
    this.location,
    required this.isListed,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'images': images,
      'status': status,
      'barterStatus': barterStatus,
      'price': price,
      'categoryId': categoryId,
      'location': location,
      'isListed': isListed,
    };
  }

  factory EditProductRequest.fromPost(MyPost post) {
    return EditProductRequest(
      title: post.title,
      description: post.description,
      images: post.images,
      status: post.status,
      barterStatus: post.barterStatus,
      price: post.price,
      categoryId: post.categoryId,
      location: post.location,
      isListed: post.isListed,
    );
  }
}
