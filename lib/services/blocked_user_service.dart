import 'dart:convert';

import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:YemPover_app/utils/error_handler.dart';
import 'package:http/http.dart' as http;

class BlockedUserItem {
  final String blockedId;
  final String fullName;
  final String? profileImage;
  final String? mobileNumber;
  final DateTime? blockedAt;

  BlockedUserItem({
    required this.blockedId,
    required this.fullName,
    this.profileImage,
    this.mobileNumber,
    this.blockedAt,
  });

  factory BlockedUserItem.fromJson(Map<String, dynamic> json) {
    final blocked = (json['blocked'] as Map<String, dynamic>?) ?? {};
    final firstName = (blocked['firstName'] ?? '').toString().trim();
    final lastName = (blocked['lastName'] ?? '').toString().trim();
    final name = '$firstName $lastName'.trim();

    return BlockedUserItem(
      blockedId: (json['blockedId'] ?? blocked['id'] ?? '').toString(),
      fullName: name.isNotEmpty ? name : 'Unknown User',
      profileImage: blocked['profileImage']?.toString(),
      mobileNumber: blocked['mobileNumber']?.toString(),
      blockedAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

class BlockedUserService {
  final http.Client _client = http.Client();
  final TokenService _tokenService = TokenService();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<BlockedUserItem>> getBlockedUsers({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiConstants.tradeChatBlockedUsers).replace(
        queryParameters: {'page': page.toString(), 'limit': limit.toString()},
      );

      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;
        final data = (body['data'] as Map<String, dynamic>?) ?? {};
        final items = (data['blockedUsers'] as List?) ?? const [];
        return items
            .whereType<Map<String, dynamic>>()
            .map(BlockedUserItem.fromJson)
            .toList();
      }

      throw await ErrorHandler.handleHttpError(response);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  Future<void> unblockUser(String blockedUserId) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiConstants.tradeChatUnblockUser(blockedUserId));
      final response = await _client.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        return;
      }

      throw await ErrorHandler.handleHttpError(response);
    } catch (e) {
      throw ErrorHandler.handleError(e);
    }
  }

  void dispose() {
    _client.close();
  }
}
