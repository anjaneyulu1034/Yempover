import 'dart:convert';
import 'dart:io';
import 'package:yempover_app/constants/api_constants.dart';
import 'package:yempover_app/models/chats/trade_chat.dart';
import 'package:http/http.dart' as http;
import 'package:yempover_app/services/token_service.dart';
import 'package:yempover_app/utils/error_handler.dart';

enum ChatReferenceType { product, service }

class TradeChatService {
  final http.Client _client = http.Client();
  final TokenService _tokenService = TokenService();

  // Headers with Authorization
  Future<Map<String, String>> _getHeaders() async {
    final token = await _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Multipart headers for image upload
  Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await _tokenService.getToken();
    return {'Accept': 'application/json', 'Authorization': 'Bearer $token'};
  }

  // ==================== EXISTING METHODS ====================

  // 1. Initialize a new chat
  Future<TradeChat> initiateChat({
    required String responderId,
    String? productId,
    String? serviceId,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse('${ApiConstants.baseUrl}/trade-chat/initiate');

      if (productId == null && serviceId == null) {
        throw ArgumentError('Either productId or serviceId must be provided');
      }

      final Map<String, dynamic> body = {'responderId': responderId};

      if (productId != null && productId.isNotEmpty) {
        body['productId'] = productId;
      }

      if (serviceId != null && serviceId.isNotEmpty) {
        body['serviceId'] = serviceId;
      }

      final encodedBody = json.encode(body);

      print('📤 Initiating chat - URL: $url');
      print('📤 Body: $encodedBody');

      final response = await _client.post(
        url,
        headers: headers,
        body: encodedBody,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final chatResponse = TradeChatResponse.fromJson(jsonResponse);
        return chatResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error initiating chat: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 2. Get all chats with pagination
  Future<TradeChatsResponse> getAllChats({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (status != null) 'status': status,
      };

      final uri = Uri.parse(
        ApiConstants.tradeChats,
      ).replace(queryParameters: queryParams);

      print('📤 Getting all chats - URL: $uri');

      final response = await _client.get(uri, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return TradeChatsResponse.fromJson(json.decode(response.body));
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error getting chats: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 3. Get single chat by ID
  Future<TradeChat> getChatById(String chatId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatDetail(chatId));

      print('📤 Getting chat by ID - URL: $url');

      final response = await _client.get(url, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final chatResponse = TradeChatResponse.fromJson(jsonResponse);
        return chatResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error getting chat: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 4. Send a text message
  Future<ChatMessage> sendMessage({
    required String chatId,
    required String messageText,
    String? imageUrl,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatMessages(chatId));

      final body = json.encode({
        'messageText': messageText,
        if (imageUrl != null) 'imageUrl': imageUrl,
      });

      print('📤 Sending message - URL: $url');
      print('📤 Body: $body');

      final response = await _client.post(url, headers: headers, body: body);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final messageResponse = MessageResponse.fromJson(jsonResponse);
        return messageResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error sending message: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 5. Upload image message - FIXED
  Future<ChatMessage> uploadImageMessage({
    required String chatId,
    required File imageFile,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatUploadImage(chatId));

      print('📤 Uploading image - URL: $url');

      final bytes = await imageFile.readAsBytes();
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode({
          'images': [base64Image],
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);

        // The API returns image URL in data.images array
        if (jsonResponse['data'] != null &&
            jsonResponse['data']['images'] != null &&
            jsonResponse['data']['images'].isNotEmpty) {
          final imageUrl = jsonResponse['data']['images'][0];

          // After uploading, send a message with the image URL
          final messageResponse = await sendMessage(
            chatId: chatId,
            messageText: '',
            imageUrl: imageUrl,
          );

          return messageResponse;
        } else {
          throw Exception('No image URL returned from upload');
        }
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 6. Create a price offer
  Future<TradeOffer> createPriceOffer({
    required String chatId,
    required double price,
    String? currency,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatOffer(chatId));

      final body = json.encode({
        'offerType': 'PRICE',
        'price': price,
        'currency': currency ?? 'USD',
        'barterItemTitle': null,
      });

      print('📤 Creating price offer - URL: $url');
      print('📤 Body: $body');

      final response = await _client.post(url, headers: headers, body: body);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error creating price offer: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 7. Create a barter offer
  Future<TradeOffer> createBarterOffer({
    required String chatId,
    required String barterItemTitle,
    String? barterItemDescription,
    List<String>? barterItemImages,
    List<String>? barterWishCategories,
    List<String>? barterItemIds,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatOffer(chatId));

      final body = json.encode({
        'offerType': 'BARTER',
        'price': null,
        'barterItemTitle': barterItemTitle,
        'barterItemDescription': barterItemDescription,
        'barterItemImages': barterItemImages ?? [],
        'barterWishCategories': barterWishCategories ?? [],
        // Real product ids of the offered items — lets the backend look up
        // their actual listed price and enforce equal-value matching for a
        // pure barter offer, instead of only trusting client-side math.
        'barterItemIds': barterItemIds ?? [],
      });

      print('📤 Creating barter offer - URL: $url');
      print('📤 Body: $body');

      final response = await _client.post(url, headers: headers, body: body);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error creating barter offer: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 7b. Create a combined (price + barter) offer
  Future<TradeOffer> createBothOffer({
    required String chatId,
    required double price,
    required String barterItemTitle,
    String? barterItemDescription,
    List<String>? barterItemImages,
    List<String>? barterWishCategories,
    List<String>? barterItemIds,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatOffer(chatId));

      final body = json.encode({
        'offerType': 'BOTH',
        'price': price,
        'currency': 'USD',
        'barterItemTitle': barterItemTitle,
        'barterItemDescription': barterItemDescription,
        'barterItemImages': barterItemImages ?? [],
        'barterWishCategories': barterWishCategories ?? [],
        'barterItemIds': barterItemIds ?? [],
      });

      print('📤 Creating BOTH offer - URL: $url');
      print('📤 Body: $body');

      final response = await _client.post(url, headers: headers, body: body);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error creating BOTH offer: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 8. Mark messages as read
  Future<bool> markMessagesAsRead(String chatId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatMarkRead(chatId));

      print('📤 Marking messages as read - URL: $url');

      final response = await _client.patch(url, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return jsonResponse['data']?['success'] ?? false;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 9. Accept an offer - FIXED
  Future<TradeOffer> acceptOffer(String chatId, String offerId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.acceptOffer(chatId, offerId));

      print('📤 Accepting offer - URL: $url');

      final response = await _client.patch(url, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error accepting offer: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 10. Reject an offer - FIXED
  Future<TradeOffer> rejectOffer(String chatId, String offerId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.rejectOffer(chatId, offerId));

      print('📤 Rejecting offer - URL: $url');

      final response = await _client.patch(url, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error rejecting offer: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 11. Counter an offer - FIXED
  Future<TradeOffer> counterOffer({
    required String chatId,
    required String offerId,
    double? price,
    String? barterItemTitle,
    String? barterItemDescription,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.counterOffer(chatId, offerId));

      final body = json.encode({
        if (price != null) 'price': price,
        if (barterItemTitle != null) 'barterItemTitle': barterItemTitle,
        if (barterItemDescription != null)
          'barterItemDescription': barterItemDescription,
      });

      print('📤 Countering offer - URL: $url');
      print('📤 Body: $body');

      final response = await _client.post(url, headers: headers, body: body);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error countering offer: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 12. Withdraw an offer
  Future<TradeOffer> withdrawOffer(String offerId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.withdrawOffer(offerId));

      print('📤 Withdrawing offer - URL: $url');

      final response = await _client.patch(url, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error withdrawing offer: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 13. Complete a trade
  Future<TradeChat> completeTrade(String chatId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatComplete(chatId));

      print('📤 Completing trade - URL: $url');

      final response = await _client.patch(url, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final chatData = TradeChat.fromJson(jsonResponse['data']);
        return chatData;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error completing trade: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 14. Cancel a trade
  Future<TradeChat> cancelTrade(String chatId, {String? reason}) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatCancel(chatId));
      final body = json.encode({'reason': reason ?? ''});

      print('📤 Cancelling trade - URL: $url');
      print('📤 Body: $body');

      final response = await _client.patch(
        url,
        headers: headers,
        body: body,
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return await getChatById(chatId);
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error cancelling trade: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 15. Archive a chat
  Future<TradeChat> archiveChat(String chatId) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatArchive(chatId));

      print('📤 Archiving chat - URL: $url');

      final response = await _client.patch(url, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final chatResponse = TradeChatResponse.fromJson(jsonResponse);
        return chatResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error archiving chat: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 16. Get inbox chats
  Future<InboxOutboxResponse> getInboxChats({
    int page = 1,
    int limit = 20,
    String? productId,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (productId != null && productId.isNotEmpty) 'productId': productId,
      };

      final uri = Uri.parse(
        ApiConstants.tradeChatInbox,
      ).replace(queryParameters: queryParams);

      print('📤 Getting inbox chats - URL: $uri');

      final response = await _client.get(uri, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return InboxOutboxResponse.fromJson(json.decode(response.body));
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error getting inbox chats: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 17. Get outbox chats
  Future<InboxOutboxResponse> getOutboxChats({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      final uri = Uri.parse(
        ApiConstants.tradeChatOutbox,
      ).replace(queryParameters: queryParams);

      print('📤 Getting outbox chats - URL: $uri');

      final response = await _client.get(uri, headers: headers);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return InboxOutboxResponse.fromJson(json.decode(response.body));
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error getting outbox chats: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 18. Create a counter offer with full details
  Future<TradeOffer> createCounterOffer({
    required String chatId,
    required String offerId,
    required String offerType,
    double? price,
    String? currency,
    String? barterItemTitle,
    String? barterItemDescription,
    List<String> barterItemImages = const [],
    List<String> barterWishCategories = const [],
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.counterOffer(chatId, offerId));

      Map<String, dynamic> body;

      if (offerType == 'PRICE') {
        body = {
          'offerType': 'PRICE',
          'price': price ?? 0,
          'currency': currency ?? 'USD',
          'barterItemTitle': '',
          'barterItemDescription': '',
          'barterItemImages': [],
          'barterWishCategories': [],
        };
      } else if (offerType == 'BOTH') {
        body = {
          'offerType': 'BOTH',
          'price': price ?? 0,
          'currency': currency ?? 'USD',
          'barterItemTitle': barterItemTitle ?? '',
          'barterItemDescription': barterItemDescription ?? '',
          'barterItemImages': barterItemImages,
          'barterWishCategories': barterWishCategories,
        };
      } else {
        body = {
          'offerType': 'BARTER',
          'price': null,
          'barterItemTitle': barterItemTitle ?? '',
          'barterItemDescription': barterItemDescription ?? '',
          'barterItemImages': barterItemImages,
          'barterWishCategories': barterWishCategories,
        };
      }

      print('📤 Creating counter offer - URL: $url');
      print('📤 Body: ${json.encode(body)}');

      final response = await _client.post(
        url,
        headers: headers,
        body: json.encode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error creating counter offer: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 19. Accept an offer with details
  Future<TradeOffer> acceptOfferWithDetails({
    required String chatId,
    required String offerId,
    required String offerType,
    double? price,
    String? currency,
    String? barterItemTitle,
    String? barterItemDescription,
    List<String> barterItemImages = const [],
    List<String> barterWishCategories = const [],
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.acceptOffer(chatId, offerId));

      Map<String, dynamic> body;

      if (offerType == 'PRICE') {
        body = {
          'offerType': 'PRICE',
          'price': price ?? 0,
          'currency': currency ?? 'USD',
          'barterItemTitle': '',
          'barterItemDescription': '',
          'barterItemImages': [],
          'barterWishCategories': [],
        };
      } else if (offerType == 'BOTH') {
        body = {
          'offerType': 'BOTH',
          'price': price ?? 0,
          'currency': currency ?? 'USD',
          'barterItemTitle': barterItemTitle ?? '',
          'barterItemDescription': barterItemDescription ?? '',
          'barterItemImages': barterItemImages,
          'barterWishCategories': barterWishCategories,
        };
      } else {
        body = {
          'offerType': 'BARTER',
          'price': null,
          'barterItemTitle': barterItemTitle ?? '',
          'barterItemDescription': barterItemDescription ?? '',
          'barterItemImages': barterItemImages,
          'barterWishCategories': barterWishCategories,
        };
      }

      print('📤 Accepting offer with details - URL: $url');
      print('📤 Body: ${json.encode(body)}');

      final response = await _client.patch(
        url,
        headers: headers,
        body: json.encode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error accepting offer with details: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 20. Reject an offer with details
  Future<TradeOffer> rejectOfferWithDetails({
    required String chatId,
    required String offerId,
    required String offerType,
    double? price,
    String? currency,
    String? barterItemTitle,
    String? barterItemDescription,
    List<String> barterItemImages = const [],
    List<String> barterWishCategories = const [],
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.rejectOffer(chatId, offerId));

      Map<String, dynamic> body;

      if (offerType == 'PRICE') {
        body = {
          'offerType': 'PRICE',
          'price': price ?? 0,
          'currency': currency ?? 'USD',
          'barterItemTitle': '',
          'barterItemDescription': '',
          'barterItemImages': [],
          'barterWishCategories': [],
        };
      } else if (offerType == 'BOTH') {
        body = {
          'offerType': 'BOTH',
          'price': price ?? 0,
          'currency': currency ?? 'USD',
          'barterItemTitle': barterItemTitle ?? '',
          'barterItemDescription': barterItemDescription ?? '',
          'barterItemImages': barterItemImages,
          'barterWishCategories': barterWishCategories,
        };
      } else {
        body = {
          'offerType': 'BARTER',
          'price': null,
          'barterItemTitle': barterItemTitle ?? '',
          'barterItemDescription': barterItemDescription ?? '',
          'barterItemImages': barterItemImages,
          'barterWishCategories': barterWishCategories,
        };
      }

      print('📤 Rejecting offer with details - URL: $url');
      print('📤 Body: ${json.encode(body)}');

      final response = await _client.patch(
        url,
        headers: headers,
        body: json.encode(body),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final offerResponse = OfferResponse.fromJson(jsonResponse);
        return offerResponse.data;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error rejecting offer with details: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 21. Mark deal as completed
  Future<TradeChat> markDealCompleted({
    required String chatId,
    String remarks = '',
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatDealCompleted(chatId));

      final body = json.encode({'remarks': remarks});

      print('📤 Marking deal as completed - URL: $url');
      print('📤 Body: $body');

      final response = await _client.post(url, headers: headers, body: body);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return await getChatById(chatId);
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error marking deal as completed: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // 22. Block a user
  Future<bool> blockUser({
    required String chatId,
    required String userIdToBlock,
  }) async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatBlockUser(chatId));

      final body = json.encode({'userIdToBlock': userIdToBlock});

      print('📤 Blocking user - URL: $url');
      print('📤 Body: $body');

      final response = await _client.post(url, headers: headers, body: body);

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        final successResponse = SuccessResponse.fromJson(jsonResponse);
        return successResponse.isSuccess;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error blocking user: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // Total unread trade-chat messages across all of the user's chats — for a
  // persistent badge (nav bar, profile icon), not tied to any one loaded page.
  Future<int> getUnreadMessageCount() async {
    try {
      final headers = await _getHeaders();
      final url = Uri.parse(ApiConstants.tradeChatUnreadCount);

      final response = await _client.get(url, headers: headers);

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return (jsonResponse['data']?['unreadCount'] as num?)?.toInt() ?? 0;
      } else {
        throw await ErrorHandler.handleHttpError(response);
      }
    } catch (e) {
      print('❌ Error getting trade-chat unread count: $e');
      throw ErrorHandler.handleError(e);
    }
  }

  // Close client
  void dispose() {
    _client.close();
  }
}
