// lib/services/socket_service.dart
import 'dart:convert';
import 'package:Yempover_app/constants/api_constants.dart';
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
  bool _isConnected = false;

  // Connection status getter
  bool get isConnected => _socket?.connected ?? false;

  void init({required String token}) {
    _token = token;
    _connect();
  }

  void _connect() {
    if (_socket != null && _socket!.connected) return;

    print('🔌 Socket: Connecting to $_baseUrl');

    _socket = IO.io(
      _baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableForceNew()
          .setExtraHeaders({'Authorization': 'Bearer $_token'})
          .setQuery({'token': _token})
          .build(),
    );

    _setupListeners();
  }

  void _setupListeners() {
    _socket!.on('connect', (_) {
      print('✅ Socket connected: ${_socket!.id}');
      _isConnected = true;
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
      _notifyListeners('reconnect', attempt);
    });

    // Chat message events
    _socket!.on('new_message', (data) {
      print('📩 New message received: $data');
      _notifyListeners('new_message', data);
    });

    _socket!.on('message_sent', (data) {
      print('✅ Message sent confirmation: $data');
      _notifyListeners('message_sent', data);
    });

    // Offer events
    _socket!.on('offer_created', (data) {
      print('💰 Offer created: $data');
      _notifyListeners('offer_created', data);
    });

    _socket!.on('offer_accepted', (data) {
      print('✅ Offer accepted: $data');
      _notifyListeners('offer_accepted', data);
    });

    _socket!.on('offer_rejected', (data) {
      print('❌ Offer rejected: $data');
      _notifyListeners('offer_rejected', data);
    });

    _socket!.on('offer_withdrawn', (data) {
      print('↩️ Offer withdrawn: $data');
      _notifyListeners('offer_withdrawn', data);
    });

    // Chat status events
    _socket!.on('chat_updated', (data) {
      print('🔄 Chat updated: $data');
      _notifyListeners('chat_updated', data);
    });

    _socket!.on('messages_read', (data) {
      print('👁️ Messages read: $data');
      _notifyListeners('messages_read', data);
    });

    // Typing events
    _socket!.on('typing', (data) {
      print('✏️ Typing: $data');
      _notifyListeners('typing', data);
    });

    // Deal completion events
    _socket!.on('deal_completed', (data) {
      print('🎉 Deal completed: $data');
      _notifyListeners('deal_completed', data);
    });

    _socket!.on('deal_cancelled', (data) {
      print('🚫 Deal cancelled: $data');
      _notifyListeners('deal_cancelled', data);
    });

    // User presence
    _socket!.on('user_presence', (data) {
      print('🟢 User presence: $data');
      _notifyListeners('user_presence', data);
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
      _socket!.io.options?['extraHeaders'] = {
        'Authorization': 'Bearer $_token',
      };
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
    if (!_isConnected) {
      print('⚠️ Cannot join chat: Socket not connected');
      return;
    }

    print('🔗 Joining chat: $chatId');
    _socket?.emit('join_chat', {'chatId': chatId});
  }

  // Leave a chat room
  void leaveChat(String chatId) {
    print('🚪 Leaving chat: $chatId');
    _socket?.emit('leave_chat', {'chatId': chatId});
  }

  // Send a message
  void sendMessage(String chatId, Map<String, dynamic> message) {
    if (!_isConnected) {
      print('⚠️ Cannot send message: Socket not connected');
      return;
    }

    print('📤 Sending message to chat $chatId: $message');
    _socket?.emit('send_message', {
      'chatId': chatId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Send typing indicator
  void sendTyping(String chatId, bool isTyping) {
    if (!_isConnected) return;

    _socket?.emit('typing', {
      'chatId': chatId,
      'isTyping': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Mark messages as read
  void markMessagesRead(String chatId, List<String> messageIds) {
    if (!_isConnected) return;

    _socket?.emit('mark_read', {
      'chatId': chatId,
      'messageIds': messageIds,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Create an offer (emit event)
  void emitOfferCreated(String chatId, Map<String, dynamic> offerData) {
    if (!_isConnected) return;

    _socket?.emit('offer_created', {
      'chatId': chatId,
      'offer': offerData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Accept an offer (emit event)
  void emitOfferAccepted(String chatId, String offerId) {
    if (!_isConnected) return;

    _socket?.emit('offer_accepted', {
      'chatId': chatId,
      'offerId': offerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Reject an offer (emit event)
  void emitOfferRejected(String chatId, String offerId) {
    if (!_isConnected) return;

    _socket?.emit('offer_rejected', {
      'chatId': chatId,
      'offerId': offerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Withdraw an offer
  void emitOfferWithdrawn(String chatId, String offerId) {
    if (!_isConnected) return;

    _socket?.emit('offer_withdrawn', {
      'chatId': chatId,
      'offerId': offerId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Complete deal
  void emitDealCompleted(String chatId, Map<String, dynamic> dealData) {
    if (!_isConnected) return;

    _socket?.emit('deal_completed', {
      'chatId': chatId,
      'dealData': dealData,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Cancel deal
  void emitDealCancelled(String chatId) {
    if (!_isConnected) return;

    _socket?.emit('deal_cancelled', {
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
    _socket?.off('');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}

// // lib/services/socket_service.dart
// import 'dart:convert';
// import 'dart:io';
// import 'package:Yempover_app/constants/api_constants.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:http/http.dart' as http;

// class SocketService {
//   static final SocketService _instance = SocketService._internal();
//   factory SocketService() => _instance;
//   SocketService._internal();

//   IO.Socket? _socket;
//   String? _token;
//   // Extract base URL without '/api/mobile' for socket connection
//   late String _baseUrl;
//   final Map<String, List<Function(dynamic)>> _listeners = {};
//   bool _isConnected = false;

//   // Connection status getter
//   bool get isConnected => _socket?.connected ?? false;

//   void init({required String token}) {
//     _token = token;
//     // Remove '/api/mobile' from baseUrl for socket connection
//     _baseUrl = ApiConstants.baseUrl.replaceAll('/api/mobile', '');
//     print('🔌 Socket: Initializing with base URL: $_baseUrl');
//     _connect();
//   }

//   void _connect() {
//     if (_socket != null && _socket!.connected) return;

//     print('🔌 Socket: Connecting to $_baseUrl');

//     try {
//       _socket = IO.io(
//         _baseUrl,
//         IO.OptionBuilder()
//             .setTransports(['websocket']) // Use WebSocket only
//             .enableForceNew() // Force new connection
//             .setExtraHeaders({
//               'Authorization': 'Bearer $_token',
//               'Accept': 'application/json',
//             })
//             .setQuery({'token': _token}) // Add token as query param as well
//             .disableAutoConnect() // Disable auto connect to control manually
//             .build(),
//       );

//       _setupListeners();
//       _socket!.connect(); // Manually connect
//     } catch (e) {
//       print('❌ Socket: Error creating socket: $e');
//     }
//   }

//   void _setupListeners() {
//     _socket!.on('connect', (_) {
//       print('✅ Socket connected: ${_socket!.id}');
//       _isConnected = true;
//       _notifyListeners('connect', null);
//     });

//     _socket!.on('disconnect', (_) {
//       print('❌ Socket disconnected');
//       _isConnected = false;
//       _notifyListeners('disconnect', null);
//     });

//     _socket!.on('connect_error', (err) {
//       print('⚠️ Socket connection error: $err');
//       _isConnected = false;
//       _notifyListeners('connect_error', err);
//     });

//     _socket!.on('connect_timeout', (err) {
//       print('⏱️ Socket connection timeout: $err');
//       _isConnected = false;
//       _notifyListeners('connect_timeout', err);
//     });

//     _socket!.on('reconnect', (attempt) {
//       print('🔄 Socket reconnected after $attempt attempts');
//       _isConnected = true;
//       _notifyListeners('reconnect', attempt);
//     });

//     _socket!.on('reconnect_attempt', (attempt) {
//       print('🔄 Socket reconnect attempt: $attempt');
//     });

//     _socket!.on('reconnect_error', (err) {
//       print('⚠️ Socket reconnect error: $err');
//     });

//     _socket!.on('reconnect_failed', (err) {
//       print('❌ Socket reconnect failed: $err');
//     });

//     // Chat message events
//     _socket!.on('new_message', (data) {
//       print('📩 New message received: $data');
//       _notifyListeners('new_message', data);
//     });

//     _socket!.on('message_sent', (data) {
//       print('✅ Message sent confirmation: $data');
//       _notifyListeners('message_sent', data);
//     });

//     // Offer events
//     _socket!.on('offer_created', (data) {
//       print('💰 Offer created: $data');
//       _notifyListeners('offer_created', data);
//     });

//     _socket!.on('offer_accepted', (data) {
//       print('✅ Offer accepted: $data');
//       _notifyListeners('offer_accepted', data);
//     });

//     _socket!.on('offer_rejected', (data) {
//       print('❌ Offer rejected: $data');
//       _notifyListeners('offer_rejected', data);
//     });

//     _socket!.on('offer_withdrawn', (data) {
//       print('↩️ Offer withdrawn: $data');
//       _notifyListeners('offer_withdrawn', data);
//     });

//     // Chat status events
//     _socket!.on('chat_updated', (data) {
//       print('🔄 Chat updated: $data');
//       _notifyListeners('chat_updated', data);
//     });

//     _socket!.on('messages_read', (data) {
//       print('👁️ Messages read: $data');
//       _notifyListeners('messages_read', data);
//     });

//     // Typing events
//     _socket!.on('typing', (data) {
//       print('✏️ Typing: $data');
//       _notifyListeners('typing', data);
//     });

//     // Deal completion events
//     _socket!.on('deal_completed', (data) {
//       print('🎉 Deal completed: $data');
//       _notifyListeners('deal_completed', data);
//     });

//     _socket!.on('deal_cancelled', (data) {
//       print('🚫 Deal cancelled: $data');
//       _notifyListeners('deal_cancelled', data);
//     });

//     // User presence
//     _socket!.on('user_presence', (data) {
//       print('🟢 User presence: $data');
//       _notifyListeners('user_presence', data);
//     });

//     // Error handling
//     _socket!.on('error', (error) {
//       print('⚠️ Socket error: $error');
//       _notifyListeners('error', error);
//     });
//   }

//   void updateToken(String token) {
//     _token = token;
//     if (_socket != null) {
//       // Update headers
//       _socket!.io.options?['extraHeaders'] = {
//         'Authorization': 'Bearer $_token',
//       };

//       if (!_socket!.connected) {
//         _socket!.connect();
//       } else {
//         // Disconnect and reconnect with new token
//         print('🔄 Socket: Reconnecting with new token');
//         _socket!.disconnect();
//         _socket!.connect();
//       }
//     }
//   }

//   // Join a specific chat room
//   void joinChat(String chatId) {
//     if (!_isConnected) {
//       print('⚠️ Cannot join chat: Socket not connected');
//       return;
//     }

//     print('🔗 Joining chat: $chatId');
//     _socket?.emit('join_chat', {'chatId': chatId});
//   }

//   // Leave a chat room
//   void leaveChat(String chatId) {
//     print('🚪 Leaving chat: $chatId');
//     _socket?.emit('leave_chat', {'chatId': chatId});
//   }

//   // Send a message
//   void sendMessage(String chatId, Map<String, dynamic> message) {
//     if (!_isConnected) {
//       print('⚠️ Cannot send message: Socket not connected');
//       return;
//     }

//     print('📤 Sending message to chat $chatId');
//     _socket?.emit('send_message', {
//       'chatId': chatId,
//       'message': message,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Send typing indicator
//   void sendTyping(String chatId, bool isTyping) {
//     if (!_isConnected) return;

//     _socket?.emit('typing', {
//       'chatId': chatId,
//       'isTyping': isTyping,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Mark messages as read
//   void markMessagesRead(String chatId, List<String> messageIds) {
//     if (!_isConnected) return;

//     _socket?.emit('mark_read', {
//       'chatId': chatId,
//       'messageIds': messageIds,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Create an offer (emit event)
//   void emitOfferCreated(String chatId, Map<String, dynamic> offerData) {
//     if (!_isConnected) return;

//     _socket?.emit('offer_created', {
//       'chatId': chatId,
//       'offer': offerData,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Accept an offer (emit event)
//   void emitOfferAccepted(String chatId, String offerId) {
//     if (!_isConnected) return;

//     _socket?.emit('offer_accepted', {
//       'chatId': chatId,
//       'offerId': offerId,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Reject an offer (emit event)
//   void emitOfferRejected(String chatId, String offerId) {
//     if (!_isConnected) return;

//     _socket?.emit('offer_rejected', {
//       'chatId': chatId,
//       'offerId': offerId,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Withdraw an offer
//   void emitOfferWithdrawn(String chatId, String offerId) {
//     if (!_isConnected) return;

//     _socket?.emit('offer_withdrawn', {
//       'chatId': chatId,
//       'offerId': offerId,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Complete deal
//   void emitDealCompleted(String chatId, Map<String, dynamic> dealData) {
//     if (!_isConnected) return;

//     _socket?.emit('deal_completed', {
//       'chatId': chatId,
//       'dealData': dealData,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Cancel deal
//   void emitDealCancelled(String chatId) {
//     if (!_isConnected) return;

//     _socket?.emit('deal_cancelled', {
//       'chatId': chatId,
//       'timestamp': DateTime.now().toIso8601String(),
//     });
//   }

//   // Add event listener
//   void on(String event, Function(dynamic) callback) {
//     _listeners.putIfAbsent(event, () => []).add(callback);
//   }

//   // Remove event listener
//   void off(String event, [Function? callback]) {
//     if (callback == null) {
//       _listeners.remove(event);
//     } else {
//       _listeners[event]?.remove(callback);
//     }
//   }

//   // Remove all listeners
//   void offAll() {
//     _listeners.clear();
//   }

//   // Notify all listeners for an event
//   void _notifyListeners(String event, dynamic data) {
//     final listeners = _listeners[event];
//     if (listeners != null) {
//       for (var listener in listeners) {
//         try {
//           listener(data);
//         } catch (e) {
//           print('Error in listener for event $event: $e');
//         }
//       }
//     }
//   }

//   // Check connection status
//   void checkConnection() {
//     if (_socket != null) {
//       print('🔌 Socket connection status: ${_socket!.connected}');
//       print('🔌 Socket ID: ${_socket!.id}');
//     }
//   }

//   // Reconnect manually
//   void reconnect() {
//     print('🔄 Socket: Manual reconnect');
//     if (_socket != null) {
//       _socket!.disconnect();
//       _socket!.connect();
//     }
//   }

//   // Upload file via presigned URL
//   Future<String?> uploadFileViaPresigned(
//     String presignApiPath,
//     File file,
//     String contentType, {
//     Map<String, String>? headers,
//   }) async {
//     try {
//       // Get presigned URL from your API
//       final presignUrl = await _getPresignedUrl(presignApiPath);
//       if (presignUrl == null) return null;

//       // Read file bytes
//       final bytes = await file.readAsBytes();

//       // Upload to presigned URL
//       final putResp = await http.put(
//         Uri.parse(presignUrl),
//         headers: {'Content-Type': contentType, ...?headers},
//         body: bytes,
//       );

//       if (putResp.statusCode == 200 || putResp.statusCode == 204) {
//         // Return the accessible URL (extract from presigned URL or your API response)
//         return presignUrl.split('?').first;
//       }

//       print('❌ Upload failed with status: ${putResp.statusCode}');
//       return null;
//     } catch (e) {
//       print('❌ Upload error: $e');
//       return null;
//     }
//   }

//   Future<String?> _getPresignedUrl(String apiPath) async {
//     try {
//       // Use full API URL
//       final fullUrl = '${ApiConstants.baseUrl}$apiPath';
//       print('🔗 Getting presigned URL from: $fullUrl');

//       final response = await http.get(
//         Uri.parse(fullUrl),
//         headers: {
//           'Authorization': 'Bearer $_token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         return data['presignedUrl'] ?? data['url'];
//       }

//       print('❌ Failed to get presigned URL: ${response.statusCode}');
//       return null;
//     } catch (e) {
//       print('❌ Error getting presigned URL: $e');
//       return null;
//     }
//   }

//   void dispose() {
//     print('🗑️ Disposing socket service');
//     offAll();
//     if (_socket != null) {
//       _socket!.off('');
//       _socket!.disconnect();
//       _socket!.dispose();
//       _socket = null;
//     }
//     _isConnected = false;
//   }
// }
