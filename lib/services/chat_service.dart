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
  
  // Get conversations list
  Future<List<Conversation>> getConversations() async {
    _logger.chat('Getting conversations...');
    try {
      final response = await _dio.get(AppEndpoints.conversations);
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Conversation.fromJson(json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load conversations (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      _logger.error('Get Conversations Dio error: ${e.message}');
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
      _logger.error('Get Conversations general error: $e');
      throw Exception(Constants.ERROR_CHAT_LOAD);
    }
  }
  
  // Get messages for a conversation
  Future<List<Message>> getMessages(String conversationId) async {
    _logger.chat('Getting messages for conversation $conversationId...');
    try {
      final response = await _dio.get('/api/conversations/$conversationId/messages');
      
      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(conversationId, json)).toList();
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to load messages (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      _logger.error('Get Messages Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(Constants.ERROR_NETWORK);
      } else if (e.response?.statusCode == 401) {
        throw Exception(Constants.ERROR_UNAUTHORIZED);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Conversation not found');
      } else {
        throw Exception(Constants.ERROR_CHAT_LOAD);
      }
    } catch (e) {
      _logger.error('Get Messages general error: $e');
      throw Exception(Constants.ERROR_CHAT_LOAD);
    }
  }
  
  // Send a message
  Future<Message> sendMessage(String conversationId, String text) async {
    _logger.chat('Sending message to conversation $conversationId...');
    try {
      final response = await _dio.post(
        '/api/conversations/$conversationId/messages',
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
          error: 'Failed to send message (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      _logger.error('Send Message Dio error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw Exception(Constants.ERROR_NETWORK);
      } else if (e.response?.statusCode == 401) {
        throw Exception(Constants.ERROR_UNAUTHORIZED);
      } else if (e.response?.statusCode == 404) {
        throw Exception('Conversation not found');
      } else {
        throw Exception('Failed to send message. Please try again.');
      }
    } catch (e) {
      _logger.error('Send Message general error: $e');
      throw Exception('Failed to send message. Please try again.');
    }
  }
  
  // Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    _logger.chat('Marking conversation $conversationId as read...');
    try {
      final response = await _dio.post('/api/conversations/$conversationId/read');
      
      if (response.statusCode != 200) {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to mark conversation as read (status ${response.statusCode})',
        );
      }
    } on DioException catch (e) {
      _logger.error('Mark Read Dio error: ${e.message}');
      // Not throwing here to prevent UI disruption over non-critical operation
    } catch (e) {
      _logger.error('Mark Read general error: $e');
      // Not throwing here to prevent UI disruption over non-critical operation
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