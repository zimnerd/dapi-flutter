import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

/// A utility class to monitor, log, and debug WebSocket traffic
class WebSocketDebug {
  static final WebSocketDebug _instance = WebSocketDebug._internal();
  factory WebSocketDebug() => _instance;

  // Stream controllers for logs
  final _sentMessagesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _receivedMessagesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _statusController = StreamController<String>.broadcast();

  // Public streams
  Stream<Map<String, dynamic>> get onMessageSent =>
      _sentMessagesController.stream;
  Stream<Map<String, dynamic>> get onMessageReceived =>
      _receivedMessagesController.stream;
  Stream<String> get onError => _errorController.stream;
  Stream<String> get onStatus => _statusController.stream;

  // In-memory log storage for UI display
  List<Map<String, dynamic>> _sentMessages = [];
  List<Map<String, dynamic>> _receivedMessages = [];
  List<String> _errors = [];
  List<String> _statuses = [];

  // Get stored logs
  List<Map<String, dynamic>> get sentMessages => _sentMessages;
  List<Map<String, dynamic>> get receivedMessages => _receivedMessages;
  List<String> get errors => _errors;
  List<String> get statuses => _statuses;

  // File for logs
  File? _logFile;
  bool _isFileLoggingEnabled = false;

  WebSocketDebug._internal() {
    // Initialize log storage
    _setupStreams();
  }

  void _setupStreams() {
    onMessageSent.listen((message) {
      _sentMessages.add(message);
      _writeToLogFile('SENT: ${message.toString()}');
    });

    onMessageReceived.listen((message) {
      _receivedMessages.add(message);
      _writeToLogFile('RECEIVED: ${message.toString()}');
    });

    onError.listen((error) {
      _errors.add(error);
      _writeToLogFile('ERROR: $error');
    });

    onStatus.listen((status) {
      _statuses.add(status);
      _writeToLogFile('STATUS: $status');
    });
  }

  /// Initialize file logging
  Future<void> initializeFileLogging(String filePath) async {
    try {
      _logFile = File(filePath);

      // Create file if it doesn't exist
      if (!await _logFile!.exists()) {
        await _logFile!.create(recursive: true);
      }

      // Write header
      await _logFile!.writeAsString(
          '=== WebSocket Debug Log ===\nStarted at: ${DateTime.now()}\n\n');

      _isFileLoggingEnabled = true;
      logStatus('File logging initialized at: $filePath');
    } catch (e) {
      logError('Failed to initialize file logging: $e');
    }
  }

  /// Write to log file if enabled
  Future<void> _writeToLogFile(String content) async {
    if (!_isFileLoggingEnabled || _logFile == null) return;

    try {
      await _logFile!.writeAsString('[${DateTime.now()}] $content\n',
          mode: FileMode.append);
    } catch (e) {
      // Don't use logError here to avoid infinite loop
      print('Error writing to log file: $e');
    }
  }

  /// Log a sent message
  void logSentMessage(Map<String, dynamic> message) {
    _sentMessagesController.add(message);
  }

  /// Log a received message
  void logReceivedMessage(Map<String, dynamic> message) {
    _receivedMessagesController.add(message);
  }

  /// Log an error
  void logError(String error) {
    _errorController.add(error);
  }

  /// Log status information
  void logStatus(String status) {
    _statusController.add(status);
  }

  /// Clear all stored logs
  void clearLogs() {
    _sentMessages.clear();
    _receivedMessages.clear();
    _errors.clear();
    _statuses.clear();
    logStatus('Logs cleared');
  }

  /// Export logs to a file
  Future<String> exportLogs(String filePath) async {
    try {
      final file = File(filePath);
      final buffer = StringBuffer();

      buffer.writeln('=== WEBSOCKET DEBUG EXPORT ===');
      buffer.writeln('Export time: ${DateTime.now()}');
      buffer.writeln('=== SENT MESSAGES ===');
      for (var message in _sentMessages) {
        buffer.writeln('${message.toString()}');
      }

      buffer.writeln('\n=== RECEIVED MESSAGES ===');
      for (var message in _receivedMessages) {
        buffer.writeln('${message.toString()}');
      }

      buffer.writeln('\n=== ERRORS ===');
      for (var error in _errors) {
        buffer.writeln(error);
      }

      buffer.writeln('\n=== STATUS UPDATES ===');
      for (var status in _statuses) {
        buffer.writeln(status);
      }

      await file.writeAsString(buffer.toString());
      return 'Logs exported to: $filePath';
    } catch (e) {
      return 'Failed to export logs: $e';
    }
  }

  /// Dispose resources
  void dispose() {
    _sentMessagesController.close();
    _receivedMessagesController.close();
    _errorController.close();
    _statusController.close();
  }
}

/// A widget to display the WebSocket debug monitor
class WebSocketDebugMonitor extends StatefulWidget {
  const WebSocketDebugMonitor({Key? key}) : super(key: key);

  @override
  _WebSocketDebugMonitorState createState() => _WebSocketDebugMonitorState();
}

class _WebSocketDebugMonitorState extends State<WebSocketDebugMonitor> {
  final _debug = WebSocketDebug();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WebSocket Debug Monitor'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Sent'),
              Tab(text: 'Received'),
              Tab(text: 'Errors'),
              Tab(text: 'Status'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  _debug.clearLogs();
                });
              },
              tooltip: 'Clear logs',
            ),
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () async {
                final result =
                    await _debug.exportLogs('/tmp/websocket_debug.log');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result)),
                );
              },
              tooltip: 'Export logs',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildLogList(
                _debug.sentMessages.map((m) => m.toString()).toList()),
            _buildLogList(
                _debug.receivedMessages.map((m) => m.toString()).toList()),
            _buildLogList(_debug.errors),
            _buildLogList(_debug.statuses),
          ],
        ),
      ),
    );
  }

  Widget _buildLogList(List<String> logs) {
    return StreamBuilder<Object>(
        stream: _debug.onStatus, // Just to trigger rebuilds
        builder: (context, snapshot) {
          return ListView.builder(
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[logs.length - 1 - index]; // Reverse order
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    log,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              );
            },
          );
        });
  }
}
