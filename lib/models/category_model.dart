// lib/models/category_model.dart
class CategoryResponse {
  final String status;
  final String message;
  final List<CategoryData> data;

  CategoryResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: (json['data'] as List)
          .map((item) => CategoryData.fromJson(item))
          .toList(),
    );
  }
}

class CategoryData {
  final String id;
  final String name;
  final String type;
  final int itemsCount;
  final List<ChildCategory> children;

  CategoryData({
    required this.id,
    required this.name,
    required this.type,
    required this.itemsCount,
    required this.children,
  });

  factory CategoryData.fromJson(Map<String, dynamic> json) {
    return CategoryData(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      itemsCount: json['itemsCount'] ?? 0,
      children: json['children'] != null
          ? (json['children'] as List)
                .map((child) => ChildCategory.fromJson(child))
                .toList()
          : [],
    );
  }
}

class ChildCategory {
  final String id;
  final String name;
  final int itemsCount;

  ChildCategory({
    required this.id,
    required this.name,
    required this.itemsCount,
  });

  factory ChildCategory.fromJson(Map<String, dynamic> json) {
    return ChildCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      itemsCount: json['itemsCount'] ?? 0,
    );
  }
}
