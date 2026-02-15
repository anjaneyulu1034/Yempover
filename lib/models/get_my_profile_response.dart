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
  Null? homeAddress;
  Null? latitude;
  Null? longitude;
  String? registrationDate;
  int? totalTradesCompleted;
  Null? subscriptionPlan;
  bool? shareEmail;
  bool? sharePhone;
  bool? notificationEnabled;

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
    this.registrationDate,
    this.totalTradesCompleted,
    this.subscriptionPlan,
    this.shareEmail,
    this.sharePhone,
    this.notificationEnabled,
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
    registrationDate = json['registrationDate'];
    totalTradesCompleted = json['totalTradesCompleted'];
    subscriptionPlan = json['subscriptionPlan'];
    shareEmail = json['shareEmail'];
    sharePhone = json['sharePhone'];
    notificationEnabled = json['notificationEnabled'];
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
    data['registrationDate'] = registrationDate;
    data['totalTradesCompleted'] = totalTradesCompleted;
    data['subscriptionPlan'] = subscriptionPlan;
    data['shareEmail'] = shareEmail;
    data['sharePhone'] = sharePhone;
    data['notificationEnabled'] = notificationEnabled;
    return data;
  }
}
