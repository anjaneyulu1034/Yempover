class GetCurrentSubscriptionPlanResponse {
  String? status;
  String? message;
  CurrentPlan? data;

  GetCurrentSubscriptionPlanResponse({this.status, this.message, this.data});

  GetCurrentSubscriptionPlanResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? CurrentPlan.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }
}

class CurrentPlan {
  String? id;
  String? userId;
  String? planId;
  String? planName; // Added this field
  String? status; // Added this field
  String? startDate;
  String? endDate;
  bool? isActive;
  String? createdAt;
  String? updatedAt;

  CurrentPlan({
    this.id,
    this.userId,
    this.planId,
    this.planName, // Added
    this.status, // Added
    this.startDate,
    this.endDate,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  CurrentPlan.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    userId = json['userId'];
    planId = json['planId'];
    planName = json['planName']; // Added
    status = json['status']; // Added
    startDate = json['startDate'];
    endDate = json['endDate'];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['userId'] = userId;
    data['planId'] = planId;
    data['planName'] = planName; // Added
    data['status'] = status; // Added
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['isActive'] = isActive;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }
}
