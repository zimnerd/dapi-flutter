import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import '../utils/exceptions.dart';
import '../utils/constants.dart';
import '../providers/providers.dart';

final profileActionsServiceProvider = Provider<ProfileActionsService>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileActionsService(dio);
});

class ProfileAction {
  final String id;
  final String profileId;
  final String actionType; // block, report
  final String? reason;
  final DateTime createdAt;

  ProfileAction({
    required this.id,
    required this.profileId,
    required this.actionType,
    this.reason,
    required this.createdAt,
  });

  factory ProfileAction.fromJson(Map<String, dynamic> json) {
    return ProfileAction(
      id: json['id'] ?? '',
      profileId: json['profile_id'] ?? '',
      actionType: json['action_type'] ?? '',
      reason: json['reason'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}

class ProfileActionsService {
  final Dio _dio;
  final _logger = Logger('ProfileActions');

  ProfileActionsService(this._dio);

  // Block or report a profile
  Future<ProfileAction> actionProfile({
    required String profileId,
    required String actionType,
    String? reason,
  }) async {
    _logger.debug('Taking action on profile $profileId: $actionType');

    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/profile-actions',
        data: {
          'profile_id': profileId,
          'action_type': actionType,
          if (reason != null) 'reason': reason,
        },
      );

      if (response.statusCode == 201 && response.data != null) {
        Map<String, dynamic> actionData;

        if (response.data is Map && response.data['data'] != null) {
          actionData = response.data['data'];
        } else if (response.data is Map) {
          actionData = response.data;
        } else {
          _logger.error(
              'Unexpected profile action response format: ${response.data.runtimeType}');
          throw ApiException('Unexpected response format');
        }

        _logger.info('Profile action successful: $actionType on $profileId');
        return ProfileAction.fromJson(actionData);
      } else {
        _logger.warn('Profile action failed: ${response.statusCode}');
        throw ApiException(
          response.data?['message'] ?? 'Failed to perform action',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error during profile action: ${e.message}');
      _handleDioError(e, defaultMessage: 'Failed to perform action');
      rethrow;
    } catch (e, s) {
      _logger.error('Error during profile action: $e', e, s);
      throw ApiException(Constants.errorGeneric);
    }
  }

  // Undo a profile action
  Future<bool> undoAction(String actionId) async {
    _logger.debug('Undoing profile action: $actionId');

    try {
      final response = await _dio.post(
        '${AppConfig.apiBaseUrl}/profile-actions/undo',
        data: {
          'action_id': actionId,
        },
      );

      if (response.statusCode == 200) {
        _logger.info('Successfully undid profile action: $actionId');
        return true;
      } else {
        _logger.warn('Failed to undo profile action: ${response.statusCode}');
        throw ApiException(
          response.data?['message'] ?? 'Failed to undo action',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error undoing profile action: ${e.message}');
      _handleDioError(e, defaultMessage: 'Failed to undo action');
      rethrow;
    } catch (e, s) {
      _logger.error('Error undoing profile action: $e', e, s);
      throw ApiException(Constants.errorGeneric);
    }
  }

  // Get profile action history
  Future<List<ProfileAction>> getActionHistory({
    int? limit,
    int? page,
    String? actionType,
  }) async {
    _logger.debug(
        'Getting profile action history: limit=$limit, page=$page, type=$actionType');

    try {
      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (page != null) queryParams['page'] = page;
      if (actionType != null) queryParams['type'] = actionType;

      final response = await _dio.get(
        '${AppConfig.apiBaseUrl}/profile-actions/history',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> actionsJson;

        if (response.data is List) {
          actionsJson = response.data;
        } else if (response.data is Map && response.data['data'] != null) {
          actionsJson = response.data['data'];
        } else {
          _logger.error(
              'Unexpected action history response format: ${response.data.runtimeType}');
          throw ApiException('Unexpected response format');
        }

        final actions =
            actionsJson.map((json) => ProfileAction.fromJson(json)).toList();
        _logger
            .info('Successfully retrieved ${actions.length} profile actions');
        return actions;
      } else {
        _logger.warn('Failed to get action history: ${response.statusCode}');
        throw ApiException(
          response.data?['message'] ?? 'Failed to get action history',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      _logger.error('Dio error getting action history: ${e.message}');
      _handleDioError(e, defaultMessage: 'Failed to get action history');

      if (kDebugMode) {
        _logger.debug('Returning mock action history in debug mode');
        return List.generate(3, (index) => _generateMockAction(index));
      } else {
        rethrow;
      }
    } catch (e, s) {
      _logger.error('Error getting action history: $e', e, s);

      if (kDebugMode) {
        _logger.debug('Returning mock action history in debug mode');
        return List.generate(3, (index) => _generateMockAction(index));
      } else {
        throw ApiException(Constants.errorGeneric);
      }
    }
  }

  // Helper method to handle Dio errors
  void _handleDioError(DioException e, {required String defaultMessage}) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode ?? 500;
      String message = defaultMessage;

      if (e.response!.data is Map) {
        message = e.response!.data['message'] ?? defaultMessage;
      }

      throw ApiException(message, statusCode: statusCode);
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw ApiException(Constants.errorNetworkTimeout);
    } else if (e.type == DioExceptionType.connectionError) {
      throw ApiException(Constants.errorNetwork);
    } else {
      throw ApiException(defaultMessage);
    }
  }

  // Generate mock action for debugging
  ProfileAction _generateMockAction(int index) {
    final actionTypes = ['block', 'report'];
    final now = DateTime.now();

    return ProfileAction(
      id: 'action-${100 + index}',
      profileId: 'profile-${200 + index}',
      actionType: actionTypes[index % actionTypes.length],
      reason: index % 2 == 0 ? 'Inappropriate behavior' : null,
      createdAt: now.subtract(Duration(days: index)),
    );
  }
}
