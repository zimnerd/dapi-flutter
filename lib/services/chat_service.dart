import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async'; // For StreamController

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/match.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import '../utils/exceptions.dart'; // Import custom exception
import '../config/app_config.dart';
import 'api_client.dart';
import 'auth_service.dart'; // Import AuthService

class ChatService {
  final Dio _dio;
  final AuthService _authService; // Store AuthService instance
  final ProviderRef _ref; // Store Ref for reading providers
  final Logger _logger = Logger('ChatService');
  
  IO.Socket? _socket;
  
  // Stream controllers for various events
  final StreamController<Message> _messageController = StreamController.broadcast();
  final StreamController<Map<String, bool>> _typingStatusController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _readReceiptController = StreamController.broadcast();
  final StreamController<Message> _groupMessageController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _onlineStatusController = StreamController.broadcast();
  final StreamController<List<dynamic>> _chatroomsController = StreamController.broadcast();
  final StreamController<Map<String, int>> _unreadCountsController = StreamController.broadcast();
  final StreamController<String> _errorController = StreamController.broadcast();
  
  // Expose streams
  Stream<Message> get messageStream => _messageController.stream;
  Stream<Map<String, bool>> get typingStatusStream => _typingStatusController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptController.stream;
  Stream<Message> get groupMessageStream => _groupMessageController.stream;
  Stream<Map<String, dynamic>> get onlineStatusStream => _onlineStatusController.stream;
  Stream<List<dynamic>> get chatroomsStream => _chatroomsController.stream;
  Stream<Map<String, int>> get unreadCountsStream => _unreadCountsController.stream;
  Stream<String> get errorStream => _errorController.stream;
  
  // Connection status
  bool get isConnected => _socket?.connected ?? false;
  
  // Store current typing status locally
  final Map<String, bool> _typingUsers = {};

  ChatService(this._dio, this._authService, this._ref);

