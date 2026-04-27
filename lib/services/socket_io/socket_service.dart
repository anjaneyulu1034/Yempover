import 'dart:async';
import 'dart:convert';
import 'package:YemPover_app/constants/api_constants.dart';
import 'package:YemPover_app/services/token_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'dart:io';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  String? _token;
  final String _baseUrl = ApiConstants.baseUrl.replaceAll('/api/mobile', '');
  final Map<String, List<Function(dynamic)>> _listeners = {};
  final Set<String> _joinedChatIds = <String>{};
  final TokenService _tokenService = TokenService();
  bool _isConnected = false;

  // Connection status getter
  bool get isConnected => _socket?.connected ?? false;

  void init({required String token}) {
    if (_token == token && _socket != null) {
      _connect();
      return;
    }

    if (_socket != null && _token != token) {
      updateToken(token);
      return;
    }

    _token = token;
    _connect();
  }

  void _connect() {
    if (_socket != null) {
      if (_socket!.connected) return;
      _socket!.connect();
      return;
    }

    print('🔌 Socket: Connecting to $_baseUrl');

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': _token})
          .setExtraHeaders({'Authorization': 'Bearer $_token'})
          .setQuery({'token': _token})
          .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    void handleIncomingMessage(dynamic data) {
      final mapped = {
        'chatId': data?['tradeChatId'] ?? data?['chatId'],
        'message': data?['message'] ?? data,
      };
      print('📩 New message received: $mapped');
      _notifyListeners('new_message', mapped);
      _notifyListeners('chat_updated', {'chatId': mapped['chatId']});
    }

    _socket!.on('connect', (_) {
      print('✅ Socket connected: ${_socket!.id}');
      _isConnected = true;
      _rejoinChatRooms();
      _notifyListeners('connect', null);
    });

    _socket!.on('disconnect', (_) {
      print('❌ Socket disconnected');
      _isConnected = false;
      _notifyListeners('disconnect', null);
    });

    _socket!.on('connect_error', (err) {
      print('⚠️ Socket connection error: $err');
      _isConnected = false;
      _notifyListeners('connect_error', err);
    });

    _socket!.on('reconnect', (attempt) {
      print('🔄 Socket reconnected after $attempt attempts');
      _isConnected = true;
      _rejoinChatRooms();
      _notifyListeners('reconnect', attempt);
    });

    // Chat message events (backend -> app event translation)
    _socket!.on('chat:message_received', handleIncomingMessage);
    _socket!.on('new_message', handleIncomingMessage);
    _socket!.on('message_received', handleIncomingMessage);

    // Offer events
    _socket!.on('offer:received', (data) {
      final mapped = {
        'chatId': data?['tradeChatId'] ?? data?['chatId'],
        'offer': data,
      };
      print('💰 Offer created: $mapped');
      _notifyListeners('offer_created', mapped);
    });

    _socket!.on('offer:accepted', (data) {
      print('✅ Offer accepted: $data');
      _notifyListeners('offer_accepted', data);
    });

    _socket!.on('offer:rejected', (data) {
      print('❌ Offer rejected: $data');
      _notifyListeners('offer_rejected', data);
    });

    _socket!.on('offer:withdrawn', (data) {
      print('↩️ Offer withdrawn: $data');
      _notifyListeners('offer_withdrawn', data);
    });

    // Chat status events
    _socket!.on('chat:user_online', (data) {
      print('🟢 Chat user online: $data');
      _notifyListeners('user_presence', {...?data, 'isOnline': true});
    });

    _socket!.on('chat:user_offline', (data) {
      print('⚪ Chat user offline: $data');
      _notifyListeners('user_presence', {...?data, 'isOnline': false});
    });

    // Typing events
    _socket!.on('chat:user_typing', (data) {
      final mapped = {...?data, 'isTyping': true};
      print('✏️ Typing: $mapped');
      _notifyListeners('typing', mapped);
    });

    _socket!.on('chat:user_stopped_typing', (data) {
      final mapped = {...?data, 'isTyping': false};
      print('⌨️ Stopped typing: $mapped');
      _notifyListeners('typing', mapped);
    });

    // Deal completion events
    _socket!.on('deal:completed', (data) {
      print('🎉 Deal completed: $data');
      _notifyListeners('deal_completed', data);
    });

    _socket!.on('deal:cancelled', (data) {
      print('🚫 Deal cancelled: $data');
      _notifyListeners('deal_cancelled', data);
    });

    _socket!.on('messages_read', (data) {
      _notifyListeners('messages_read', data);
    });

    // User presence
    _socket!.on('user_online', (data) {
      print('🟢 User online: $data');
      _notifyListeners('user_presence', {...?data, 'isOnline': true});
    });

    _socket!.on('user_offline', (data) {
      print('⚪ User offline: $data');
      _notifyListeners('user_presence', {...?data, 'isOnline': false});
    });

    // Error handling
    _socket!.on('error', (error) {
      print('⚠️ Socket error: $error');
      _notifyListeners('error', error);
    });
  }

  void updateToken(String token) {
    _token = token;
    if (_socket != null) {
      _socket!.io.options?['auth'] = {'token': _token};
      _socket!.io.options?['extraHeaders'] = {
        'Authorization': 'Bearer $_token',
      };
      _socket!.io.options?['query'] = {'token': _token};
      if (!_socket!.connected) {
        _socket!.connect();
      } else {
        // Reconnect to apply new token
        _socket!.disconnect();
        _socket!.connect();
      }
    }
  }

  // Join a specific chat room
  void joinChat(String chatId) {
    _joinedChatIds.add(chatId);

    if (!_isConnected) {
      print('⚠️ Socket not connected, queued join for chat: $chatId');
      _socket?.connect();
      return;
    }

    print('🔗 Joining chat: $chatId');
    _socket?.emitWithAck(
      'chat:join',
      {'chatId': chatId},
      ack: (response) {
        print('✅ Joined chat room ack for $chatId: $response');

        if (response is Map<String, dynamic>) {
          final otherUserId = response['otherUserId'];
          final otherUserOnline = response['otherUserOnline'];
          if (otherUserId != null && otherUserOnline != null) {
            _notifyListeners('user_presence', {
              'chatId': chatId,
              'userId': otherUserId,
              'isOnline': otherUserOnline == true,
            });
          }
        }
      },
    );
  }

  // Leave a chat room
  void leaveChat(String chatId) {
    _joinedChatIds.remove(chatId);
    print('🚪 Leaving chat: $chatId');
    _socket?.emit('chat:leave', {'chatId': chatId});
  }

  void _rejoinChatRooms() {
    for (final chatId in _joinedChatIds) {
      _socket?.emitWithAck(
        'chat:join',
        {'chatId': chatId},
        ack: (response) {
          print('🔁 Rejoined chat room ack for $chatId: $response');

          if (response is Map<String, dynamic>) {
            final otherUserId = response['otherUserId'];
            final otherUserOnline = response['otherUserOnline'];
            if (otherUserId != null && otherUserOnline != null) {
              _notifyListeners('user_presence', {
                'chatId': chatId,
                'userId': otherUserId,
                'isOnline': otherUserOnline == true,
              });
            }
          }
        },
      );
    }
  }

  // Send a message
  void sendMessage(String chatId, Map<String, dynamic> message) {
    if (!_isConnected) {
      print('⚠️ Cannot send message: Socket not connected');
      return;
    }

    print('📤 Sending message to chat $chatId: $message');
    _socket?.emit('chat:message', {
      'chatId': chatId,
      'messageText': message['messageText'] ?? message['text'] ?? '',
      'imageUrl': message['imageUrl'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> sendMessageWithAck({
    required String chatId,
    String? messageText,
    String? imageUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!await _ensureConnected()) {
      throw Exception('Socket not connected');
    }

    final completer = Completer<Map<String, dynamic>>();

    _socket?.emitWithAck(
      'chat:message',
      {
        'chatId': chatId,
        'messageText': messageText ?? '',
        'imageUrl': imageUrl,
      },
      ack: (response) {
        if (response is Map<String, dynamic>) {
          final success = response['success'] == true;
          if (success) {
            final message = response['message'];
            if (message is Map<String, dynamic>) {
              completer.complete(message);
              return;
            }
            completer.complete(response);
            return;
          }

          completer.completeError(
            Exception(response['error'] ?? 'Failed to send message'),
          );
          return;
        }

        completer.completeError(Exception('Invalid socket ack response'));
      },
    );

    return completer.future.timeout(
      timeout,
      onTimeout: () => throw TimeoutException('Message ack timed out'),
    );
  }

  Future<bool> _ensureConnected({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    if (isConnected) return true;

    final latestToken = await _tokenService.getToken();
    if (latestToken == null || latestToken.isEmpty) {
      return false;
    }

    if (_token != latestToken || _socket == null) {
      init(token: latestToken);
    } else if (!_socket!.connected) {
      _socket!.connect();
    }

    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      if (isConnected) return true;
      await Future.delayed(const Duration(milliseconds: 120));
    }

    return isConnected;
  }

  // Send typing indicator
  void sendTyping(String chatId, bool isTyping) {
    if (!_isConnected) return;

    _socket?.emit(isTyping ? 'chat:typing' : 'chat:stop_typing', {
      'chatId': chatId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Mark messages as read
  void markMessagesRead(String chatId, List<String> messageIds) {
    if (!_isConnected) return;

    _socket?.emitWithAck(
      'messages:read',
      {'chatId': chatId, 'messageIds': messageIds},
      ack: (response) {
        if (response is Map<String, dynamic> && response['success'] != true) {
          print('⚠️ messages:read ack error: ${response['error']}');
        }
      },
    );
  }

  // Create an offer (emit event)
  void emitOfferCreated(String chatId, Map<String, dynamic> offerData) {
    if (!_isConnected) return;

    _socket?.emit('offer:created', {
      'chatId': chatId,
      'offerId': offerData['id'] ?? offerData['_id'],
      'offer': offerData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Accept an offer (emit event)
  void emitOfferAccepted(String chatId, String offerId) {
    if (!_isConnected) return;

    _socket?.emit('offer:accepted', {
      'chatId': chatId,
      'offerId': offerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Reject an offer (emit event)
  void emitOfferRejected(String chatId, String offerId) {
    if (!_isConnected) return;

    _socket?.emit('offer:rejected', {
      'chatId': chatId,
      'offerId': offerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Withdraw an offer
  void emitOfferWithdrawn(String chatId, String offerId) {
    if (!_isConnected) return;

    _socket?.emit('offer:withdrawn', {
      'chatId': chatId,
      'offerId': offerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Complete deal
  void emitDealCompleted(String chatId, Map<String, dynamic> dealData) {
    if (!_isConnected) return;

    _socket?.emit('deal:completed', {
      'chatId': chatId,
      'remarks': dealData['remarks'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Cancel deal
  void emitDealCancelled(String chatId) {
    if (!_isConnected) return;

    _socket?.emit('deal:cancelled', {
      'chatId': chatId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Add event listener
  void on(String event, Function(dynamic) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  // Remove event listener
  void off(String event, [Function? callback]) {
    if (callback == null) {
      _listeners.remove(event);
    } else {
      _listeners[event]?.remove(callback);
    }
  }

  // Remove all listeners
  void offAll() {
    _listeners.clear();
  }

  // Notify all listeners for an event
  void _notifyListeners(String event, dynamic data) {
    final listeners = _listeners[event];
    if (listeners != null) {
      for (var listener in listeners) {
        try {
          listener(data);
        } catch (e) {
          print('Error in listener for event $event: $e');
        }
      }
    }
  }

  // Check connection status
  void checkConnection() {
    if (_socket != null) {
      print('🔌 Socket connection status: ${_socket!.connected}');
    }
  }

  // Reconnect manually
  void reconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.connect();
    }
  }

  // Upload file via presigned URL
  Future<String?> uploadFileViaPresigned(
    String presignApiPath,
    File file,
    String contentType, {
    Map<String, String>? headers,
  }) async {
    try {
      // Get presigned URL from your API
      final presignUrl = await _getPresignedUrl(presignApiPath);
      if (presignUrl == null) return null;

      // Read file bytes
      final bytes = await file.readAsBytes();

      // Upload to presigned URL
      final putResp = await http.put(
        Uri.parse(presignUrl),
        headers: {'Content-Type': contentType, ...?headers},
        body: bytes,
      );

      if (putResp.statusCode == 200 || putResp.statusCode == 204) {
        // Return the accessible URL (extract from presigned URL or your API response)
        return presignUrl.split('?').first;
      }

      print('❌ Upload failed with status: ${putResp.statusCode}');
      return null;
    } catch (e) {
      print('❌ Upload error: $e');
      return null;
    }
  }

  Future<String?> _getPresignedUrl(String apiPath) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$apiPath'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['presignedUrl'] ?? data['url'];
      }

      return null;
    } catch (e) {
      print('❌ Error getting presigned URL: $e');
      return null;
    }
  }

  void dispose() {
    print('🗑️ Disposing socket service');
    offAll();
    _joinedChatIds.clear();
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
