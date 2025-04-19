import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../logger.dart';

/// Network status enum for web
enum NetworkStatus {
  online,
  offline,
  unknown
}

/// Provider for network status - simplified for web
final networkStatusProvider = StateProvider<NetworkStatus>((ref) {
  return NetworkStatus.online; // Default to online for web
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

/// Web-compatible network manager 
class NetworkManager {
  /// Starts monitoring network connectivity
  static void startMonitoring() {
    // No-op for web
  }

  /// Stops monitoring network connectivity
  static void stopMonitoring() {
    // No-op for web
  }

  /// Returns the current network status
  static NetworkStatus getCurrentStatus() {
    // Default to online for web
    return NetworkStatus.online;
  }
} 