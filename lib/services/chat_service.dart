import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../utils/constants.dart';
import 'api_config.dart';
import 'api_client.dart';

class ChatService {
  final Dio _dio;

  ChatService(this._dio);
  
  // Get matches list
  Future<List<Profile>> getMatches() async {
    print('⟹ [ChatService] Getting matches...');
    try {
      final response = await _dio.get('/matches');
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Profile.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to load matches (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ChatService] Get Matches Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to load matches';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ChatService] Get Matches general error: $e');
      throw Exception('Error fetching matches: $e');
    }
  }
  
  // Get conversations list
  Future<List<Conversation>> getConversations() async {
    print('⟹ [ChatService] Getting conversations...');
    try {
      final response = await _dio.get('/conversations');
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to load conversations (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ChatService] Get Conversations Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to load conversations';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ChatService] Get Conversations general error: $e');
      throw Exception('Error fetching conversations: $e');
    }
  }
  
  // Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    print('⟹ [ChatService] Getting messages for conversation $conversationId...');
    try {
      final response = await _dio.get('/conversations/$conversationId/messages');
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(conversationId, json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to load messages (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ChatService] Get Messages Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to load messages';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ChatService] Get Messages general error: $e');
      throw Exception('Error fetching messages: $e');
    }
  }
  
  // Send a message
  Future<Message> sendMessage(String conversationId, String text) async {
    print('⟹ [ChatService] Sending message to conversation $conversationId...');
    try {
      final response = await _dio.post(
        '/conversations/$conversationId/messages',
        data: {
          'text': text,
        },
      );
      
      if (response.statusCode == 201 && response.data != null) {
        return Message.fromJson(conversationId, response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to send message (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ChatService] Send Message Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to send message';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ChatService] Send Message general error: $e');
      throw Exception('Error sending message: $e');
    }
  }
  
  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    print('⟹ [ChatService] Marking conversation $conversationId as read...');
    try {
      final response = await _dio.post('/conversations/$conversationId/read');
      
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to mark conversation as read (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ChatService] Mark Read Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to mark read';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ChatService] Mark Read general error: $e');
      throw Exception('Error marking conversation as read: $e');
    }
  }
  
  // Create new conversation
  Future<Conversation> createConversation(int userId) async {
    print('⟹ [ChatService] Creating conversation with user $userId...');
    try {
      final response = await _dio.post(
        '/conversations',
        data: {
          'userId': userId.toString(),
        },
      );
      
      if (response.statusCode == 201 && response.data != null) {
        return Conversation.fromJson(response.data);
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to create conversation (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ChatService] Create Conversation Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to create conversation';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ChatService] Create Conversation general error: $e');
      throw Exception('Error creating conversation: $e');
    }
  }
  
  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    print('⟹ [ChatService] Deleting conversation $conversationId...');
    try {
      final response = await _dio.delete('/conversations/$conversationId');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          message: 'Failed to delete conversation (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      print('⟹ [ChatService] Delete Conversation Dio error: ${e.message}');
      String errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to delete conversation';
      throw Exception(errorMessage);
    } catch (e) {
      print('⟹ [ChatService] Delete Conversation general error: $e');
      throw Exception('Error deleting conversation: $e');
    }
  }
} 