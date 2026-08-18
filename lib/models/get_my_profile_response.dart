// lib/models/get_my_profile_response.dart (Updated)
class GetMyProfileResponse {
  String? status;
  String? message;
  ProfileData? data;

  GetMyProfileResponse({this.status, this.message, this.data});

  GetMyProfileResponse.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? ProfileData.fromJson(json['data']) : null;
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

class ProfileData {
  String? id;
  String? firstName;
  String? lastName;
  String? email;
  String? mobileNumber;
  String? profileImage;
  dynamic homeAddress; // Changed from Null? to dynamic to accept String or null
  dynamic latitude; // Changed from Null? to dynamic
  dynamic longitude; // Changed from Null? to dynamic
  String? status;
  String? role;
  String? registrationDate;
  String? lastLoginDate;
  dynamic deletedAt;
  dynamic termsAcceptedAt;
  int? totalTradesCompleted;
  int? totalPosts;
  dynamic subscriptionPlan;
  String? subscriptionPlanId;
  String? subscriptionStartDate;
  String? subscriptionEndDate;
  String? createdAt;
  String? updatedAt;
  bool? shareEmail;
  bool? sharePhone;
  bool? notificationEnabled;
  bool? verificationPending;

  ProfileData({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.mobileNumber,
    this.profileImage,
    this.homeAddress,
    this.latitude,
    this.longitude,
    this.status,
    this.role,
    this.registrationDate,
    this.lastLoginDate,
    this.deletedAt,
    this.termsAcceptedAt,
    this.totalTradesCompleted,
    this.totalPosts,
    this.subscriptionPlan,
    this.subscriptionPlanId,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.createdAt,
    this.updatedAt,
    this.shareEmail,
    this.sharePhone,
    this.notificationEnabled,
    this.verificationPending,
  });

  ProfileData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    firstName = json['firstName'];
    lastName = json['lastName'];
    email = json['email'];
    mobileNumber = json['mobileNumber'];
    profileImage = json['profileImage'];
    homeAddress = json['homeAddress'];
    latitude = json['latitude'];
    longitude = json['longitude'];
    status = json['status'];
    role = json['role'];
    registrationDate = json['registrationDate'];
    lastLoginDate = json['lastLoginDate'];
    deletedAt = json['deletedAt'];
    termsAcceptedAt = json['termsAcceptedAt'];
    totalTradesCompleted = json['totalTradesCompleted'];
    totalPosts = json['totalPosts'] ?? json['totalPost'] ?? json['postsCount'];
    subscriptionPlan = json['subscriptionPlan'];
    subscriptionPlanId = json['subscriptionPlanId'];
    subscriptionStartDate = json['subscriptionStartDate'];
    subscriptionEndDate = json['subscriptionEndDate'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    shareEmail = json['shareEmail'];
    sharePhone = json['sharePhone'];
    notificationEnabled = json['notificationEnabled'];
    verificationPending = json['verificationPending'] == true;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['firstName'] = firstName;
    data['lastName'] = lastName;
    data['email'] = email;
    data['mobileNumber'] = mobileNumber;
    data['profileImage'] = profileImage;
    data['homeAddress'] = homeAddress;
    data['latitude'] = latitude;
    data['longitude'] = longitude;
    data['status'] = status;
    data['role'] = role;
    data['registrationDate'] = registrationDate;
    data['lastLoginDate'] = lastLoginDate;
    data['deletedAt'] = deletedAt;
    data['termsAcceptedAt'] = termsAcceptedAt;
    data['totalTradesCompleted'] = totalTradesCompleted;
    data['totalPosts'] = totalPosts;
    data['subscriptionPlan'] = subscriptionPlan;
    data['subscriptionPlanId'] = subscriptionPlanId;
    data['subscriptionStartDate'] = subscriptionStartDate;
    data['subscriptionEndDate'] = subscriptionEndDate;
    data['createdAt'] = createdAt;
    data['updatedAt'] = updatedAt;
    data['shareEmail'] = shareEmail;
    data['sharePhone'] = sharePhone;
    data['notificationEnabled'] = notificationEnabled;
    return data;
  }
}