  Future<void> initSocket() async {
    if (_socket != null && _socket!.connected) {
      _logger.info("Socket already connected.");
      return;
    }

    _logger.info("Initializing WebSocket connection...");
    final token = await _authService.getAccessToken();

    if (token == null) {
      _logger.error("Cannot initialize socket: No auth token found.");
      _errorController.add("Authentication required: No token found");
      return;
    }
    
    final socketUrl = AppConfig.socketUrl; // Use the getter from AppConfig
    _logger.info("Connecting to socket at: $socketUrl");

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'forceNew': true, // Ensures a new connection attempt
      'auth': {
        'token': token
      },
      'reconnection': true,
      'reconnectionAttempts': 5,
      'reconnectionDelay': 1000,
      'reconnectionDelayMax': 5000,
      'timeout': 20000,
    });

    _setupEventListeners();
    _setupReconnection();
    
    // Connect the socket
    _socket!.connect();
  }

  void _setupEventListeners() {
    // Connection events
    _socket!.onConnect((_) {
      _logger.info('Socket connected: ${_socket!.id}');
    });

    _socket!.onConnectError((data) {
      _logger.error('Socket connection error: $data');
      _errorController.add("Connection error: ${data.toString()}");
    });

    _socket!.onError((data) {
      _logger.error('Socket error: $data');
      _errorController.add("Socket error: ${data.toString()}");
    });

    _socket!.onDisconnect((_) {
      _logger.info('Socket disconnected');
    });

    // Private messaging events
    _socket!.on('new_message', (data) {
      _logger.chat('Received new message: $data');
      try {
        final String conversationId = data['conversation_id'] ?? 'unknown_conversation'; 
        final message = Message.fromJson(conversationId, data);
        _messageController.add(message);
      } catch (e) {
        _logger.error('Error parsing incoming message: $e\nData: $data');
      }
    });
    
    // Typing indicators
    _socket!.on('user_typing', (data) {
      _logger.chat('Received user_typing event: $data');
      if (data is Map && data.containsKey('senderId')) {
        final senderId = data['senderId'].toString();
        _typingUsers[senderId] = true;
        _typingStatusController.add(Map.unmodifiable(_typingUsers)); // Add immutable copy
      }
    });

    _socket!.on('user_stopped_typing', (data) {
      _logger.chat('Received user_stopped_typing event: $data');
      if (data is Map && data.containsKey('senderId')) {
        final senderId = data['senderId'].toString();
        _typingUsers[senderId] = false;
        _typingStatusController.add(Map.unmodifiable(_typingUsers)); // Add immutable copy
      }
    });
    
    // Read receipts
    _socket!.on('messages_read', (data) {
      _logger.chat('Received read receipt: $data');
      _readReceiptController.add(data);
    });
    
    // Group chat events
    _socket!.on('new_group_message', (data) {
      _logger.chat('Received group message: $data');
      try {
        final String roomId = data['room_id'] ?? 'unknown_room';
        final message = Message.fromJson(roomId, data);
        _groupMessageController.add(message);
      } catch (e) {
        _logger.error('Error parsing incoming group message: $e\nData: $data');
      }
    });
    
    _socket!.on('chatroom_created', (data) {
      _logger.chat('Chatroom created: $data');
    });
    
    _socket!.on('chatroom_joined', (data) {
      _logger.chat('Joined chatroom: $data');
    });
    
    _socket!.on('chatrooms_list', (data) {
      _logger.chat('Received chatrooms list');
      if (data is List) {
        _chatroomsController.add(data);
      }
    });
    
    // Presence/online status
    _socket!.on('user_presence_changed', (data) {
      _logger.chat('Received user presence change: $data');
      _onlineStatusController.add(data);
    });
    
    _socket!.on('user_online', (data) {
      _logger.chat('User online notification: $data');
      _onlineStatusController.add(data);
    });
    
    // Unread counts
    _socket!.on('unread_counts', (data) {
      _logger.chat('Received unread counts: $data');
      if (data is Map) {
        _unreadCountsController.add(Map<String, int>.from(data));
      }
    });
    
    // General events - log all events for debugging
    _socket!.onAny((event, data) {
      _logger.debug('⬇️ Socket event: $event, data: $data');
    });
  }
  
  void _setupReconnection() {
    _socket!.onReconnect((attempt) {
      _logger.info('Socket reconnected after $attempt attempts');
      // Re-authenticate after reconnection
      _authService.getAccessToken().then((token) {
        if (token != null) {
          _socket!.emit('authenticate', {'token': token});
        }
      });
    });
    
    _socket!.onReconnectAttempt((attempt) {
      _logger.info('Attempting to reconnect: attempt $attempt');
    });
    
    _socket!.onReconnectError((error) {
      _logger.error('Reconnection error: $error');
    });
    
    _socket!.onReconnectFailed((_) {
      _logger.error('Socket reconnection failed after maximum attempts');
      _errorController.add("Connection failed: Maximum reconnection attempts reached");
    });
  }

  // Private messaging
  void sendPrivateMessage(String recipientId, String text, {String? mediaUrl}) {
    if (_socket == null || !_socket!.connected) {
      _logger.warn("Socket not connected. Cannot send message.");
      _errorController.add("Cannot send message: disconnected");
      return;
    }
    
    _logger.chat("Sending private message via socket to $recipientId");
    final messageData = {
      'recipientId': recipientId,
      'message': text,
    };
    
    if (mediaUrl != null) {
      messageData['mediaUrl'] = mediaUrl;
    }
    
    _socket!.emit('private_message', messageData);
  }

  // Emit typing events
  void startTyping(String recipientId) {
    if (_socket == null || !_socket!.connected) return;
    _logger.chat("Emitting start_typing to $recipientId");
    _socket!.emit('start_typing', {'recipientId': recipientId});
  }

  void stopTyping(String recipientId) {
    if (_socket == null || !_socket!.connected) return;
    _logger.chat("Emitting stop_typing to $recipientId");
    _socket!.emit('stop_typing', {'recipientId': recipientId});
  }
  
  // Load conversation history
  void loadConversationHistory(String conversationId, {int limit = 50, String? before}) {
    if (_socket == null || !_socket!.connected) {
      _errorController.add("Cannot load messages: disconnected");
      return;
    }
    
    _logger.chat("Loading conversation history for: $conversationId");
    
    final requestData = {
      'conversationId': conversationId,
      'limit': limit,
    };
    
    if (before != null) {
      requestData['before'] = before;
    }
    
    _socket!.emit('load_conversation', requestData);
  }
  
  // Mark messages as read
  void markMessagesAsRead(List<String> messageIds, String conversationId) {
    if (_socket == null || !_socket!.connected) return;
    _logger.chat("Marking messages as read: $messageIds");
    _socket!.emit('mark_read', {
      'messageIds': messageIds,
      'conversationId': conversationId
    });
  }
  
  // Get unread message counts
  void getUnreadCounts() {
    if (_socket == null || !_socket!.connected) return;
    _logger.chat("Requesting unread message counts");
    _socket!.emit('get_unread_counts');
  }
  
  // Group chat methods
  void createChatroom(String name, List<String> memberIds) {
    if (_socket == null || !_socket!.connected) {
      _errorController.add("Cannot create chatroom: disconnected");
      return;
    }
    
    _logger.chat("Creating chatroom: $name with members: $memberIds");
    _socket!.emit('create_chatroom', {
      'name': name,
      'members': memberIds
    });
  }

  void joinChatroom(String roomId) {
    if (_socket == null || !_socket!.connected) return;
    _logger.chat("Joining chatroom: $roomId");
    _socket!.emit('join_chatroom', {'roomId': roomId});
  }

  void leaveChatroom(String roomId) {
    if (_socket == null || !_socket!.connected) return;
    _logger.chat("Leaving chatroom: $roomId");
    _socket!.emit('leave_chatroom', {'roomId': roomId});
  }

  void sendGroupMessage(String roomId, String text, {String? mediaUrl}) {
    if (_socket == null || !_socket!.connected) {
      _errorController.add("Cannot send group message: disconnected");
      return;
    }
    
    _logger.chat("Sending group message to room: $roomId");
    
    final messageData = {
      'roomId': roomId,
      'content': text,
    };
    
    if (mediaUrl != null) {
      messageData['mediaUrl'] = mediaUrl;
    }
    
    _socket!.emit('group_message', messageData);
  }

  void loadGroupMessages(String roomId, {int limit = 50, String? before}) {
    if (_socket == null || !_socket!.connected) {
      _errorController.add("Cannot load group messages: disconnected");
      return;
    }
    
    _logger.chat("Loading group messages for room: $roomId");
    
    final requestData = {
      'roomId': roomId,
      'limit': limit,
    };
    
    if (before != null) {
      requestData['before'] = before;
    }
    
    _socket!.emit('load_group_conversation', requestData);
  }
  
  // Get all chatrooms the user is a member of
  void getChatrooms() {
    if (_socket == null || !_socket!.connected) return;
    _logger.chat("Requesting user's chatrooms");
    _socket!.emit('get_chatrooms');
  }
  
  // Presence/online status
  void updatePresence(String status) {
    if (_socket == null || !_socket!.connected) return;
    // Valid statuses: 'online', 'away', 'busy', 'offline'
    _logger.chat("Updating presence status to: $status");
    _socket!.emit('update_presence', {'status': status});
  }

  // Force disconnect and reconnect (useful for handling token refresh)
  void reconnect() {
    _logger.info('Forcing socket reconnection');
    _socket?.disconnect();
    
    // Short delay before reconnecting
    Future.delayed(const Duration(milliseconds: 500), () {
      initSocket();
    });
  }

  // Dispose method
  void dispose() {
    _logger.info("Disposing ChatService and disconnecting socket.");
    _socket?.disconnect();
    _socket?.dispose();
    
    // Close all stream controllers
    _messageController.close();
    _typingStatusController.close();
    _readReceiptController.close();
    _groupMessageController.close();
    _onlineStatusController.close();
    _chatroomsController.close();
    _unreadCountsController.close();
    _errorController.close();
  }
  
  // --- Existing HTTP methods ---
  
  // Get matches list
  Future<List<Profile>> getMatches() async {
    _logger.chat('Getting matches...');
    try {
      final response = await _dio.get(AppEndpoints.matches);
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Profile.fromJson(json)).toList();
      } else {
        // Throw specific ApiException for non-200 status
        throw ApiException(
          response.data?['message'] ?? Constants.errorFailedToLoadMatches,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Get Matches Dio error: ${e.message}', e);
      _handleDioError(e); // Throws ApiException
      // The following line is unreachable but satisfies the compiler
      throw ApiException(Constants.errorUnknown);
    } catch (e, s) {
      _logger.error('Get Matches general error: $e', e, s);
      throw ApiException(Constants.errorFailedToLoadMatches);
    }
  }
  
  // Get conversations list
  Future<List<Conversation>> getConversations() async {
    _logger.chat('Getting conversations...');
    try {
      final response = await _dio.get(AppEndpoints.conversations);
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        // Throw specific ApiException for non-200 status
        throw ApiException(
          response.data?['message'] ?? Constants.errorFailedToLoadConversations,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Get Conversations Dio error: ${e.message}', e);
      _handleDioError(e); // Throws ApiException
      // The following line is unreachable but satisfies the compiler
      throw ApiException(Constants.errorUnknown);
    } catch (e, s) {
      _logger.error('Get Conversations general error: $e', e, s);
      throw ApiException(Constants.errorFailedToLoadConversations);
    }
  }
  
  // Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    _logger.chat('Getting messages for conversation $conversationId...');
    try {
      // Use correct endpoint - dynamically build it
      final endpoint = AppEndpoints.conversationMessages(conversationId);
      _logger.debug("Requesting messages from: ${AppConfig.apiBaseUrl}$endpoint");
      final response = await _dio.get(endpoint);
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        // Pass conversationId if needed by fromJson
        return data.map((json) => Message.fromJson(conversationId, json)).toList(); 
      } else {
        _logger.warn("Failed to load messages: Status ${response.statusCode}, Data: ${response.data}");
        // Throw specific ApiException for non-200 status
        throw ApiException(
          response.data?['message'] ?? Constants.errorFailedToLoadMessages,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Get Messages Dio error: ${e.message}', e);
      _handleDioError(e); // Throws ApiException
      // The following line is unreachable but satisfies the compiler
      throw ApiException(Constants.errorUnknown);
    } catch (e, s) {
      _logger.error('Get Messages general error: $e', e, s);
      throw ApiException(Constants.errorFailedToLoadMessages);
    }
  }
  
  // Send a message - THIS SHOULD NOW USE WEBSOCKETS
  Future<Message> sendMessage(String conversationId, String text) async {
     _logger.warn("sendMessage via HTTP is deprecated. Use sendPrivateMessage via WebSocket.");
     
     // We need the recipient's ID to send via WebSocket.
     // This requires fetching the conversation details first or having it available.
     // For now, let's throw an error or return a dummy message.
     
     // Placeholder: Fetch conversation to get recipientId - This is inefficient!
     // Better approach: Pass recipientId to this function or handle sending in UI 
     // after fetching conversation details.
     /*
     try {
       final conversation = await getConversationDetails(conversationId); // Assuming such a method exists
       final recipientId = conversation.participants.firstWhere((p) => p.id != _authService.getCurrentUserIdSync()).id; // Needs sync user ID access
       sendPrivateMessage(recipientId, text);
       // We can't easily return the Message object here as it's async via socket.
       // The UI should react to the messageStreamProvider instead.
       return Message(id: 'temp-${DateTime.now().millisecondsSinceEpoch}', conversationId: conversationId, senderId: 'me', text: text, timestamp: DateTime.now());
     } catch (e) {
       _logger.error("Error trying to send message via WebSocket fallback: $e");
       throw Exception("Failed to send message. WebSocket error.");
     }
     */
     throw UnimplementedError("Use sendPrivateMessage via WebSocket. Requires recipientId.");
  }
  
  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    _logger.chat('Marking conversation $conversationId as read...');
    try {
      // Use correct endpoint
      final response = await _dio.post('/api/conversations/$conversationId/read'); 
      
      if (response.statusCode != 200) {
         _logger.warn("Failed to mark conversation as read: Status ${response.statusCode}, Data: ${response.data}");
        // Don't throw, just log
      }
    } on DioException catch (e) {
      _logger.error('Mark Read Dio error: ${e.message}');
      // Not throwing here to prevent UI disruption over non-critical operation
    } catch (e) {
      _logger.error('Mark Read general error: $e');
      // Not throwing here to prevent UI disruption over non-critical operation
    }
  }
  
  // Create new conversation
  Future<Conversation> createConversation(String userId) async { // userId should be String
    _logger.chat('Creating conversation with user $userId...');
    try {
       // Use correct endpoint
      final response = await _dio.post(
        AppEndpoints.conversations, 
        data: {
          // Assuming backend expects 'userId' or 'recipientId'
          'recipientId': userId, 
        },
      );
      
      if (response.statusCode == 201 && response.data != null) {
         _logger.info("Conversation created successfully: ${response.data['id']}");
        return Conversation.fromJson(response.data);
      } else {
        _logger.warn("Failed to create conversation: Status ${response.statusCode}, Data: ${response.data}");
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to create conversation (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      _logger.error('Create Conversation Dio error: ${e.message}, Response: ${e.response?.data}');
      // Use _handleDioError for consistency
      _handleDioError(e); 
      rethrow; // Rethrow the ApiException
    } catch (e, s) {
      _logger.error('Create Conversation general error: $e', e, s); // Add stack trace
      throw ApiException(Constants.errorGeneric); // Throw generic ApiException
    }
  }
  
  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _logger.chat('Deleting conversation $conversationId...');
    try {
      // Use correct endpoint
      final response = await _dio.delete('/api/conversations/$conversationId'); 
      
      if (response.statusCode != 200 && response.statusCode != 204) {
         _logger.warn("Failed to delete conversation: Status ${response.statusCode}, Data: ${response.data}");
        // Throw specific ApiException for non-200 status
        throw ApiException(
          response.data?['message'] ?? 'Failed to delete conversation',
          statusCode: response.statusCode,
        );
      }
       _logger.info("Conversation $conversationId deleted successfully.");
    } on DioException catch (e) {
      _logger.error('Delete Conversation Dio error: ${e.message}, Response: ${e.response?.data}');
      // Use _handleDioError for consistency
      _handleDioError(e);
      rethrow; // Rethrow the ApiException
    } catch (e, s) {
      _logger.error('Delete Conversation general error: $e', e, s); // Add stack trace
      throw ApiException(Constants.errorGeneric); // Throw generic ApiException
    }
  }

  // Helper method to handle Dio errors and throw ApiException
  void _handleDioError(DioException e) {
    final String message;
    int? statusCode = e.response?.statusCode;

    // Prefer server message if available
    final serverMessage = e.response?.data?['message'];
    if (serverMessage != null && serverMessage is String && serverMessage.isNotEmpty) {
        message = serverMessage;
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = Constants.errorNetworkTimeout;
          break;
        case DioExceptionType.badResponse:
          switch (statusCode) {
            case 400:
              message = Constants.errorBadRequest;
              break;
            case 401:
              message = Constants.errorUnauthorized;
              break;
            case 403:
              message = Constants.errorForbidden;
              break;
            case 404:
              message = Constants.errorNotFound;
              break;
            case 429:
               message = Constants.errorRateLimit;
               break;
            case 500:
            case 502:
            case 503:
            case 504:
              message = Constants.errorServer;
              break;
            default:
              message = Constants.errorResponseFormat; // Or a more generic server error
          }
          break;
        case DioExceptionType.cancel:
          message = Constants.errorRequestCancelled;
          break;
        case DioExceptionType.connectionError:
           message = Constants.errorNetwork;
           break;
        case DioExceptionType.unknown:
        default:
          message = Constants.errorUnknown; // Or specific unknown error message
      }
    }

    _logger.error('API Error: ($statusCode) $message');
    throw ApiException(message, statusCode: statusCode);
  }
}

// Helper function or extension to get current user ID synchronously (if feasible)
// This is often difficult in Flutter due to async nature of storage.
// Consider managing user ID state globally via another provider if needed synchronously.
// String getCurrentUserIdSync(ProviderRef ref) {
//    // This is problematic, avoid if possible.
//    // Maybe read from a state provider that holds the user ID after login.
//    final userIdState = ref.read(userIdProvider); // Assuming a userIdProvider exists
//    return userIdState ?? 'unknown_user';
// } 