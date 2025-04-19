import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/auth_service.dart';

/// Provider that exposes the current user's ID
final userIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);
  
  if (authState.status == AuthStatus.authenticated) {
    return authService.getUserId();
  }
  return null;
});

/// Provider that exposes the current user's email
final userEmailProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);
  
  if (authState.status == AuthStatus.authenticated) {
    return authService.getUserEmail();
  }
  return null;
});

/// Provider that exposes the current user's name
final userNameProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  final authService = ref.watch(authServiceProvider);
  
  if (authState.status == AuthStatus.authenticated) {
    return authService.getUserName();
  }
  return null;
}); 