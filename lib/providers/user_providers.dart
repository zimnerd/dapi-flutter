import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';
import '../services/auth_service.dart';

/// Provider that exposes the current user's ID
final userIdProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserId();
});

/// Provider that exposes the current user's email
final userEmailProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserEmail();
});

/// Provider that exposes the current user's name
final userNameProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserName();
}); 