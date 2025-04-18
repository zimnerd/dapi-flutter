import 'dart:convert';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class SubscriptionService {
  // Create Dio instance directly
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: Duration(milliseconds: AppConfig.networkTimeoutMs),
    receiveTimeout: Duration(milliseconds: AppConfig.networkTimeoutMs),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));
  final StorageService _storageService = StorageService();
  
  /// Check if the user has premium status
  /// Returns true if user has premium subscription, false otherwise
  Future<bool> checkPremiumStatus() async {
    try {
      print('⟹ [SubscriptionService] Checking premium status');
      
      // Try to get from local storage first for quicker response
      final cachedStatus = await _storageService.read('premium_status');
      if (cachedStatus != null) {
        print('⟹ [SubscriptionService] Found cached premium status: $cachedStatus');
        return cachedStatus == 'true';
      }
      
      // If not in storage, check with the API
      final response = await _dio.get('/api/users/me');
      
      if (response.statusCode == 200 && response.data != null) {
        final userData = response.data;
        
        // Check if user has premium role or subscription
        final isPremium = 
            userData['role'] == 'premium' || 
            (userData['subscription'] != null && 
             userData['subscription']['status'] == 'active');
        
        // Cache the result
        await _storageService.write('premium_status', isPremium.toString());
        
        print('⟹ [SubscriptionService] Premium status from API: $isPremium');
        return isPremium;
      }
      
      print('⟹ [SubscriptionService] No premium data found, defaulting to false');
      return false;
    } catch (e) {
      print('⟹ [SubscriptionService] Error checking premium status: $e');
      
      // For demo purposes, check if we have mock data enabled
      final useMock = await _storageService.read('use_mock_data');
      if (useMock == 'true') {
        print('⟹ [SubscriptionService] Using mock premium status');
        return false; // Default mock value
      }
      
      return false;
    }
  }
  
  /// Subscribe user to premium plan
  /// Returns true if subscription was successful
  Future<bool> subscribeToPremium(String planId) async {
    try {
      print('⟹ [SubscriptionService] Subscribing to premium plan: $planId');
      
      // In a real app, this would connect to a payment processor
      // For this demo, we'll simulate a successful subscription
      
      final response = await _dio.post(
        '/api/subscriptions',
        data: {
          'planId': planId,
          'paymentMethod': 'card',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update the local cache
        await _storageService.write('premium_status', 'true');
        print('⟹ [SubscriptionService] Successfully subscribed to premium');
        return true;
      }
      
      print('⟹ [SubscriptionService] Failed to subscribe: ${response.statusCode}');
      return false;
    } catch (e) {
      print('⟹ [SubscriptionService] Error subscribing to premium: $e');
      
      // For demo purposes, simulate successful subscription
      final useMock = await _storageService.read('use_mock_data');
      if (useMock == 'true') {
        await _storageService.write('premium_status', 'true');
        print('⟹ [SubscriptionService] Mock subscription successful');
        return true;
      }
      
      return false;
    }
  }
  
  /// Cancel premium subscription
  /// Returns true if cancellation was successful
  Future<bool> cancelSubscription() async {
    try {
      print('⟹ [SubscriptionService] Cancelling subscription');
      
      final response = await _dio.delete('/api/subscriptions/current');
      
      if (response.statusCode == 200) {
        // Update the local cache
        await _storageService.write('premium_status', 'false');
        print('⟹ [SubscriptionService] Successfully cancelled subscription');
        return true;
      }
      
      print('⟹ [SubscriptionService] Failed to cancel: ${response.statusCode}');
      return false;
    } catch (e) {
      print('⟹ [SubscriptionService] Error cancelling subscription: $e');
      
      // For demo purposes
      final useMock = await _storageService.read('use_mock_data');
      if (useMock == 'true') {
        await _storageService.write('premium_status', 'false');
        print('⟹ [SubscriptionService] Mock cancellation successful');
        return true;
      }
      
      return false;
    }
  }
  
  /// Get available subscription plans
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    try {
      print('⟹ [SubscriptionService] Getting subscription plans');
      
      final response = await _dio.get('/api/subscription-plans');
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> plans = response.data;
        print('⟹ [SubscriptionService] Found ${plans.length} plans');
        return plans.cast<Map<String, dynamic>>();
      }
      
      throw Exception('Failed to load subscription plans');
    } catch (e) {
      print('⟹ [SubscriptionService] Error getting subscription plans: $e');
      
      // Return mock plans for demo
      return [
        {
          'id': 'monthly',
          'name': 'Monthly',
          'price': 9.99,
          'interval': 'month',
          'features': ['unlimited_swipes', 'see_likes', 'global_mode']
        },
        {
          'id': 'yearly',
          'name': 'Yearly',
          'price': 79.99,
          'interval': 'year',
          'features': ['unlimited_swipes', 'see_likes', 'global_mode', 'rewind', 'priority_matching'],
          'savings': '33%'
        },
      ];
    }
  }
} 