import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../config/app_config.dart';

/// A widget for testing WebSocket connections
/// This widget can be embedded in a screen to verify WebSocket functionality
class WebSocketTester extends ConsumerStatefulWidget {
  const WebSocketTester({super.key});

  @override
  ConsumerState<WebSocketTester> createState() => _WebSocketTesterState();
}

class _WebSocketTesterState extends ConsumerState<WebSocketTester> {
  final _logs = <String>[];
  bool _isConnected = false;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Subscription management
  late List<StreamSubscription> _subscriptions;

  @override
  void initState() {
    super.initState();
    _subscriptions = [];
    _setupListeners();
  }

  void _setupListeners() {
    // Get ChatService instance
    final chatService = ref.read(chatServiceProvider);

    // Listen for new messages
    _subscriptions.add(chatService.onNewMessage.listen((data) {
      _addLog('Message received: ${data.toString()}');
    }));

    // Listen for typing indicators
    _subscriptions.add(chatService.onTypingEvent.listen((data) {
      _addLog('Typing event: ${data.toString()}');
    }));

    // Listen for read receipts
    _subscriptions.add(chatService.onReadReceipt.listen((data) {
      _addLog('Read receipt: ${data.toString()}');
    }));

    // Listen for online status updates
    _subscriptions.add(chatService.onOnlineStatus.listen((data) {
      _addLog('Online status update: ${data.toString()}');
    }));

    // Listen for errors
    _subscriptions.add(chatService.onError.listen((error) {
      _addLog('ERROR: $error');
    }));

    // Listen for group messages
    _subscriptions.add(chatService.onGroupMessage.listen((data) {
      _addLog('Group message: ${data.toString()}');
    }));

    // Listen for room updates
    _subscriptions.add(chatService.onRoomUpdate.listen((data) {
      _addLog('Room update: ${data.toString()}');
    }));
  }

  void _addLog(String log) {
    setState(() {
      _logs.add('[${DateTime.now().toIso8601String()}] $log');
      // Limit logs to 100 entries
      if (_logs.length > 100) {
        _logs.removeAt(0);
      }
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _connectWebSocket() async {
    final chatService = ref.read(chatServiceProvider);

    _addLog('Initializing WebSocket...');
    await chatService.initSocket();

    _addLog('Connecting to WebSocket server at ${AppConfig.socketUrl}');
    chatService.connect();

    setState(() {
      _isConnected = chatService.isConnected;
    });

    // Check status after delay to allow connection
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isConnected = chatService.isConnected;
      });
      _addLog(
          'Connection status after delay: ${_isConnected ? 'Connected ✅' : 'Failed to connect ❌'}');
    });
  }

  // New method to check token info
  void _checkAuthToken() async {
    try {
      final authService = ref.read(authServiceProvider);
      final token = await authService.getAccessToken();

      if (token != null) {
        _addLog('🔐 Auth token found: ${token.substring(0, 10)}...');

        // Check token expiration if possible
        try {
          final parts = token.split('.');
          if (parts.length == 3) {
            final payload = parts[1];
            final normalized = base64Url.normalize(payload);
            final decoded = utf8.decode(base64Url.decode(normalized));
            final Map<String, dynamic> data = jsonDecode(decoded);

            if (data.containsKey('exp')) {
              final exp = data['exp'];
              final expDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
              final now = DateTime.now();
              final isExpired = expDate.isBefore(now);

              _addLog('Token expiration: ${expDate.toString()}');
              _addLog('Token status: ${isExpired ? "EXPIRED ❌" : "VALID ✅"}');
            } else {
              _addLog('Token does not contain expiration information');
            }
          }
        } catch (e) {
          _addLog('Could not parse token details: $e');
        }
      } else {
        _addLog('❌ No auth token found. Login required.');
      }
    } catch (e) {
      _addLog('❌ Error checking token: $e');
    }
  }

  // Force reconnect with fresh token
  void _forceReconnect() async {
    _addLog('🔄 Forcing reconnection with fresh token...');

    final chatService = ref.read(chatServiceProvider);
    final authService = ref.read(authServiceProvider);

    // Disconnect current socket
    if (chatService.isConnected) {
      _addLog('Disconnecting current socket...');
      chatService.disconnect();
    }

    // Get a fresh token if possible
    try {
      // Refresh token if you have a refresh method
      _addLog('Attempting to refresh authentication...');
      await authService.refreshToken();
      _addLog('Token refreshed successfully');
    } catch (e) {
      _addLog('⚠️ Token refresh failed: $e');
    }

    // Reinitialize and connect
    await chatService.initSocket();
    chatService.connect();

    _addLog('Reconnection attempt complete');

    // Check status after delay
    Future.delayed(Duration(seconds: 2), () {
      setState(() {
        _isConnected = chatService.isConnected;
      });
      _addLog(
          'Connection status after reconnect: ${_isConnected ? 'Connected ✅' : 'Failed to connect ❌'}');
    });
  }

  void _disconnectWebSocket() {
    final chatService = ref.read(chatServiceProvider);
    chatService.disconnect();

    _addLog('Disconnected from WebSocket server');
    setState(() {
      _isConnected = false;
    });
  }

  void _sendTestMessage() {
    if (_recipientController.text.isEmpty || _messageController.text.isEmpty) {
      _addLog('Error: Please enter recipient ID and message text');
      return;
    }

    final chatService = ref.read(chatServiceProvider);
    final recipientId = _recipientController.text;
    final messageText = _messageController.text;

    chatService.sendPrivateMessage(recipientId, messageText);
    _addLog('Sent message to $recipientId: $messageText');
    _messageController.clear();
  }

  void _updateOnlineStatus(bool isOnline) {
    final chatService = ref.read(chatServiceProvider);
    chatService.updateOnlineStatus(isOnline);
    _addLog('Updated online status: $isOnline');
  }

  void _checkConnectionStatus() {
    final chatService = ref.read(chatServiceProvider);
    final isConnected = chatService.isConnected;

    setState(() {
      _isConnected = isConnected;
    });

    _addLog(
        'Connection status check: ${isConnected ? 'Connected' : 'Disconnected'}');
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _messageController.dispose();
    _recipientController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'WebSocket Tester',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),

            // Connection status
            Row(
              children: [
                Icon(
                  _isConnected ? Icons.circle : Icons.circle_outlined,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: _isConnected ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _checkConnectionStatus,
                  child: const Text('Check Status'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Connect/Disconnect buttons
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isConnected ? null : _connectWebSocket,
                  child: const Text('Connect'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isConnected ? _disconnectWebSocket : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Disconnect'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional connection troubleshooting buttons
            Text(
              'Troubleshooting',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _checkAuthToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Check Token'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _forceReconnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Force Reconnect'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Online status buttons
            if (_isConnected) ...[
              Text(
                'Online Status',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _updateOnlineStatus(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Go Online'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _updateOnlineStatus(false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Go Offline'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Test message form
            if (_isConnected) ...[
              Text(
                'Send Test Message',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _recipientController,
                decoration: const InputDecoration(
                  labelText: 'Recipient ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendTestMessage,
                    child: const Text('Send'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Log viewer
            Text(
              'Event Logs',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _logs[index],
                      style: const TextStyle(
                        color: Colors.green,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
