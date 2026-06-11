class Inquiry {
  final String id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String message;
  final String status;
  final String sourcePlatform;
  final String? userId;
  final DateTime? receivedDate;
  final DateTime? contactedDate;
  final DateTime? closedDate;
  final String? adminNotes;
  final String? closingNotes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Inquiry({
    required this.id,
    this.name,
    this.email,
    this.phoneNumber,
    required this.message,
    required this.status,
    required this.sourcePlatform,
    this.userId,
    this.receivedDate,
    this.contactedDate,
    this.closedDate,
    this.adminNotes,
    this.closingNotes,
    this.createdAt,
    this.updatedAt,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      message: json['message'] as String,
      status: json['status'] as String,
      sourcePlatform: json['sourcePlatform'] as String,
      userId: json['userId'] as String?,
      receivedDate: json['receivedDate'] != null
          ? DateTime.parse(json['receivedDate'] as String)
          : null,
      contactedDate: json['contactedDate'] != null
          ? DateTime.parse(json['contactedDate'] as String)
          : null,
      closedDate: json['closedDate'] != null
          ? DateTime.parse(json['closedDate'] as String)
          : null,
      adminNotes: json['adminNotes'] as String?,
      closingNotes: json['closingNotes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
