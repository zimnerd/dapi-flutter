import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_client.dart';
import '../services/chat_service.dart';
import 'providers.dart';

// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  // Get Dio instance from dioProvider
  final dio = ref.watch(dioProvider);
  
  // Create and return a new ChatService with the Dio instance
  return ChatService(dio);
}); 