import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../logger.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:dating_app/providers/providers.dart'; // For loggerProvider

/// Network connectivity status
enum NetworkStatus { checking, online, offline }

/// Provider for current network status
final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  final logger = ref.watch(loggerProvider);
  return NetworkStatusNotifier(logger);
});

/// Provider for whether messages should be queued for offline sending
final offlineQueueEnabledProvider = StateProvider<bool>((ref) => true);

/// Provider for queued messages to be sent when connection is restored
final offlineMessageQueueProvider = StateNotifierProvider<OfflineMessageQueueNotifier, List<Map<String, dynamic>>>((ref) {
  return OfflineMessageQueueNotifier();
});

/// Network status notifier
class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetConnectionStatus>? _internetSubscription;
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker = InternetConnectionChecker();
  final AppLogger _logger;

  NetworkStatusNotifier(this._logger) : super(NetworkStatus.checking) {
    _initialize();
  }

  Future<void> _initialize() async {
    _logger.info('Initializing NetworkStatusNotifier');
    await checkConnectivity(); // Initial check
    _startListening();
  }

  Future<void> checkConnectivity() async {
    if (mounted) {
      state = NetworkStatus.checking;
    }
    try {
      final result = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(result);
    } catch (e) {
      _logger.severe('Error checking initial connectivity: $e');
      if (mounted) {
        state = NetworkStatus.offline; // Assume offline on error
      }
    }
  }

  void _startListening() {
    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    // Listen to actual internet connection status
    _internetSubscription = _internetChecker.onStatusChange.listen((status) {
       _logger.info('Internet Connection Status changed: $status');
      if (mounted) {
          state = (status == InternetConnectionStatus.connected)
              ? NetworkStatus.online
              : NetworkStatus.offline;
           _logger.info('NetworkStatus updated to: $state based on InternetChecker');
       }
    });
     _logger.info('Started listening to network changes.');
  }

  // Updated to handle List<ConnectivityResult>
  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    _logger.info('Connectivity changed: $result');
    // Check if the list contains none or if it's empty (though unlikely for the stream)
    if (result.contains(ConnectivityResult.none) || result.isEmpty) {
       _logger.info('ConnectivityResult indicates no connection. Setting state to offline.');
      if (mounted) {
        state = NetworkStatus.offline;
      }
    } else {
       _logger.info('ConnectivityResult indicates a connection. Verifying with InternetChecker...');
      // Even if WiFi/Mobile is connected, check actual internet access
      final isConnected = await _internetChecker.hasConnection;
      _logger.info('InternetChecker result: $isConnected');
      if (mounted) {
        state = isConnected ? NetworkStatus.online : NetworkStatus.offline;
         _logger.info('NetworkStatus updated to: $state based on ConnectivityResult + InternetChecker');
      }
    }
  }

  @override
  void dispose() {
     _logger.info('Disposing NetworkStatusNotifier.');
    _connectivitySubscription?.cancel();
    _internetSubscription?.cancel();
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