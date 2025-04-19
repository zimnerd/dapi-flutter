import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/logger.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

/// Connection status for the socket
enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  authenticated,
  error
}

/// Provider for the socket service
final socketServiceProvider = Provider<SocketService>((ref) {
  final authService = ref.watch(authServiceProvider);
  final logger = Logger('SocketService');
  return SocketService(authService, logger);
});

typedef SocketEventCallback = void Function(Map<String, dynamic>? data);
typedef ConnectionStatusCallback = void Function(bool isConnected);

/// Class to manage Socket.IO connections
class SocketService extends ChangeNotifier {
  final AuthService _authService;
  final Logger _logger;
  
  IO.Socket? _socket;
  SocketConnectionStatus _status = SocketConnectionStatus.disconnected;
  final Map<String, List<SocketEventCallback>> _eventHandlers = {};
  
  // Streams for emitting events
  final _messageReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _connectionStatusController = StreamController<SocketConnectionStatus>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  
  /// Get current connection status
  SocketConnectionStatus get status => _status;
  
  /// Stream of received messages
  Stream<Map<String, dynamic>> get messageReceived => _messageReceivedController.stream;
  
  /// Stream of typing status updates
  Stream<Map<String, dynamic>> get typingStatus => _typingStatusController.stream;
  
  /// Stream of connection status changes
  Stream<SocketConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  
  /// Stream of connection errors
  Stream<String> get connectionError => _errorController.stream;
  
  /// Is the socket currently connected
  bool get isConnected => _socket != null && 
                        (_status == SocketConnectionStatus.connected || 
                         _status == SocketConnectionStatus.authenticated);
  
  /// Constructor
  SocketService(this._authService, this._logger);
  
  /// Connect to the socket server
  void connect() async {
    if (_socket != null) {
      _logger.info('Socket already exists, disconnecting first');
      disconnect();
    }
    
    _setStatus(SocketConnectionStatus.connecting);
    
    try {
      // Get auth token for socket connection
      final token = await _authService.getAccessToken();
      
      if (token == null || token.isEmpty) {
        _logger.error('No authentication token available for socket connection');
        _setStatus(SocketConnectionStatus.error);
        _errorController.add('Authentication required');
        return;
      }
      
      // Configure socket options
      _socket = IO.io(
        AppConfig.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setAuth({'token': token})
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .setQuery({
              'userId': _authService.userId,
            })
            .build()
      );
      
      // Set up event handlers
      _setupEventHandlers();
      
      // Connect
      _socket!.connect();
      
      _logger.info('Socket connection initiated');
    } catch (e) {
      _logger.error('Error connecting to socket: $e');
      _setStatus(SocketConnectionStatus.error);
      _errorController.add('Connection error: $e');
    }
  }
  
  /// Disconnect from the socket
  void disconnect() {
    _logger.info('Disconnecting socket');
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _setStatus(SocketConnectionStatus.disconnected);
  }
  
  /// Set up socket event handlers
  void _setupEventHandlers() {
    if (_socket == null) return;
    
    // Connection events
    _socket!.onConnect((_) {
      _logger.info('Socket connected');
      _setStatus(SocketConnectionStatus.connected);
    });
    
    _socket!.onConnectError((error) {
      _logger.error('Socket connect error: $error');
      _setStatus(SocketConnectionStatus.error);
      _errorController.add('Connect error: $error');
    });
    
    _socket!.onDisconnect((_) {
      _logger.info('Socket disconnected');
      _setStatus(SocketConnectionStatus.disconnected);
    });
    
    _socket!.onError((error) {
      _logger.error('Socket error: $error');
      _errorController.add('Socket error: $error');
    });
    
    // Auth events
    _socket!.on('authenticated', (data) {
      _logger.info('Socket authenticated');
      _setStatus(SocketConnectionStatus.authenticated);
    });
    
    _socket!.on('unauthorized', (data) {
      _logger.error('Socket unauthorized: $data');
      _setStatus(SocketConnectionStatus.error);
      _errorController.add('Authentication failed');
    });
    
    // Chat events
    _socket!.on('message', (data) {
      _logger.debug('Received message event: $data');
      _messageReceivedController.add(data);
    });
    
    _socket!.on('typing', (data) {
      _logger.debug('Received typing event: $data');
      _typingStatusController.add(data);
    });
    
    // Listen for read receipts
    _socket!.on('read', (data) {
      _logger.info('Read receipt: ${jsonEncode(data)}');
      _notifyEventListeners('read', data);
    });
  }
  
