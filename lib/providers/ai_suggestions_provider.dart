import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/chat_service.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../providers/chat_message_actions.dart';
import '../providers/providers.dart'; // To access authServiceProvider

// Provider for AI icebreaker suggestions from server
final icebreakerSuggestionsProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, conversationId) async {
  // Get auth service for authentication
  final authService = ref.read(authServiceProvider);

  try {
    print("Fetching AI Icebreaker suggestions for: $conversationId");

    // Using Dio directly since this might be a separate endpoint
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.networkTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Try to get auth token
    final token = await authService.getAccessToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    // Call the API - replace with your actual endpoint
    final response = await dio.get(
      '${AppEndpoints.conversations}/$conversationId/icebreakers',
    );

    if (response.statusCode == 200) {
      // Extract suggestions from response
      final List<dynamic> data = response.data['data'] ?? response.data ?? [];
      return data.map((item) => item.toString()).toList();
    } else {
      print("Failed to fetch AI suggestions: ${response.statusCode}");
      // Fallback to default suggestions if server request fails
      return _getDefaultSuggestions();
    }
  } catch (e) {
    print("Error fetching AI suggestions: $e");
    // Return fallback suggestions
    return _getDefaultSuggestions();
  }
});

// Fallback suggestions when server is unavailable
List<String> _getDefaultSuggestions() {
  return [
    "What's been the highlight of your week so far? ✨",
    "If you could have any superpower, what would it be? 🦸",
    "Spotted something interesting in your profile! Tell me more?",
    "Pineapple on pizza: Yes or No? 🍍🍕",
    "What's one song you have on repeat right now? 🎶",
  ];
}

// Provider for Profile Optimization Tips
final profileOptimizationTipsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  // Get auth service for authentication
  final authService = ref.read(authServiceProvider);

  try {
    print("Fetching AI Profile Optimization Tips...");

    // Using Dio directly since this might be a separate endpoint
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConfig.networkTimeoutMs),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Try to get auth token
    final token = await authService.getAccessToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    // Call the API - replace with your actual endpoint
    final response = await dio.get(
      '/api/profiles/me/tips', // Use direct path instead of missing endpoint
    );

    if (response.statusCode == 200) {
      // Extract tips from response
      final List<dynamic> data = response.data['data'] ?? response.data ?? [];
      return data.map((item) => item.toString()).toList();
    } else {
      print("Failed to fetch profile tips: ${response.statusCode}");
      // Fallback to default tips if server request fails
      return _getDefaultProfileTips();
    }
  } catch (e) {
    print("Error fetching profile tips: $e");
    // Return fallback tips
    return _getDefaultProfileTips();
  }
});

// Fallback profile tips when server is unavailable
List<String> _getDefaultProfileTips() {
  return [
    "Your first photo is great! Adding one more showing an activity you enjoy could boost interest.",
    "Consider answering the 'Two truths and a lie' prompt - it's a great conversation starter!",
    "Mentioning specific goals in your bio can help attract like-minded people.",
  ];
}
