// lib/models/api_response.dart
class ApiResponse<T> {
  final String status;
  final String message;
  final T? data;

  ApiResponse({required this.status, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    return ApiResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null && fromJson != null
          ? fromJson(json['data'] as Map<String, dynamic>)
          : json['data'] as T?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data};
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}
