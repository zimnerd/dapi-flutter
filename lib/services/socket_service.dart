import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import '../providers/providers.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return SocketService(secureStorage);
});

enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  authenticated,
  error
}

class SocketService {
  final FlutterSecureStorage _secureStorage;
  final _logger = Logger('Socket');
  
  IO.Socket? _socket;
  SocketConnectionStatus _connectionStatus = SocketConnectionStatus.disconnected;
  
  // Stream controllers
  final _connectionStatusController = StreamController<SocketConnectionStatus>.broadcast();
  final _messageReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _typingStatusController = StreamController<Map<String, dynamic>>.broadcast();
  final _readReceiptController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream getters
  Stream<SocketConnectionStatus> get connectionStatus => _connectionStatusController.stream;
  Stream<Map<String, dynamic>> get messageReceived => _messageReceivedController.stream;
  Stream<Map<String, dynamic>> get typingStatus => _typingStatusController.stream;
  Stream<Map<String, dynamic>> get readReceipt => _readReceiptController.stream;
  
  SocketService(this._secureStorage);
  
  SocketConnectionStatus get status => _connectionStatus;
  bool get isConnected => _connectionStatus == SocketConnectionStatus.connected || 
                        _connectionStatus == SocketConnectionStatus.authenticated;
  
  Future<void> connect() async {
    if (_socket != null) {
      _logger.debug('Socket already initialized. Current status: $_connectionStatus');
      return;
    }
    
    _connectionStatus = SocketConnectionStatus.connecting;
    _connectionStatusController.add(_connectionStatus);
    
    try {
      final token = await _secureStorage.read(key: AppStorageKeys.accessToken);
      
      if (token == null || token.isEmpty) {
        _logger.error('Failed to connect: No authentication token available');
        _connectionStatus = SocketConnectionStatus.error;
        _connectionStatusController.add(_connectionStatus);
        return;
      }
      
      _logger.info('Initializing socket connection to: ${AppConfig.socketUrl}');
      
      _socket = IO.io(
        AppConfig.socketUrl,
        IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNewConnection()
          .setExtraHeaders({
            'Authorization': 'Bearer $token'
          })
          .setAuth({
            'token': token
          })
          .build()
      );
      
      _setupSocketListeners();
      _socket!.connect();
      
    } catch (e) {
      _logger.error('Socket connection error: $e');
      _connectionStatus = SocketConnectionStatus.error;
      _connectionStatusController.add(_connectionStatus);
    }
  }
  
  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      _logger.info('Socket connected');
      _connectionStatus = SocketConnectionStatus.connected;
      _connectionStatusController.add(_connectionStatus);
    });
    
    _socket!.onConnectError((error) {
      _logger.error('Socket connection error: $error');
      _connectionStatus = SocketConnectionStatus.error;
      _connectionStatusController.add(_connectionStatus);
    });
    
    _socket!.onDisconnect((_) {
      _logger.info('Socket disconnected');
      _connectionStatus = SocketConnectionStatus.disconnected;
      _connectionStatusController.add(_connectionStatus);
    });
    
    _socket!.onReconnecting((_) {
      _logger.info('Socket reconnecting');
      _connectionStatus = SocketConnectionStatus.reconnecting;
      _connectionStatusController.add(_connectionStatus);
    });
    
    _socket!.onReconnect((_) {
      _logger.info('Socket reconnected');
      _connectionStatus = SocketConnectionStatus.connected;
      _connectionStatusController.add(_connectionStatus);
    });
    
    _socket!.onError((error) {
      _logger.error('Socket error: $error');
      _connectionStatus = SocketConnectionStatus.error;
      _connectionStatusController.add(_connectionStatus);
    });
    
    // Listen for authentication response
    _socket!.on('authenticated', (_) {
      _logger.info('Socket authenticated');
      _connectionStatus = SocketConnectionStatus.authenticated;
      _connectionStatusController.add(_connectionStatus);
    });
    
    // Listen for messages
    _socket!.on('message_received', (data) {
      _logger.debug('Message received: $data');
      _messageReceivedController.add(data);
    });
    
    // Listen for typing status
    _socket!.on('chat:typing:start', (data) {
      _logger.debug('Typing started: $data');
      _typingStatusController.add({'typing': true, ...data});
    });
    
    _socket!.on('chat:typing:stop', (data) {
      _logger.debug('Typing stopped: $data');
      _typingStatusController.add({'typing': false, ...data});
    });
    
    // Listen for read receipts
    _socket!.on('chat:read', (data) {
      _logger.debug('Message read: $data');
      _readReceiptController.add(data);
    });
  }
  
  void disconnect() {
    _logger.info('Disconnecting socket');
    _socket?.disconnect();
    _connectionStatus = SocketConnectionStatus.disconnected;
    _connectionStatusController.add(_connectionStatus);
  }
  
  void dispose() {
    _logger.info('Disposing socket service');
    _socket?.dispose();
    _socket = null;
    _connectionStatus = SocketConnectionStatus.disconnected;
    
    // Close stream controllers
    _connectionStatusController.close();
    _messageReceivedController.close();
    _typingStatusController.close();
    _readReceiptController.close();
  }
  
  // Join a chat room
  void joinConversation(String conversationId) {
    if (!isConnected) {
      _logger.warn('Cannot join conversation: Socket not connected');
      return;
    }
    
    _logger.info('Joining conversation: $conversationId');
    _socket!.emit('chat:join', conversationId);
  }
  
  // Leave a chat room
  void leaveConversation(String conversationId) {
    if (!isConnected) {
      _logger.warn('Cannot leave conversation: Socket not connected');
      return;
    }
    
    _logger.info('Leaving conversation: $conversationId');
    _socket!.emit('chat:leave', conversationId);
  }
  
  // Send a message
  void sendMessage(String conversationId, String message, {Map<String, dynamic>? extras}) {
    if (!isConnected) {
      _logger.warn('Cannot send message: Socket not connected');
      return;
    }
    
    _logger.info('Sending message to conversation: $conversationId');
    _socket!.emit('chat:message', {
      'conversation_id': conversationId,
      'message': message,
      ...?extras
    });
  }
  
  // Send typing indicator
  void sendTypingStart(String conversationId) {
    if (!isConnected) return;
    
    _logger.debug('Sending typing start for conversation: $conversationId');
    _socket!.emit('chat:typing:start', conversationId);
  }
  
  // Stop typing indicator
  void sendTypingStop(String conversationId) {
    if (!isConnected) return;
    
    _logger.debug('Sending typing stop for conversation: $conversationId');
    _socket!.emit('chat:typing:stop', conversationId);
  }
  
  // Mark messages as read
  void markMessageRead(String conversationId, String messageId) {
    if (!isConnected) return;
    
    _logger.debug('Marking message $messageId as read in conversation: $conversationId');
    _socket!.emit('chat:read', {
      'conversation_id': conversationId,
      'message_id': messageId
    });
  }
} 