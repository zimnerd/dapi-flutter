import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';
import 'providers.dart';
import '../utils/logger.dart';

/// Provider that automatically manages socket connection based on auth state
final socketConnectionProvider = Provider((ref) {
  final logger = Logger('SocketConnection');
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  final socketService = ref.watch(socketServiceProvider);
  
  // Connect socket when user is authenticated
  if (isAuthenticated) {
    // Check if already connected to avoid redundant connects
    if (socketService.status == SocketConnectionStatus.disconnected || 
        socketService.status == SocketConnectionStatus.error) {
      logger.info('User authenticated, connecting socket');
      socketService.connect();
    }
  } else {
    // Disconnect if logged out or not authenticated
    if (socketService.status != SocketConnectionStatus.disconnected) {
      logger.info('User not authenticated, disconnecting socket');
      socketService.disconnect();
    }
  }
  
  // Listen for auth state changes to reconnect if needed
  ref.listen(isAuthenticatedProvider, (previous, current) {
    if (previous == false && current == true) {
      // User just logged in
      logger.info('User logged in, connecting socket');
      socketService.connect();
    } else if (previous == true && current == false) {
      // User just logged out
      logger.info('User logged out, disconnecting socket');
      socketService.disconnect();
    }
  });
  
  // Listen for socket errors and reconnect if authenticated
  ref.listen(
    Provider((ref) => socketService.status),
    (previous, current) {
      if (current == SocketConnectionStatus.error && isAuthenticated) {
        logger.warn('Socket error detected, attempting reconnect in 3 seconds');
        Future.delayed(const Duration(seconds: 3), () {
          if (ref.read(isAuthenticatedProvider)) {
            logger.info('Reconnecting socket after error');
            socketService.connect();
          }
        });
      }
    }
  );
}); 