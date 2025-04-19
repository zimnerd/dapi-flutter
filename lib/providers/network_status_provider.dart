import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';

enum NetworkStatus {
  online,
  offline,
  unknown,
}

/// Provider that tracks network connectivity status
final networkStatusProvider = StateNotifierProvider<NetworkStatusNotifier, NetworkStatus>((ref) {
  final logger = Logger('NetworkStatusProvider');
  return NetworkStatusNotifier(Connectivity(), logger);
});

/// Notifier that monitors network connectivity changes
class NetworkStatusNotifier extends StateNotifier<NetworkStatus> {
  final Connectivity _connectivity;
  final Logger _logger;
  StreamSubscription? _connectivitySubscription;

  NetworkStatusNotifier(this._connectivity, this._logger) : super(NetworkStatus.unknown) {
    _initConnectivity();
    _setupSubscription();
  }

  /// Initialize connectivity status
  Future<void> _initConnectivity() async {
    try {
      final status = await _connectivity.checkConnectivity();
      _updateStatus(status);
    } catch (e) {
      _logger.error('Failed to get connectivity status: $e');
      state = NetworkStatus.unknown;
    }
  }

  /// Listen for connectivity changes
  void _setupSubscription() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  /// Update the network status based on connectivity result
  void _updateStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      if (state != NetworkStatus.offline) {
        _logger.debug('⟹ [NetworkStatus] Connectivity status changed to offline');
        state = NetworkStatus.offline;
      }
    } else {
      if (state != NetworkStatus.online) {
        _logger.debug('⟹ [NetworkStatus] Connectivity status changed to online');
        state = NetworkStatus.online;
      }
    }
  }

  /// Check if the network is currently connected
  bool get isConnected => state == NetworkStatus.online;

  /// Manually trigger a connectivity check
  Future<void> checkConnectivity() async {
    try {
      final status = await _connectivity.checkConnectivity();
      _updateStatus(status);
    } catch (e) {
      _logger.error('Failed to check connectivity: $e');
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
} 