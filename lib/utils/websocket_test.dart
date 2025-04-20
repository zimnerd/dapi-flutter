import 'dart:async';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

/// A utility class for testing WebSocket connections with the mock server
class WebSocketTest {
  // Socket.IO instance
  IO.Socket? _socket;

  // Server configuration
  final String serverUrl;
  final String email;
  final String password;

  // Connection status
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Authentication token
  String? _authToken;

  // Status message streams
  final _logController = StreamController<String>.broadcast();
  Stream<String> get logStream => _logController.stream;

  // Connection result callback
  Function(bool success, String message)? onConnectionResult;

  WebSocketTest({
    required this.serverUrl,
    required this.email,
    required this.password,
    this.onConnectionResult,
  });

  /// Start the WebSocket test
  Future<void> startTest() async {
    log('Starting WebSocket test...');
    log('Server URL: $serverUrl');

    try {
      // Step 1: Get authentication token
      await _getAuthToken();

      // Step 2: Connect to WebSocket server
      if (_authToken != null) {
        await _connectToWebSocket();
      }
    } catch (e) {
      log('❌ Test failed: $e');
      onConnectionResult?.call(false, 'Test failed: $e');
    }
  }

  /// Get authentication token from the server
  Future<void> _getAuthToken() async {
    log('Step 1: Getting authentication token...');

    try {
      final dio = Dio();
      final response = await dio.post(
        '$serverUrl/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      log('Login response received: ${response.statusCode}');

      if (response.data is Map) {
        // Try different token formats
        if (response.data['token'] != null) {
          _authToken = response.data['token'];
        } else if (response.data['data'] != null &&
            response.data['data']['token'] != null) {
          _authToken = response.data['data']['token'];
        } else if (response.data['access_token'] != null) {
          _authToken = response.data['access_token'];
        }
      }

      if (_authToken != null) {
        log('✅ Auth token received: ${_authToken!.substring(0, 15)}...');
      } else {
        log('❌ No token found in response');
        log('Response data: ${response.data}');
        onConnectionResult?.call(
            false, 'Authentication failed: No token received');
      }
    } catch (e) {
      log('❌ Authentication failed: $e');
      onConnectionResult?.call(false, 'Authentication failed: $e');
      rethrow;
    }
  }

  /// Connect to the WebSocket server using Socket.IO
  Future<void> _connectToWebSocket() async {
    log('Step 2: Connecting to WebSocket server...');

    try {
      // Try three different methods of authentication
      await _tryConnectionMethods();

      // Check final connection status
      if (_isConnected) {
        log('✅ Successfully connected to WebSocket server');
        onConnectionResult?.call(
            true, 'Successfully connected to WebSocket server');
      } else {
        log('❌ Failed to connect to WebSocket server');
        onConnectionResult?.call(
            false, 'Failed to connect to WebSocket server');
      }
    } catch (e) {
      log('❌ WebSocket connection error: $e');
      onConnectionResult?.call(false, 'WebSocket connection error: $e');
      rethrow;
    }
  }

  /// Try different methods of WebSocket authentication
  Future<void> _tryConnectionMethods() async {
    log('Trying different authentication methods...');

    // Method 1: Using auth.token
    bool method1Success = await _tryMethodAuth();

    // If method 1 worked, we're done
    if (method1Success) {
      return;
    }

    // Method 2: Using extraHeaders
    bool method2Success = await _tryMethodHeaders();

    // If method 2 worked, we're done
    if (method2Success) {
      return;
    }

    // Method 3: Using query parameters
    bool method3Success = await _tryMethodQuery();

    // Update final connection status
    _isConnected = method1Success || method2Success || method3Success;
  }

  /// Try connection with auth.token method
  Future<bool> _tryMethodAuth() async {
    log('Method 1: Using auth.token property');

    Completer<bool> completer = Completer<bool>();

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': _authToken})
          .enableForceNew()
          .build(),
    );

    // Listen for connection events
    _socket!.onConnect((_) {
      log('  ✅ Connected with auth.token method');
      log('  Socket ID: ${_socket!.id}');
      if (!completer.isCompleted) completer.complete(true);
    });

    _socket!.onConnectError((error) {
      log('  ❌ Connection error with auth.token method: $error');
      if (!completer.isCompleted) completer.complete(false);
    });

    // Set timeout
    Timer(Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        log('  ⏱️ Timeout with auth.token method');
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Try connection with extraHeaders method
  Future<bool> _tryMethodHeaders() async {
    log('Method 2: Using extraHeaders.Authorization');

    Completer<bool> completer = Completer<bool>();

    _socket = IO.io(
      serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $_authToken'})
          .enableForceNew()
          .build(),
    );

    // Listen for connection events
    _socket!.onConnect((_) {
      log('  ✅ Connected with extraHeaders method');
      log('  Socket ID: ${_socket!.id}');
      if (!completer.isCompleted) completer.complete(true);
    });

    _socket!.onConnectError((error) {
      log('  ❌ Connection error with extraHeaders method: $error');
      if (!completer.isCompleted) completer.complete(false);
    });

    // Set timeout
    Timer(Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        log('  ⏱️ Timeout with extraHeaders method');
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Try connection with query parameter method
  Future<bool> _tryMethodQuery() async {
    log('Method 3: Using query parameter');

    Completer<bool> completer = Completer<bool>();

    _socket = IO.io(
      '$serverUrl?token=$_authToken',
      IO.OptionBuilder().setTransports(['websocket']).enableForceNew().build(),
    );

    // Listen for connection events
    _socket!.onConnect((_) {
      log('  ✅ Connected with query parameter method');
      log('  Socket ID: ${_socket!.id}');
      if (!completer.isCompleted) completer.complete(true);
    });

    _socket!.onConnectError((error) {
      log('  ❌ Connection error with query parameter method: $error');
      if (!completer.isCompleted) completer.complete(false);
    });

    // Set timeout
    Timer(Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        log('  ⏱️ Timeout with query parameter method');
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Log a message and add it to the log stream
  void log(String message) {
    print('⟹ [WebSocketTest] $message');
    _logController.add(message);
  }

  /// Send a test message to the server
  void sendTestMessage(String event, Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      log('Sending test message: $event');
      _socket!.emit(event, data);
    } else {
      log('Cannot send message: Not connected');
    }
  }

  /// Disconnect from the WebSocket server
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    log('Disconnected from WebSocket server');
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _logController.close();
  }
}
