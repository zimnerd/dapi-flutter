import 'dart:async';
import 'package:dio/dio.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../utils/websocket_debug.dart'; // Import the debug utility

final Logger _logger = Logger('ChatService');

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
      _logger.error('Error initializing ChatService: $e');
    }
  }

  // Debug utility
  late WebSocketDebug _debug;

  // Socket instance
  io.Socket? _socket;

  // Services
  late final AuthService _authService;

  // Initialize the auth service
  void initializeAuthService(AuthService authService) {
    _authService = authService;
    _logger.info('AuthService initialized in ChatService');
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
      _logger.error(
          'AuthService not initialized. Call initializeAuthService() first.');
      _errorController
          .add('Authentication service not available. Please restart the app.');
      _debug.logError('AuthService not initialized');
      return;
    }

    try {
      final token = await _authService.getAccessToken();
      _logger.info(
          '🔐 Auth token for WebSocket: ${token != null ? "Found (${token.substring(0, 10)}...)" : "NOT FOUND!"}');
      _debug.logStatus('Auth token: ${token != null ? "Found" : "NOT FOUND"}');

      if (token == null) {
        _logger.error(
            '❌ Failed to initialize socket: No authentication token available');
        _errorController
            .add('No authentication token available. Please log in again.');
        _debug.logError('No authentication token available');
        return;
      }

      // Create socket connection with Socket.IO client
      _logger
          .info('🔌 Initializing socket connection to ${AppConfig.socketUrl}');
      _debug.logStatus(
          'Initializing socket connection to ${AppConfig.socketUrl}');

      // Directly use HTTP URL format for WebSocket connection
      // Force using the non-localhost URL for actual device usage
      String socketUrl = 'https://dapi.pulsetek.co.za:3000';
      _logger.info('🔌 Using socket URL: $socketUrl');
      _debug.logStatus('Using socket URL: $socketUrl');

      // Close existing socket if it exists
      if (_socket != null) {
        _logger.info(
            '🔄 Closing existing socket connection before creating new one');
        _debug.logStatus('Closing existing socket connection');
        _socket?.disconnect();
        _socket?.dispose();
        _socket = null;
      }

      // Create new socket with multiple authentication methods
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
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
      _logger.info('🔐 WebSocket initialized with token - connecting manually');
      _debug
          .logStatus('WebSocket initialized with token - connecting manually');

      // Manually connect the socket
      _socket?.connect();
    } catch (e) {
      _logger.error('❌ Error initializing WebSocket: $e');
      _errorController.add('Failed to initialize chat connection: $e');
      _debug.logError('Error initializing WebSocket: $e');
    }
  }

  /// Connect to the WebSocket server
  void connect() {
    if (_socket == null) {
      _logger.error('Socket not initialized. Call initSocket() first.');
      return;
    }

    if (!_socket!.connected) {
      _socket!.connect();
      _logger.info('Connecting to WebSocket server...');
    } else {
      _logger.info('Already connected to WebSocket server');
    }
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _socket?.disconnect();
    _logger.info('Disconnected from WebSocket server');
  }

  /// Set up all socket event listeners
  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      _logger.info('✅ Connected to WebSocket server successfully');
      _debug.logStatus('Connected to WebSocket server successfully');
    });

    _socket?.onDisconnect((reason) {
      _logger.info('🔌 Disconnected from WebSocket server. Reason: $reason');
      _debug.logStatus('Disconnected from WebSocket server. Reason: $reason');
    });

    _socket?.onConnectError((error) {
      _logger.error('❌ Connection error: $error');
      _logger.info(
          '📋 Connection details: URL=${AppConfig.socketUrl}, Transport=${_socket?.io.engine?.transport?.name}');
      _errorController
          .add('Connection error: Unable to connect to chat server');
      _debug.logError('Connection error: $error');
    });

    _socket?.onError((error) {
      _logger.error('❌ Socket error: $error');
      _errorController.add('Chat service error: Please try again later');
      _debug.logError('Socket error: $error');
    });

    // Message events
    _socket?.on('private_message', (data) {
      _logger.info('📩 Received private message: ${data.toString()}');
      _debug.logReceivedMessage({'event': 'private_message', 'data': data});

      // Add better debugging and parsing for conversation ID
      String conversationId = data['conversationId'] ?? '';

      // If the server sends a different format, try to normalize it
      if (conversationId.isEmpty && data['matchId'] != null) {
        conversationId = data['matchId'];
      }

      // Log the received conversation ID
      _logger.info(
          '📋 DEBUG: Received message for conversationId: $conversationId');
      _debug.logStatus('Received message for conversationId: $conversationId');

      _messagesController.add(data);
    });

    // Add listeners for the server's response events
    _socket?.on('new_message', (data) {
      _logger.info('📩 Received new message: ${data.toString()}');
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
      _logger.info('📩 Message sent confirmation: ${data.toString()}');
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
      _logger.info('⌨️ Typing indicator received: ${data.toString()}');
      _typingController.add(data);
    });

    _socket?.on('read_receipt', (data) {
      _logger.info('👁️ Read receipt received: ${data.toString()}');
      _readReceiptController.add(data);
    });

    _socket?.on('status_change', (data) {
      _logger.info('🟢 Online status update received: ${data.toString()}');
      _onlineStatusController.add(data);
    });

    // Group chat events
    _socket?.on('group_message', (data) {
      _logger.info('👥 Received group message: ${data.toString()}');
      _groupMessagesController.add(data);
    });

    _socket?.on('room_update', (data) {
      _logger.info('🔄 Room update received: ${data.toString()}');
      _roomUpdatesController.add(data);
    });
  }

  /// Send a private message to another user via WebSocket
  void sendPrivateMessage(String recipientId, String message,
      {String? mediaUrl}) {
    if (!isConnected) {
      _logger.error('Not connected to WebSocket server');
      _errorController.add('Not connected to chat server. Please try again.');
      _debug.logError('Not connected to WebSocket server');
      return;
    }

    // Create a match ID for the conversation, but prevent duplication of 'conv_with_' prefix
    final matchId = recipientId.startsWith('conv_with_')
        ? recipientId
        : 'conv_with_$recipientId';

    _logger.info(
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

    _logger.info('Sent private message to $matchId');

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
      _logger.error('Error getting current user ID: $e');
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
      _logger.error('Not connected to WebSocket server');
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
    _logger.info('Sent group message to room $roomId');
  }

  /// Notify when user starts typing
  void startTyping(String receiverId) {
    if (!isConnected) return;

    _socket?.emit('typing', {
      'receiverId': receiverId,
      'isTyping': true,
    });
    _logger.info('Sent typing indicator to $receiverId');
  }

  /// Notify when user stops typing
  void stopTyping(String receiverId) {
    if (!isConnected) return;

    _socket?.emit('typing', {
      'receiverId': receiverId,
      'isTyping': false,
    });
    _logger.info('Sent stop typing indicator to $receiverId');
  }

  /// Send read receipt for messages
  void sendReadReceipt(String conversationId, String messageId) {
    if (!isConnected) return;

    _socket?.emit('read_receipt', {
      'conversationId': conversationId,
      'messageId': messageId,
      'timestamp': DateTime.now().toIso8601String(),
    });
    _logger.info('Sent read receipt for message $messageId');
  }

  /// Update online status
  void updateOnlineStatus(bool isOnline) {
    if (!isConnected) return;

    _socket?.emit('status_change', {
      'isOnline': isOnline,
      'lastSeen': DateTime.now().toIso8601String(),
    });
    _logger.info('Updated online status: $isOnline');
  }

  /// Create a new chat room for group conversations
  void createChatRoom(String roomName, List<String> memberIds) {
    if (!isConnected) return;

    _socket?.emit('create_room', {
      'roomName': roomName,
      'members': memberIds,
    });
    _logger.info('Created new chat room: $roomName');
  }

  /// Join an existing chat room
  void joinChatRoom(String roomId) {
    if (!isConnected) return;

    _socket?.emit('join_room', {
      'roomId': roomId,
    });
    _logger.info('Joined chat room: $roomId');
  }

  /// Leave a chat room
  void leaveChatRoom(String roomId) {
    if (!isConnected) return;

    _socket?.emit('leave_room', {
      'roomId': roomId,
    });
    _logger.info('Left chat room: $roomId');
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
        _logger.error('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService.getAccessToken();

      if (token == null) {
        _logger.error(
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

      _logger.info(
          'Fetching conversations from: ${AppConfig.apiBaseUrl}${AppEndpoints.conversations}');
      final response = await dio.get(AppEndpoints.conversations);

      if (response.statusCode == 200) {
        // Debug the response format to help identify structure
        _logger.info('Response data structure: ${response.data.runtimeType}');
        _logger.info(
            'Response keys: ${response.data is Map ? (response.data as Map).keys.toList() : "Not a map"}');

        // Extract and validate conversations data
        dynamic conversationsData;

        if (response.data is Map && response.data.containsKey('data')) {
          // Standard API format with data field
          conversationsData = response.data['data'];
          _logger.info(
              'Found data field in response with type: ${conversationsData.runtimeType}');
        } else if (response.data is List) {
          // Direct list format
          conversationsData = response.data;
          _logger.info(
              'Response is direct list with length: [33m[1m${conversationsData.length}[0m');
        } else {
          _logger
              .error('Unknown response format: [33m[1m${response.data}[0m');
          conversationsData = [];
        }

        // Ensure conversations is a List<dynamic>
        List<dynamic> conversations = [];

        if (conversationsData is List) {
          conversations = conversationsData;
        } else {
          _logger.error(
              'Conversations data is not a list: [33m[1m$conversationsData[0m');
        }

        _logger.info(
            'Successfully processed [33m[1m${conversations.length}[0m conversations');

        // Transform to expected format if needed
        return conversations
            .map((conv) {
              try {
                // Just return the original data for now, will be processed by Conversation.fromJson
                return conv;
              } catch (e) {
                _logger.error('Error processing conversation: $e');
                return null;
              }
            })
            .where((conv) => conv != null)
            .toList();
      } else {
        _logger.error('Error fetching conversations: ${response.statusCode}');
        throw Exception(
            'Failed to fetch conversations: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error fetching conversations: $e');
      rethrow;
    }
  }

  /// Private method to fetch messages via HTTP
  Future<List<dynamic>> _getMessagesHttp(String conversationId) async {
    try {
      if (_authService == null) {
        _logger.error('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService.getAccessToken();

      if (token == null) {
        _logger.error(
            'Failed to fetch messages: No authentication token available');
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
      _logger.info('Fetching messages from: ${AppConfig.apiBaseUrl}$endpoint');

      final response = await dio.get(endpoint);

      if (response.statusCode == 200) {
        // More robust handling of response data
        try {
          // Debug the response structure
          _logger.info('Response data type: ${response.data.runtimeType}');

          List<dynamic> messages = [];

          // Handle different response formats
          if (response.data is Map) {
            if (response.data.containsKey('data') &&
                response.data['data'] is List) {
              messages = response.data['data'];
              _logger.info(
                  'Successfully fetched ${messages.length} messages from data field');
            } else {
              // Try to extract messages from other fields or use the entire response
              _logger.info(
                  'No data field found in response, checking other possibilities');

              // If response contains a "messages" field
              if (response.data.containsKey('messages') &&
                  response.data['messages'] is List) {
                messages = response.data['messages'];
                _logger.info(
                    'Found ${messages.length} messages in messages field');
              } else {
                // As a fallback, create an empty list
                _logger.info(
                    'No recognizable message format found, using empty list');
                messages = [];
              }
            }
          } else if (response.data is List) {
            messages = response.data;
            _logger.info(
                'Response is directly a list of ${messages.length} messages');
          } else {
            _logger.error('Unknown response format: ${response.data}');
            messages = [];
          }

          // Convert to a safe format with required fields to prevent parsing errors later
          return messages
              .map((item) {
                if (item is! Map) {
                  _logger.warn('Skipping non-Map message item: $item');
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
          _logger.error('Error parsing message response: $parseError');
          _logger.error('Response was: ${response.data}');

          // Return empty list rather than throwing to prevent app crashes
          return [];
        }
      } else {
        _logger.error('Error fetching messages: ${response.statusCode}');
        throw Exception('Failed to fetch messages: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error fetching messages: $e');

      // For common network errors, provide a more graceful failure
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          _logger.warn('Network timeout, returning empty message list');
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
        _logger.error('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService.getAccessToken();

      if (token == null) {
        _logger.error(
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

      _logger.info('Marking conversation as read: $conversationId/read');
      final response =
          await dio.post('${AppEndpoints.conversations}/$conversationId/read');

      return response.statusCode == 200;
    } catch (e) {
      _logger.error('Error marking conversation as read: $e');
      return false;
    }
  }

  /// Create a new conversation
  Future<dynamic> createConversation(String recipientId) async {
    try {
      if (_authService == null) {
        _logger.error('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService.getAccessToken();

      if (token == null) {
        _logger.error(
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

      _logger.info('Creating conversation with recipient: $recipientId');
      final response = await dio.post(
        AppEndpoints.conversations,
        data: {'recipient_id': recipientId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _logger.info('Conversation created successfully');
        return response.data['data'];
      } else {
        _logger.error('Error creating conversation: ${response.statusCode}');
        throw Exception(
            'Failed to create conversation: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error creating conversation: $e');
      rethrow;
    }
  }

  /// Delete a conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      if (_authService == null) {
        _logger.error('AuthService not initialized yet');
        throw Exception('Authentication service not available');
      }

      final token = await _authService.getAccessToken();

      if (token == null) {
        _logger.error(
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

      _logger.info('Deleting conversation: $conversationId');
      final response =
          await dio.delete('${AppEndpoints.conversations}/$conversationId');

      return response.statusCode == 200;
    } catch (e) {
      _logger.error('Error deleting conversation: $e');
      return false;
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
