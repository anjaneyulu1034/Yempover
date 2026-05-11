// models/update_profile_image_request.dart
class UpdateProfileImageRequest {
  final String image; // Full data URL with base64

  UpdateProfileImageRequest({required this.image});

  Map<String, dynamic> toJson() {
    return {'image': image};
  }
}

// models/update_profile_image_response.dart
class UpdateProfileImageResponse {
  final String status;
  final String message;
  final ProfileImageData data;

  UpdateProfileImageResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory UpdateProfileImageResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileImageResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      data: ProfileImageData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class ProfileImageData {
  final UserImageInfo user;
  final String url;
  final String base64;

  ProfileImageData({
    required this.user,
    required this.url,
    required this.base64,
  });

  factory ProfileImageData.fromJson(Map<String, dynamic> json) {
    return ProfileImageData(
      user: UserImageInfo.fromJson(json['user'] as Map<String, dynamic>),
      url: json['url'] as String,
      base64: json['base64'] as String,
    );
  }
}

class UserImageInfo {
  final String id;
  final String profileImage;

  UserImageInfo({required this.id, required this.profileImage});

  factory UserImageInfo.fromJson(Map<String, dynamic> json) {
    return UserImageInfo(
      id: json['id'] as String,
      profileImage: json['profileImage'] as String,
    );
  }
}
