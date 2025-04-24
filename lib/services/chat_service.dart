import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../utils/websocket_debug.dart'; // Import the debug utility

// Event models for WebSockets
class TypingEvent {
  final String userId;
  final String conversationId;
  final bool isTyping;

  TypingEvent(
      {required this.userId,
      required this.conversationId,
      required this.isTyping});
}

class ReadReceiptEvent {
  final String userId;
  final String conversationId;

  ReadReceiptEvent({required this.userId, required this.conversationId});
}

class OnlineStatusEvent {
  final String userId;
  final bool isOnline;

  OnlineStatusEvent({required this.userId, required this.isOnline});
}

/// ChatService handles all chat-related operations, including:
/// - WebSocket connection for real-time messaging
/// - Fetching conversations and messages
/// - Sending and receiving messages
/// - Typing indicators
/// - Read receipts
/// - Online status tracking
/// - Group chat functionality
class ChatService {
  // Singleton instance
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal() {
    // Initialize services and controllers
    try {
      // Initialize stream controllers (without initializing AuthService here)
      _messagesController = StreamController<Map<String, dynamic>>.broadcast();
      _typingController = StreamController<Map<String, dynamic>>.broadcast();
      _readReceiptController =
          StreamController<Map<String, dynamic>>.broadcast();
      _onlineStatusController =
          StreamController<Map<String, dynamic>>.broadcast();
      _errorController = StreamController<String>.broadcast();
      _groupMessagesController =
          StreamController<Map<String, dynamic>>.broadcast();
      _roomUpdatesController =
          StreamController<Map<String, dynamic>>.broadcast();

      // Initialize the WebSocket debug utility
      _debug = WebSocketDebug();
      _debug.logStatus('ChatService initialized');
    } catch (e) {
      print('Error initializing ChatService: $e');
    }
  }

  // Debug utility
  late WebSocketDebug _debug;

  // Socket instance
  IO.Socket? _socket;

  // Services
  AuthService? _authService;
  final Dio _dio = Dio();

  // Initialize the auth service
  void initializeAuthService(AuthService authService) {
    _authService = authService;
    print('AuthService initialized in ChatService');
  }

  // Stream controllers
  late StreamController<Map<String, dynamic>> _messagesController;
  late StreamController<Map<String, dynamic>> _typingController;
  late StreamController<Map<String, dynamic>> _readReceiptController;
  late StreamController<Map<String, dynamic>> _onlineStatusController;
  late StreamController<String> _errorController;
  late StreamController<Map<String, dynamic>> _groupMessagesController;
  late StreamController<Map<String, dynamic>> _roomUpdatesController;

  // Streams
  Stream<Map<String, dynamic>> get onNewMessage => _messagesController.stream;
  Stream<Map<String, dynamic>> get onTypingEvent => _typingController.stream;
  Stream<Map<String, dynamic>> get onReadReceipt =>
      _readReceiptController.stream;
  Stream<Map<String, dynamic>> get onOnlineStatus =>
      _onlineStatusController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<Map<String, dynamic>> get onGroupMessage =>
      _groupMessagesController.stream;
  Stream<Map<String, dynamic>> get onRoomUpdate =>
      _roomUpdatesController.stream;

  // Socket connection status
  bool get isConnected => _socket?.connected ?? false;

