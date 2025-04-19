import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';
import 'providers.dart';

/// Socket connection provider that automatically manages socket connection based on auth state
final socketConnectionProvider = Provider<void>((ref) {
  final logger = Logger('SocketConnectionProvider');
  final authState = ref.watch(authStateProvider);
  final socketService = ref.watch(socketServiceProvider);
  
  // Connect socket when authenticated, disconnect when logged out
  if (authState.status == AuthStatus.authenticated) {
    // Only connect if not already connected/connecting
    if (socketService.connectionStatus == SocketConnectionStatus.disconnected ||
        socketService.connectionStatus == SocketConnectionStatus.error) {
      logger.debug('⟹ [SocketConnectionProvider] Auth state is authenticated, connecting socket');
      socketService.connect();
    }
  } else {
    // Only disconnect if currently connected
    if (socketService.connectionStatus == SocketConnectionStatus.connected ||
        socketService.connectionStatus == SocketConnectionStatus.authenticated) {
      logger.debug('⟹ [SocketConnectionProvider] Auth state is not authenticated, disconnecting socket');
      socketService.disconnect();
    }
  }
  
  // Return void as we're just using this provider for side effects
  return;
}); 