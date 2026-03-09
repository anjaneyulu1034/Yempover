class DeleteAccountResponse {
  final String status;
  final String message;

  DeleteAccountResponse({required this.status, required this.message});

  factory DeleteAccountResponse.fromJson(Map<String, dynamic> json) {
    return DeleteAccountResponse(
      status: json['status'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message};
  }
}