  /// Initialize the WebSocket connection
  Future<void> initSocket() async {
    if (_authService == null) {
      print('AuthService not initialized. Call initializeAuthService() first.');
      _errorController
          .add('Authentication service not available. Please restart the app.');
      _debug.logError('AuthService not initialized');
      return;
    }

    try {
      final token = await _authService!.getAccessToken();
      print(
          '🔐 Auth token for WebSocket: ${token != null ? "Found (${token.substring(0, 10)}...)" : "NOT FOUND!"}');
      _debug.logStatus('Auth token: ${token != null ? "Found" : "NOT FOUND"}');

      if (token == null) {
        print(
            '❌ Failed to initialize socket: No authentication token available');
        _errorController
            .add('No authentication token available. Please log in again.');
        _debug.logError('No authentication token available');
        return;
      }

      // Create socket connection with Socket.IO client
      print('🔌 Initializing socket connection to ${AppConfig.socketUrl}');
      _debug.logStatus(
          'Initializing socket connection to ${AppConfig.socketUrl}');

      // Directly use HTTP URL format for WebSocket connection
      // Force using the non-localhost URL for actual device usage
      String socketUrl = 'https://dapi.pulsetek.co.za:3000';
      print('🔌 Using socket URL: $socketUrl');
      _debug.logStatus('Using socket URL: $socketUrl');

      // Close existing socket if it exists
      if (_socket != null) {
        print('🔄 Closing existing socket connection before creating new one');
        _debug.logStatus('Closing existing socket connection');
        _socket!.disconnect();
        _socket!.dispose();
        _socket = null;
      }

      // Create new socket with multiple authentication methods
      _socket = IO.io(
        socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect() // Disable auto-connect to control connection timing
            .enableReconnection()
            // Try multiple authentication methods to ensure one works
            .setQuery({'token': token, 'auth_token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .build(),
      );

      // Set up event listeners
      _setupSocketListeners();
      print('🔐 WebSocket initialized with token - connecting manually');
      _debug
          .logStatus('WebSocket initialized with token - connecting manually');

      // Manually connect the socket
      _socket!.connect();
    } catch (e) {
      print('❌ Error initializing WebSocket: $e');
      _errorController.add('Failed to initialize chat connection: $e');
      _debug.logError('Error initializing WebSocket: $e');
    }
  }

  // Helper method to get auth token
  Future<String?> _getAuthToken() async {
    try {
      // Use FlutterSecureStorage instead of SharedPreferences
      final storage = FlutterSecureStorage();
      final token = await storage.read(key: AppStorageKeys.accessToken);
      print(
          'Retrieved auth token from secure storage: ${token != null ? 'token found' : 'token not found'}');
      return token;
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  /// Connect to the WebSocket server
  void connect() {
    if (_socket == null) {
      print('Socket not initialized. Call initSocket() first.');
      return;
    }

    if (!_socket!.connected) {
      _socket!.connect();
      print('Connecting to WebSocket server...');
    } else {
      print('Already connected to WebSocket server');
    }
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _socket?.disconnect();
    print('Disconnected from WebSocket server');
  }

  /// Set up all socket event listeners
  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('✅ Connected to WebSocket server successfully');
      _debug.logStatus('Connected to WebSocket server successfully');
    });

    _socket?.onDisconnect((reason) {
      print('🔌 Disconnected from WebSocket server. Reason: $reason');
      _debug.logStatus('Disconnected from WebSocket server. Reason: $reason');
    });

    _socket?.onConnectError((error) {
      print('❌ Connection error: $error');
      print(
          '📋 Connection details: URL=${AppConfig.socketUrl}, Transport=${_socket?.io.engine?.transport?.name}');
      _errorController
          .add('Connection error: Unable to connect to chat server');
      _debug.logError('Connection error: $error');
    });

    _socket?.onError((error) {
      print('❌ Socket error: $error');
      _errorController.add('Chat service error: Please try again later');
      _debug.logError('Socket error: $error');
    });

    // Message events
    _socket?.on('private_message', (data) {
      print('📩 Received private message: ${data.toString()}');
      _debug.logReceivedMessage({'event': 'private_message', 'data': data});

      // Add better debugging and parsing for conversation ID
      String conversationId = data['conversationId'] ?? '';

      // If the server sends a different format, try to normalize it
      if (conversationId.isEmpty && data['matchId'] != null) {
        conversationId = data['matchId'];
      }

      // Log the received conversation ID
      print('📋 DEBUG: Received message for conversationId: $conversationId');
      _debug.logStatus('Received message for conversationId: $conversationId');

      _messagesController.add(data);
    });

    // Add listeners for the server's response events
    _socket?.on('new_message', (data) {
      print('📩 Received new message: ${data.toString()}');
      _debug.logReceivedMessage({'event': 'new_message', 'data': data});

      final messageData = {
        'id': data['id'] ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
        'conversationId': data['match_id'] ?? '',
        'senderId': data['sender_id'] ?? '',
        'text': data['content'] ?? '',
        'timestamp': data['sent_at'] ?? DateTime.now().toIso8601String(),
        'status': 'sent'
      };

      _messagesController.add(messageData);
    });

    _socket?.on('message_sent', (data) {
      print('📩 Message sent confirmation: ${data.toString()}');
      _debug.logReceivedMessage({'event': 'message_sent', 'data': data});

      final messageData = {
        'id': data['id'] ?? 'msg-${DateTime.now().millisecondsSinceEpoch}',
        'conversationId': data['match_id'] ?? '',
        'senderId': data['sender_id'] ?? '',
        'text': data['content'] ?? '',
        'timestamp': data['sent_at'] ?? DateTime.now().toIso8601String(),
        'status': 'sent'
      };

      _messagesController.add(messageData);
    });

    _socket?.on('typing', (data) {
      print('⌨️ Typing indicator received: ${data.toString()}');
      _typingController.add(data);
    });

    _socket?.on('read_receipt', (data) {
      print('👁️ Read receipt received: ${data.toString()}');
      _readReceiptController.add(data);
    });

    _socket?.on('status_change', (data) {
      print('🟢 Online status update received: ${data.toString()}');
      _onlineStatusController.add(data);
    });

    // Group chat events
    _socket?.on('group_message', (data) {
      print('👥 Received group message: ${data.toString()}');
      _groupMessagesController.add(data);
    });

    _socket?.on('room_update', (data) {
      print('🔄 Room update received: ${data.toString()}');
      _roomUpdatesController.add(data);
    });
  }

  /// Send a private message to another user via WebSocket
  void sendPrivateMessage(String recipientId, String message,
      {String? mediaUrl}) {
    if (!isConnected) {
      print('Not connected to WebSocket server');
      _errorController.add('Not connected to chat server. Please try again.');
      _debug.logError('Not connected to WebSocket server');
      return;
    }

    // Create a match ID for the conversation, but prevent duplication of 'conv_with_' prefix
    final matchId = recipientId.startsWith('conv_with_')
        ? recipientId
        : 'conv_with_$recipientId';

    print(
        '📋 DEBUG: Using matchId: $matchId (original recipientId: $recipientId)');
    _debug.logStatus(
        'Using matchId: $matchId (original recipientId: $recipientId)');

    // Prepare message data in the format expected by the server
    final messageData = {
      'matchId': matchId, // The server expects matchId
      'content': message, // The server expects content
      'mediaUrl': mediaUrl, // This matches the server format
    };

    // Also include original format for backward compatibility
    final backupMessageData = {
      'receiverId': recipientId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };

    // Log the message we're about to send
    _debug.logSentMessage({'event': 'send_message', 'data': messageData});

    // Try both event names since we're not sure which one the server expects
    _socket?.emit('send_message', messageData);

    // Also emit with the original format for compatibility
    _socket?.emit('private_message', backupMessageData);
    _debug.logSentMessage(
        {'event': 'private_message', 'data': backupMessageData});

    print('Sent private message to $matchId');

    // Get the current user ID if available
    String currentUserId = 'currentUserId';
    try {
      // Try to get user ID from auth service
      if (_authService != null) {
        // The method to get user ID will depend on how your AuthService is implemented
        // This is a safe fallback approach
        currentUserId = 'user-${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      print('Error getting current user ID: $e');
    }

    // Emit a local message to our own stream for immediate UI update
    // This ensures the UI updates even if the server doesn't send confirmation
    final localMessage = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'conversationId': matchId,
      'senderId': currentUserId, // Use the retrieved user ID
      'text': message,
      'timestamp': DateTime.now().toIso8601String(),
      'status': 'sending'
    };

    _messagesController.add(localMessage);
    _debug.logStatus('Added local message to UI: ${localMessage['id']}');
  }

  /// Send a message to a group chat
  void sendGroupMessage(String roomId, String message, {String? mediaUrl}) {
    if (!isConnected) {
      print('Not connected to WebSocket server');
      _errorController.add('Not connected to chat server. Please try again.');
      return;
    }

    final messageData = {
      'roomId': roomId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      if (mediaUrl != null) 'mediaUrl': mediaUrl,
    };

    _socket?.emit('group_message', messageData);
    print('Sent group message to room $roomId');
  }

  /// Notify when user starts typing
  void startTyping(String receiverId) {
    if (!isConnected) return;

    _socket?.emit('typing', {
      'receiverId': receiverId,
      'isTyping': true,
    });
    print('Sent typing indicator to $receiverId');
  }

  /// Notify when user stops typing
  void stopTyping(String receiverId) {
    if (!isConnected) return;

    _socket?.emit('typing', {
      'receiverId': receiverId,
      'isTyping': false,
    });
    print('Sent stop typing indicator to $receiverId');
  }

  /// Send read receipt for messages
  void sendReadReceipt(String conversationId, String messageId) {
    if (!isConnected) return;

    _socket?.emit('read_receipt', {
      'conversationId': conversationId,
      'messageId': messageId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    print('Sent read receipt for message $messageId');
  }

  /// Update online status
  void updateOnlineStatus(bool isOnline) {
    if (!isConnected) return;

    _socket?.emit('status_change', {
      'isOnline': isOnline,
      'lastSeen': DateTime.now().toIso8601String(),
    });
    print('Updated online status: $isOnline');
  }

  /// Create a new chat room for group conversations
  void createChatRoom(String roomName, List<String> memberIds) {
    if (!isConnected) return;

    _socket?.emit('create_room', {
      'roomName': roomName,
      'members': memberIds,
    });
    print('Created new chat room: $roomName');
  }

  /// Join an existing chat room
  void joinChatRoom(String roomId) {
    if (!isConnected) return;

    _socket?.emit('join_room', {
      'roomId': roomId,
    });
    print('Joined chat room: $roomId');
  }

  /// Leave a chat room
  void leaveChatRoom(String roomId) {
    if (!isConnected) return;

    _socket?.emit('leave_room', {
      'roomId': roomId,
    });
    print('Left chat room: $roomId');
  }

  /// Get list of all conversations via HTTP (fallback method)
  Future<List<dynamic>> getConversations() async {
    return _getConversationsHttp();
  }

  /// Get messages for a specific conversation via HTTP (fallback method)
  Future<List<dynamic>> getMessages(String conversationId) async {
    return _getMessagesHttp(conversationId);
  }

  /// Mark a conversation as read via HTTP (fallback method)
  Future<bool> markConversationAsRead(String conversationId) async {
    return _markConversationAsReadHttp(conversationId);
  }

  /// Private method to fetch conversations via HTTP
  Future<List<dynamic>> _getConversationsHttp() async {
    try {
      if (_authService == null) {
        print('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService!.getAccessToken();

      if (token == null) {
        print(
            'Failed to fetch conversations: No authentication token available');
        throw Exception('Authentication token not available');
      }

      // Configure Dio properly with base URL and timeout
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ));

      print(
          'Fetching conversations from: ${AppConfig.apiBaseUrl}${AppEndpoints.conversations}');
      final response = await dio.get(AppEndpoints.conversations);

      if (response.statusCode == 200) {
        // Debug the response format to help identify structure
        print('Response data structure: ${response.data.runtimeType}');
        print(
            'Response keys: ${response.data is Map ? (response.data as Map).keys.toList() : "Not a map"}');

        // Extract and validate conversations data
        dynamic conversationsData;

        if (response.data is Map && response.data.containsKey('data')) {
          // Standard API format with data field
          conversationsData = response.data['data'];
          print(
              'Found data field in response with type: ${conversationsData.runtimeType}');
        } else if (response.data is List) {
          // Direct list format
          conversationsData = response.data;
          print(
              'Response is direct list with length: ${conversationsData.length}');
        } else {
          // Unknown format
          print('Unknown response format: ${response.data}');
          conversationsData = [];
        }

        // Ensure conversations is a List<dynamic>
        List<dynamic> conversations = [];

        if (conversationsData is List) {
          conversations = conversationsData;
        } else {
          print('Conversations data is not a list: $conversationsData');
        }

        print('Successfully processed ${conversations.length} conversations');

        // Transform to expected format if needed
        return conversations
            .map((conv) {
              try {
                // Just return the original data for now, will be processed by Conversation.fromJson
                return conv;
              } catch (e) {
                print('Error processing conversation: $e');
                return null;
              }
            })
            .where((conv) => conv != null)
            .toList();
      } else {
        print('Error fetching conversations: ${response.statusCode}');
        throw Exception(
            'Failed to fetch conversations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching conversations: $e');
      rethrow;
    }
  }

  /// Private method to fetch messages via HTTP
  Future<List<dynamic>> _getMessagesHttp(String conversationId) async {
    try {
      if (_authService == null) {
        print('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService!.getAccessToken();

      if (token == null) {
        print('Failed to fetch messages: No authentication token available');
        throw Exception('Authentication token not available');
      }

      // Configure Dio properly with base URL and timeout
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ));

      final endpoint = AppEndpoints.conversationMessages(conversationId);
      print('Fetching messages from: ${AppConfig.apiBaseUrl}$endpoint');

      final response = await dio.get(endpoint);

      if (response.statusCode == 200) {
        // More robust handling of response data
        try {
          // Debug the response structure
          print('Response data type: ${response.data.runtimeType}');

          List<dynamic> messages = [];

          // Handle different response formats
          if (response.data is Map) {
            if (response.data.containsKey('data') &&
                response.data['data'] is List) {
              messages = response.data['data'];
              print(
                  'Successfully fetched ${messages.length} messages from data field');
            } else {
              // Try to extract messages from other fields or use the entire response
              print(
                  'No data field found in response, checking other possibilities');

              // If response contains a "messages" field
              if (response.data.containsKey('messages') &&
                  response.data['messages'] is List) {
                messages = response.data['messages'];
                print('Found ${messages.length} messages in messages field');
              } else {
                // As a fallback, create an empty list
                print('No recognizable message format found, using empty list');
                messages = [];
              }
            }
          } else if (response.data is List) {
            messages = response.data;
            print('Response is directly a list of ${messages.length} messages');
          } else {
            print('Unknown response format: ${response.data}');
            messages = [];
          }

          // Convert to a safe format with required fields to prevent parsing errors later
          return messages
              .map((item) {
                if (item is! Map) {
                  print('Skipping non-Map message item: $item');
                  return null;
                }

                // Create a standardized message format with defaults for missing fields
                return {
                  'id': item['id'] ??
                      'msg-${DateTime.now().millisecondsSinceEpoch}',
                  'conversationId': item['conversationId'] ?? conversationId,
                  'senderId':
                      item['senderId'] ?? item['sender_id'] ?? 'unknown',
                  'text':
                      item['text'] ?? item['content'] ?? item['message'] ?? '',
                  'timestamp': item['timestamp'] ??
                      item['created_at'] ??
                      DateTime.now().toIso8601String(),
                  'status': item['status'] ?? 'sent'
                };
              })
              .where((item) => item != null)
              .toList();
        } catch (parseError) {
          print('Error parsing message response: $parseError');
          print('Response was: ${response.data}');

          // Return empty list rather than throwing to prevent app crashes
          return [];
        }
      } else {
        print('Error fetching messages: ${response.statusCode}');
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');

      // For common network errors, provide a more graceful failure
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          print('Network timeout, returning empty message list');
          return [];
        }
      }

      rethrow;
    }
  }

  /// Private method to mark conversation as read via HTTP
  Future<bool> _markConversationAsReadHttp(String conversationId) async {
    try {
      if (_authService == null) {
        print('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService!.getAccessToken();

      if (token == null) {
        print(
            'Failed to mark conversation as read: No authentication token available');
        throw Exception('Authentication token not available');
      }

      // Configure Dio properly with base URL and timeout
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ));

      print('Marking conversation as read: $conversationId/read');
      final response =
          await dio.post('${AppEndpoints.conversations}/$conversationId/read');

      return response.statusCode == 200;
    } catch (e) {
      print('Error marking conversation as read: $e');
      return false;
    }
  }

  /// Create a new conversation
  Future<dynamic> createConversation(String recipientId) async {
    try {
      if (_authService == null) {
        print('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService!.getAccessToken();

      if (token == null) {
        print(
            'Failed to create conversation: No authentication token available');
        throw Exception('Authentication token not available');
      }

      // Configure Dio properly with base URL and timeout
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ));

      print('Creating conversation with recipient: $recipientId');
      final response = await dio.post(
        AppEndpoints.conversations,
        data: {'recipient_id': recipientId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Conversation created successfully');
        return response.data['data'];
      } else {
        print('Error creating conversation: ${response.statusCode}');
        throw Exception(
            'Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      if (_authService == null) {
        print('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService!.getAccessToken();

      if (token == null) {
        print(
            'Failed to delete conversation: No authentication token available');
        throw Exception('Authentication token not available');
      }

      // Configure Dio properly with base URL and timeout
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConfig.networkTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ));

      print('Deleting conversation: $conversationId');
      final response =
          await dio.delete('${AppEndpoints.conversations}/$conversationId');

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting conversation: $e');
      return false;
    }
  }

  /// Handle Dio errors and log appropriately
  void _handleDioError(dynamic error, String context) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        print('$context: Connection timeout');
      } else if (error.type == DioExceptionType.badResponse) {
        final int? statusCode = error.response?.statusCode;
        final dynamic data = error.response?.data;
        print(
            '$context: Bad response (${statusCode ?? "unknown status"}): $data');
      } else {
        print('$context: ${error.message}');
      }
    } else {
      print('$context: $error');
    }
  }

  // Clean up resources
  void dispose() {
    disconnect();
    _messagesController.close();
    _typingController.close();
    _readReceiptController.close();
    _onlineStatusController.close();
    _errorController.close();
    _groupMessagesController.close();
    _roomUpdatesController.close();
  }
}
