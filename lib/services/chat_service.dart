import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/match.dart';
import '../utils/logger.dart';
import '../utils/constants.dart';
import '../config/app_config.dart';
import 'api_client.dart';

class ChatService {
  final Dio _dio;
  final Logger _logger = Logger('ChatService');

  ChatService(this._dio);
  
  // Get matches list
  Future<List<Profile>> getMatches() async {
    _logger.chat('Getting matches...');
    try {
      final response = await _dio.get(AppEndpoints.matches);
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Profile.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load matches (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      _logger.error('Get Matches Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(Constants.ERROR_NETWORK);
      } else if (e.response?.statusCode == 401) {
        throw Exception(Constants.ERROR_UNAUTHORIZED);
      } else {
        throw Exception(Constants.ERROR_CHAT_LOAD);
      }
    } catch (e) {
      _logger.error('Get Matches general error: $e');
      throw Exception(Constants.ERROR_CHAT_LOAD);
    }
  }
  
  /// Get all conversations for the current user
  Future<List<Conversation>> getConversations() async {
    try {
      _logger.info('Fetching conversations');
      final response = await _dio.get(AppEndpoints.conversations);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        return data.map((item) => Conversation.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error fetching conversations: $e');
      // Return empty list on error
      return [];
    }
  }
  
  /// Get all messages for a specific conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      _logger.info('Fetching messages for conversation: $conversationId');
      final response = await _dio.get('${AppEndpoints.messages}?conversation_id=$conversationId');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'] ?? response.data;
        
        // Convert each item to a Message object
        return data.map((item) => Message(
          id: item['id'].toString(),
          conversationId: item['conversation_id'] ?? conversationId,
          senderId: item['sender_id'] ?? '',
          text: item['message'] ?? item['text'] ?? '',
          timestamp: DateTime.tryParse(item['timestamp'] ?? '') ?? DateTime.now(),
          status: item['read'] == true ? MessageStatus.read : MessageStatus.delivered,
          reactions: item['reactions'] != null ? List<String>.from(item['reactions']) : [],
        )).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error fetching messages for conversation $conversationId: $e');
      
      // Return empty list on error - the user can still use socket for real-time
      return [];
    }
  }
  
  /// Send a new message
  /// Note: This is now primarily handled by the socket service
  /// but we keep this as a fallback in case the socket is disconnected
  Future<Message?> sendMessage(String conversationId, String text) async {
    try {
      _logger.info('Sending message to conversation: $conversationId');
      final response = await _dio.post(
        AppEndpoints.messages,
        data: {
          'conversation_id': conversationId,
          'message': text,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;
        
        return Message(
          id: data['id'].toString(),
          conversationId: data['conversation_id'] ?? conversationId,
          senderId: data['sender_id'] ?? '',
          text: data['message'] ?? data['text'] ?? text,
          timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
          status: MessageStatus.sent,
          reactions: [],
        );
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      _logger.error('Error sending message to conversation $conversationId: $e');
      return null;
    }
  }
  
  /// Mark a message as read
  /// Note: This is now primarily handled by the socket service
  /// but we keep this as a fallback in case the socket is disconnected
  Future<bool> markMessageAsRead(String conversationId, String messageId) async {
    try {
      _logger.info('Marking message $messageId as read');
      final response = await _dio.post(
        AppEndpoints.readMessages,
        data: {
          'conversation_id': conversationId,
          'message_id': messageId,
        },
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.error('Error marking message $messageId as read: $e');
      return false;
    }
  }
  
  /// Delete a message
  Future<bool> deleteMessage(String messageId) async {
    try {
      _logger.info('Deleting message: $messageId');
      final response = await _dio.delete(
        '${AppEndpoints.deleteMessage}/$messageId',
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      _logger.error('Error deleting message $messageId: $e');
      return false;
    }
  }
  
  // Create new conversation
  Future<Conversation> createConversation(int userId) async {
    _logger.chat('Creating conversation with user $userId...');
    try {
      final response = await _dio.post(
        '/api/conversations',
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
          error: 'Failed to create conversation (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      _logger.error('Create Conversation Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(Constants.ERROR_NETWORK);
      } else if (e.response?.statusCode == 401) {
        throw Exception(Constants.ERROR_UNAUTHORIZED);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Match not found');
      } else if (e.response?.statusCode == 409) {
        throw Exception('Conversation already exists');
      } else {
        throw Exception('Failed to create conversation. Please try again.');
      }
    } catch (e) {
      _logger.error('Create Conversation general error: $e');
      throw Exception('Failed to create conversation. Please try again.');
    }
  }
  
  // Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _logger.chat('Deleting conversation $conversationId...');
    try {
      final response = await _dio.delete('/api/conversations/$conversationId');
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to delete conversation (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      _logger.error('Delete Conversation Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(Constants.ERROR_NETWORK);
      } else if (e.response?.statusCode == 401) {
        throw Exception(Constants.ERROR_UNAUTHORIZED);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Conversation not found');
      } else {
        throw Exception('Failed to delete conversation. Please try again.');
      }
    } catch (e) {
      _logger.error('Delete Conversation general error: $e');
      throw Exception('Failed to delete conversation. Please try again.');
    }
  }
} 