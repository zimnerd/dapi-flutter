import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/websocket_tester.dart';

/// A dedicated screen for testing WebSocket connections
/// This provides a full-screen experience for testing the chat functionality
class WebSocketTestScreen extends ConsumerWidget {
  const WebSocketTestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Connection Tester'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showInfoDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Use this tool to test WebSocket connectivity',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: WebSocketTester(),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About WebSocket Testing'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text(
                'This tool helps you verify that the WebSocket connection is working properly.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text('How to use:'),
              SizedBox(height: 8),
              Text('1. Click "Connect" to establish a WebSocket connection'),
              Text('2. Check the connection status'),
              Text('3. Send test messages and observe events'),
              Text('4. Try going online/offline to test presence features'),
              SizedBox(height: 16),
              Text(
                'All events from the server will be logged in the event log panel at the bottom of the screen.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
} 