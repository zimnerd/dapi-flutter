import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/services/matches_service.dart' as service;
import 'package:dating_app/services/api_client.dart';
import 'package:dating_app/services/profile_service.dart';
import '../models/profile.dart';
import 'package:dating_app/providers/providers.dart'
    show profileServiceProvider, userIdProvider;
import '../utils/logger.dart';

final Logger _logger = Logger('MatchesProvider');

final matchesServiceProvider = Provider<service.MatchesService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return service.MatchesService(apiClient);
});

final matchesProvider =
    StateNotifierProvider<MatchesNotifier, AsyncValue<List<Match>>>((ref) {
  final service = ref.watch(matchesServiceProvider);
  final profileService = ref.watch(profileServiceProvider);
  final userId = ref.watch(userIdProvider);
  return MatchesNotifier(service, profileService, userId);
});

final likesProvider =
    StateNotifierProvider<LikesNotifier, AsyncValue<List<Profile>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LikesNotifier(apiClient);
});

final newMatchesProvider =
    StateNotifierProvider<NewMatchesNotifier, AsyncValue<List<Match>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NewMatchesNotifier(apiClient);
});

class MatchesNotifier extends StateNotifier<AsyncValue<List<Match>>> {
  final service.MatchesService _service;
  final ProfileService _profileService;
  final String? _userId;

  MatchesNotifier(this._service, this._profileService, this._userId)
      : super(const AsyncValue.loading()) {
    loadMatches();
  }

  String? _getCurrentUserId() {
    return _userId;
  }

  Future<Match?> _convertServiceMatch(
      service.Match serviceMatch, String currentUserId) async {
    try {
      // Get the other user's profile
      final otherUserId = serviceMatch.getOtherUserId(currentUserId);
      final profile = await _profileService.getProfile(otherUserId);

      if (profile == null) return null;

      return Match(
        id: serviceMatch.id,
        matchedUser: profile,
        matchedAt: serviceMatch.createdAt,
        isNew: serviceMatch.status == service.MatchStatus.pending,
        // These will be populated when we implement chat functionality
        lastMessage: null,
        lastMessageAt: null,
      );
    } catch (e) {
      _logger.error('[MatchesNotifier] Error converting match: $e');
      return null;
    }
  }

  Future<void> loadMatches() async {
    try {
      state = const AsyncValue.loading();
      final serviceMatches = await _service.getAllMatches();
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final convertedMatches = await Future.wait(
          serviceMatches.map((m) => _convertServiceMatch(m, currentUserId)));
      state = AsyncValue.data(convertedMatches.whereType<Match>().toList());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> loadPendingMatches() async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) {
        _logger.warn('[MatchesNotifier] No current user ID found');
        state = AsyncValue.data([]);
        return;
      }

      final serviceMatches = await _service.getPendingMatches();
      final convertedMatches = await Future.wait(
          serviceMatches.map((m) => _convertServiceMatch(m, currentUserId)));

      state = AsyncValue.data(convertedMatches.whereType<Match>().toList());
    } catch (e) {
      _logger.error('[MatchesNotifier] Error loading pending matches: $e');
    }
  }

  Future<void> updateMatchStatus(
      String matchId, service.MatchStatus status) async {
    try {
      await _service.updateMatchStatus(matchId, status);
      await loadMatches(); // Reload matches after update
    } catch (e) {
      _logger.error('[MatchesNotifier] Failed to update match status: $e');
    }
  }

  Future<void> deleteMatch(String matchId) async {
    try {
      await _service.deleteMatch(matchId);
      state = AsyncValue.data(
          state.value!.where((match) => match.id != matchId).toList());
    } catch (e) {
      _logger.error('[MatchesNotifier] Failed to delete match: $e');
    }
  }

  Future<bool> hasMatchWithUser(String userId) async {
    return await _service.hasMatchWithUser(userId);
  }

  Future<List<Match>> getMatchesWithUser(String userId) async {
    try {
      final currentUserId = _getCurrentUserId();
      if (currentUserId == null) return [];

      final serviceMatches = await _service.getMatchesWithUser(userId);
      final convertedMatches = await Future.wait(
          serviceMatches.map((m) => _convertServiceMatch(m, currentUserId)));

      return convertedMatches.whereType<Match>().toList();
    } catch (e) {
      _logger.error('[MatchesNotifier] Failed to get matches with user: $e');
      return [];
    }
  }
}

class LikesNotifier extends StateNotifier<AsyncValue<List<Profile>>> {
  final ApiClient _apiClient;

  LikesNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadLikes();
  }

  Future<void> loadLikes() async {
    try {
      state = const AsyncValue.loading();
      final likes = await _apiClient.getLikes();
      state = AsyncValue.data(likes);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

class NewMatchesNotifier extends StateNotifier<AsyncValue<List<Match>>> {
  final ApiClient _apiClient;

  NewMatchesNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadNewMatches();
  }

  Future<void> loadNewMatches() async {
    try {
      state = const AsyncValue.loading();
      final response = await _apiClient.get('/matches/new');
      final matches =
          (response as List).map((data) => Match.fromJson(data)).toList();
      state = AsyncValue.data(matches);
    } catch (e) {
      _logger.error('[NewMatchesNotifier] Failed to load new matches: $e');
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
