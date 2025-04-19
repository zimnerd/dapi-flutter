import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../logger.dart';

/// Network connectivity status
enum NetworkStatus {
  online,
  offline,
}

/// Provider for current network status
final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  return NetworkStatusNotifier();
});

/// Provider for whether messages should be queued for offline sending
final offlineQueueEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for queued messages to be sent when connection is restored
final offlineMessageQueueProvider = StateNotifierProvider<OfflineMessageQueueNotifier, List<Map<String, dynamic>>>((ref) {
  return OfflineMessageQueueNotifier();
});

/// Network status notifier
class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  NetworkStatusNotifier() : super(NetworkStatus.online) {
    _initConnectivity();
    _setupConnectivityListener();
  }

  final _logger = Logger('Network');
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  Future<void> _initConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      _logger.error('Failed to check connectivity: $e');
    }
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      if (state != NetworkStatus.offline) {
        _logger.warn('Network connection lost');
        state = NetworkStatus.offline;
      }
    } else {
      if (state != NetworkStatus.online) {
        _logger.info('Network connection restored');
        state = NetworkStatus.online;
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Queue manager for offline messages
class OfflineMessageQueueNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  OfflineMessageQueueNotifier() : super([]);
  final _logger = Logger('OfflineQueue');

  /// Add a message to the offline queue
  void addToQueue(Map<String, dynamic> message) {
    _logger.info('Adding message to offline queue: ${message['text']}');
    state = [...state, message];
  }

  /// Get next message from the queue
  Map<String, dynamic>? peekNextMessage() {
    if (state.isEmpty) return null;
    return state.first;
  }

  /// Remove a message from the queue
  void removeFromQueue(String messageId) {
    _logger.info('Removing message from offline queue: $messageId');
    state = state.where((msg) => msg['id'] != messageId).toList();
  }

  /// Clear the entire queue
  void clearQueue() {
    _logger.info('Clearing offline message queue');
    state = [];
  }
}

/// Network manager that handles connectivity and retries
class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;
  NetworkManager._internal();

  final _logger = Logger('NetworkManager');
  
  /// Check if the device is currently online
  static Future<bool> isOnline() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Show a snackbar when offline
  static void showOfflineSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.signal_wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('You are offline. Messages will be sent when you reconnect.'),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
} 