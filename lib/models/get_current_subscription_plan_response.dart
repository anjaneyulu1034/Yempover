class GetCurrentSubscriptionPlanResponse {
  String? status;
  String? message;
  CurrentPlan? data;

  GetCurrentSubscriptionPlanResponse({this.status, this.message, this.data});

  GetCurrentSubscriptionPlanResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];

    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      data = CurrentPlan.fromJson(json['data']);
    } else {
      data = null;
    }
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
  PlanDetails? plan;
  String? startDate;
  String? endDate;
  bool? isValid;
  bool? isFirstTimeFree;

  CurrentPlan({
    this.plan,
    this.startDate,
    this.endDate,
    this.isValid,
    this.isFirstTimeFree,
  });

  CurrentPlan.fromJson(Map<String, dynamic> json) {
    plan = json['plan'] != null ? PlanDetails.fromJson(json['plan']) : null;
    startDate = json['startDate'];
    endDate = json['endDate'];
    isValid = json['isValid'];
    isFirstTimeFree = json['isFirstTimeFree'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (plan != null) {
      data['plan'] = plan!.toJson();
    }
    data['startDate'] = startDate;
    data['endDate'] = endDate;
    data['isValid'] = isValid;
    data['isFirstTimeFree'] = isFirstTimeFree;
    return data;
  }

  // Helper getters for easier access
  String? get planName => plan?.name ?? 'Free Trial';
  String? get planId => plan?.id;
  double? get planAmount => plan?.amount ?? 0;
  String? get planDescription => plan?.description;
  List<String>? get planFeatures => plan?.features;
  String get status => isValid == true ? 'active' : 'inactive';
}

class PlanDetails {
  String? id;
  String? name;
  String? description;
  double? amount;
  int? durationDays;
  List<String>? features;
  bool? isActive;
  String? createdAt;
  String? updatedAt;

  PlanDetails({
    this.id,
    this.name,
    this.description,
    this.amount,
    this.durationDays,
    this.features,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  PlanDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    description = json['description'];
    amount = json['amount']?.toDouble();
    durationDays = json['durationDays'];
    features = json['features'] != null
        ? List<String>.from(json['features'])
        : [];
    isActive = json['isActive'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['amount'] = amount;
    data['durationDays'] = durationDays;
    data['features'] = features;
    data['isActive'] = isActive;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    return data;
  }

  String get formattedAmount {
    if (amount == null) return '\$0';
    return '\$${amount!.toStringAsFixed(2)}';
  }
}
