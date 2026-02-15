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
  Null? plan;
  Null? startDate;
  Null? endDate;
  bool? isValid;

  CurrentPlan({this.plan, this.startDate, this.endDate, this.isValid});

  CurrentPlan.fromJson(Map<String, dynamic> json) {
    plan = json['plan'];
    startDate = json['startDate'];
    endDate = json['endDate'];
    isValid = json['isValid'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['plan'] = plan;
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['isValid'] = isValid;
    return data;
  }
}
