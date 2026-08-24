class ReportPostResponse {
  final String status;
  final String message;
  final ReportData data;

  ReportPostResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ReportPostResponse.fromJson(Map<String, dynamic> json) {
    return ReportPostResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: ReportData.fromJson(json['data'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'message': message, 'data': data.toJson()};
  }
}

class ReportData {
  final Report report;

  ReportData({required this.report});

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(report: Report.fromJson(json['report'] ?? {}));
  }

  Map<String, dynamic> toJson() {
    return {'report': report.toJson()};
  }
}

class Report {
  final String id;
  final String reportedById;
  final String productId;
  final String? serviceId;
  final String reason;
  final String description;
  final String status;
  final String? adminNotes;
  final DateTime reportedDate;
  final DateTime? reviewedDate;
  final DateTime? actionTakenDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Report({
    required this.id,
    required this.reportedById,
    required this.productId,
    this.serviceId,
    required this.reason,
    required this.description,
    required this.status,
    this.adminNotes,
    required this.reportedDate,
    this.reviewedDate,
    this.actionTakenDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? '',
      reportedById: json['reportedById'] ?? '',
      productId: json['productId'] ?? '',
      serviceId: json['serviceId'],
      reason: json['reason'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      adminNotes: json['adminNotes'],
      reportedDate: DateTime.parse(
        json['reportedDate'] ?? DateTime.now().toIso8601String(),
      ),
      reviewedDate: json['reviewedDate'] != null
          ? DateTime.parse(json['reviewedDate'])
          : null,
      actionTakenDate: json['actionTakenDate'] != null
          ? DateTime.parse(json['actionTakenDate'])
          : null,
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
      'reportedById': reportedById,
      'productId': productId,
      'serviceId': serviceId,
      'reason': reason,
      'description': description,
      'status': status,
      'adminNotes': adminNotes,
      'reportedDate': reportedDate.toIso8601String(),
      'reviewedDate': reviewedDate?.toIso8601String(),
      'actionTakenDate': actionTakenDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
