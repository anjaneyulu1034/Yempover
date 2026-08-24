class HidePostResponse {
  final String status;
  final String message;

  HidePostResponse({required this.status, required this.message});

  factory HidePostResponse.fromJson(Map<String, dynamic> json) {
    return HidePostResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message};
  }
}
