class LogoutRequest {
  final String? refreshToken;

  LogoutRequest({this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken ?? ''};
  }
}
