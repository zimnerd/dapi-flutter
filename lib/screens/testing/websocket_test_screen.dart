import 'package:flutter/material.dart';
import '../../utils/websocket_test.dart';

class WebSocketTestScreen extends StatefulWidget {
  const WebSocketTestScreen({super.key});

  @override
  _WebSocketTestScreenState createState() => _WebSocketTestScreenState();
}

class _WebSocketTestScreenState extends State<WebSocketTestScreen> {
  final _serverUrlController =
      TextEditingController(text: 'https://dapi.pulsetek.co.za:3000');
  final _emailController =
      TextEditingController(text: 'eddienyagano@gmail.com');
  final _passwordController = TextEditingController(text: 'password123');

  final List<String> _logs = [];
  bool _isConnected = false;
  bool _isLoading = false;
  WebSocketTest? _webSocketTest;

  @override
  void dispose() {
    _serverUrlController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _webSocketTest?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Server URL input
            TextField(
              controller: _serverUrlController,
              decoration: const InputDecoration(
                labelText: 'Server URL',
                hintText: 'https://dapi.pulsetek.co.za:3000',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Email input
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Password input
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                hintText: 'Enter password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Connection status indicator
            Container(
              height: 40,
              decoration: BoxDecoration(
                color:
                    _isConnected ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                _isConnected
                    ? 'Connected to WebSocket server'
                    : 'Not connected',
                style: TextStyle(
                  color: _isConnected
                      ? Colors.green.shade800
                      : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startTest,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !_isConnected ? null : _sendTestMessage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Send Test Message'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !_isConnected ? null : _disconnect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Disconnect'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Logs
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(8),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        log,
                        style: TextStyle(
                          color: _getLogColor(log),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
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

  // Helper to get appropriate color for log messages
  Color _getLogColor(String log) {
    if (log.contains('✅')) return Colors.green;
    if (log.contains('❌')) return Colors.red;
    if (log.contains('⏱️')) return Colors.orange;
    if (log.contains('Step')) return Colors.cyan;
    if (log.contains('Connected')) return Colors.green.shade300;
    return Colors.white;
  }

  // Start the WebSocket test
  void _startTest() async {
    // Reset logs
    setState(() {
      _logs.clear();
      _isLoading = true;
      _isConnected = false;
    });

    // Create WebSocket test instance
    _webSocketTest = WebSocketTest(
      serverUrl: _serverUrlController.text,
      email: _emailController.text,
      password: _passwordController.text,
      onConnectionResult: (success, message) {
        setState(() {
          _isConnected = success;
          _isLoading = false;
        });
      },
    );

    // Subscribe to log stream
    _webSocketTest!.logStream.listen((log) {
      setState(() {
        _logs.add(log);
      });
    });

    // Start test
    await _webSocketTest!.startTest();
  }

  // Send a test message to the server
  void _sendTestMessage() {
    if (_webSocketTest != null && _isConnected) {
      _webSocketTest!
          .sendTestMessage('ping', {'message': 'Hello from Flutter client!'});
    }
  }

  // Disconnect from the server
  void _disconnect() {
    _webSocketTest?.disconnect();
    setState(() {
      _isConnected = false;
    });
  }
}
