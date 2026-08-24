// import 'package:shared_preferences/shared_preferences.dart';

// class AuthStorage {
//   static const String _tokenKey = 'auth_token';
//   static const String _userIdKey = 'user_id';
//   static const String _userNameKey = 'user_name';
//   static const String _userEmailKey = 'user_email';
//   static const String _userMobileKey = 'user_mobile';

//   static Future<void> saveToken(String token) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_tokenKey, token);
//   }

//   static Future<String?> getToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_tokenKey);
//   }

//   static Future<void> saveUser({
//     required String id,
//     String? name,
//     String? email,
//     String? mobile,
//   }) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(_userIdKey, id);
//     if (name != null) await prefs.setString(_userNameKey, name);
//     if (email != null) await prefs.setString(_userEmailKey, email);
//     if (mobile != null) await prefs.setString(_userMobileKey, mobile);
//   }

//   static Future<String?> getUserId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_userIdKey);
//   }

//   static Future<String?> getUserName() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_userNameKey);
//   }

//   static Future<String?> getUserMobile() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getString(_userMobileKey);
//   }

//   static Future<void> clear() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_tokenKey);
//     await prefs.remove(_userIdKey);
//     await prefs.remove(_userNameKey);
//     await prefs.remove(_userEmailKey);
//     await prefs.remove(_userMobileKey);
//   }

//   static Future<bool> isLoggedIn() async {
//     final token = await getToken();
//     return token != null;
//   }
// }