  /// Update and emit status changes
  void _setStatus(SocketConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _connectionStatusController.add(newStatus);
    }
  }
  
  /// Join a conversation room
  void joinConversation(String conversationId) {
    if (!isConnected) {
      _logger.warn('Cannot join conversation $conversationId: not connected');
      return;
    }
    
    _logger.info('Joining conversation: $conversationId');
    _socket!.emit('joinConversation', {
      'conversationId': conversationId,
      'userId': _authService.userId
    });
  }
  
  /// Leave a conversation room
  void leaveConversation(String conversationId) {
    if (!isConnected) return;
    
    _logger.info('Leaving conversation: $conversationId');
    _socket!.emit('leaveConversation', {
      'conversationId': conversationId,
      'userId': _authService.userId
    });
  }
  
  /// Send a message to a conversation
  void sendMessage(String conversationId, String text, {Map<String, dynamic>? extras}) {
    if (!isConnected) {
      _logger.warn('Cannot send message to $conversationId: not connected');
      return;
    }
    
    _logger.info('Sending message to conversation: $conversationId');
    
    final message = {
      'conversation_id': conversationId,
      'message': text,
      'timestamp': DateTime.now().toIso8601String(),
      ...?extras,
    };
    
    _socket!.emit('message', message);
  }
  
  /// Mark a message as read
  void markMessageRead(String conversationId, String messageId) {
    if (!isConnected) return;
    
    _logger.info('Marking message $messageId as read');
    _socket!.emit('read', {
      'conversation_id': conversationId,
      'message_id': messageId,
    });
  }
  
  /// Send typing start notification
  void sendTypingStart(String conversationId) {
    if (!isConnected) return;
    
    _logger.debug('Sending typing start for conversation: $conversationId');
    _socket!.emit('typing', {
      'conversation_id': conversationId,
      'is_typing': true,
    });
  }
  
  /// Send typing stop notification
  void sendTypingStop(String conversationId) {
    if (!isConnected) return;
    
    _logger.debug('Sending typing stop for conversation: $conversationId');
    _socket!.emit('typing', {
      'conversation_id': conversationId,
      'is_typing': false,
    });
  }
  
  /// Cleanup resources
  void dispose() {
    disconnect();
    _messageReceivedController.close();
    _typingStatusController.close();
    _connectionStatusController.close();
    _errorController.close();
    super.dispose();
  }
  
  void _notifyEventListeners(String event, dynamic data) {
    if (_eventHandlers.containsKey(event)) {
      for (final handler in _eventHandlers[event]!) {
        handler(data);
      }
    }
  }
  
  // Register event handlers
  void on(String event, SocketEventCallback callback) {
    if (!_eventHandlers.containsKey(event)) {
      _eventHandlers[event] = [];
    }
    _eventHandlers[event]!.add(callback);
  }
  
  // Convenience methods for specific events
  void onMessageReceived(SocketEventCallback callback) {
    on('message', callback);
  }
  
  void onTypingStatusChanged(SocketEventCallback callback) {
    on('typing', callback);
  }
  
  void onReadReceiptReceived(SocketEventCallback callback) {
    on('read', callback);
  }
  
  void onConnectionStatusChanged(ConnectionStatusCallback callback) {
    addListener(() {
      callback(isConnected);
    });
  }
  
  // Reconnect if disconnected
  void reconnect() {
    if (!_isConnected && _socket != null) {
      _logger.info('Attempting to reconnect');
      _socket!.connect();
    }
  }
  
  // Send a new message
  void sendMessage({
    required String conversationId,
    required String content,
    required String senderId,
  }) {
    if (isConnected && _socket != null) {
      _logger.info('Sending message to conversation: $conversationId');
      _socket!.emit('message', {
        'conversationId': conversationId,
        'senderId': senderId,
        'content': content,
        'timestamp': DateTime.now().toIso8601String()
      });
    } else {
      _logger.warn('Cannot send message: Socket not connected');
    }
  }
  
  // Send typing status
  void sendTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    if (isConnected && _socket != null) {
      _logger.info('Sending typing status: $isTyping');
      _socket!.emit('typing', {
        'conversationId': conversationId,
        'userId': userId,
        'isTyping': isTyping
      });
    }
  }
  
  // Send read receipt
  void sendReadReceipt({
    required String conversationId,
    required String userId,
  }) {
    if (isConnected && _socket != null) {
      _logger.info('Sending read receipt for conversation: $conversationId');
      _socket!.emit('read', {
        'conversationId': conversationId,
        'userId': userId,
        'timestamp': DateTime.now().toIso8601String()
      });
    }
  }
} 