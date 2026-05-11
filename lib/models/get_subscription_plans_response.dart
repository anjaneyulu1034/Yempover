class GetSubscriptionPlansResponse {
  String? status;
  String? message;
  SubscriptionPlans? data;

  GetSubscriptionPlansResponse({this.status, this.message, this.data});

  GetSubscriptionPlansResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null
        ? SubscriptionPlans.fromJson(json['data'])
        : null;
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

class SubscriptionPlans {
  List<Plans>? plans;

  SubscriptionPlans({this.plans});

  SubscriptionPlans.fromJson(Map<String, dynamic> json) {
    if (json['plans'] != null) {
      plans = <Plans>[];
      json['plans'].forEach((v) {
        plans!.add(Plans.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (plans != null) {
      data['plans'] = plans!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Plans {
  String? id;
  String? name;
  String? description;
  double? amount;
  int? durationDays;
  List<String>? features;
  bool? isActive;
  String? createdAt;
  String? updatedAt;

  Plans({
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

  Plans.fromJson(Map<String, dynamic> json) {
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

  // Helper method to format price
  String get formattedAmount {
    if (amount == null) return '\$0';
    return '\$${amount!.toStringAsFixed(2)}';
  }
}
