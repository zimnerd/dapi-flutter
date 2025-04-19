import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logger.dart';

/// Network connectivity status
enum NetworkStatus {
  online,
  offline,
}

/// Provider for current network status (stub for web)
final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  return NetworkStatusNotifier();
});

/// Provider for whether messages should be queued for offline sending
final offlineQueueEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for queued messages to be sent when connection is restored
final offlineMessageQueueProvider = StateNotifierProvider<OfflineMessageQueueNotifier, List<Map<String, dynamic>>>((ref) {
  return OfflineMessageQueueNotifier();
});

/// Network status notifier - Stub implementation for web
class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  NetworkStatusNotifier() : super(NetworkStatus.online);

  final _logger = Logger('NetworkStub');

  // Web always returns online in this stub
  Future<void> checkConnectivity() async {
    _logger.info('Web stub: always returning online status');
    state = NetworkStatus.online;
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Queue manager for offline messages
class OfflineMessageQueueNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  OfflineMessageQueueNotifier() : super([]);
  final _logger = Logger('OfflineQueueStub');

  /// Add a message to the offline queue
  void addToQueue(Map<String, dynamic> message) {
    _logger.info('Web stub: Adding message to offline queue: ${message['text']}');
    state = [...state, message];
  }

  /// Get next message from the queue
  Map<String, dynamic>? peekNextMessage() {
    if (state.isEmpty) return null;
    return state.first;
  }

  /// Remove a message from the queue
  void removeFromQueue(String messageId) {
    _logger.info('Web stub: Removing message from offline queue: $messageId');
    state = state.where((msg) => msg['id'] != messageId).toList();
  }

  /// Clear the entire queue
  void clearQueue() {
    _logger.info('Web stub: Clearing offline message queue');
    state = [];
  }
}

/// Network manager stub for web
class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  final _logger = Logger('NetworkManagerStub');
  
  /// Check if the device is currently online (always returns true for web)
  static Future<bool> isOnline() async {
    return true;
  }

  /// Show a snackbar when offline
  static void showOfflineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.signal_wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('Web stub: Always online in browser'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
} 