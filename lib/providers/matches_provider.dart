import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/match.dart';
import '../services/api_client.dart';
import '../models/profile.dart';

final matchesProvider =
    StateNotifierProvider<MatchesNotifier, AsyncValue<List<Match>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MatchesNotifier(apiClient);
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
  final ApiClient _apiClient;

  MatchesNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    loadMatches();
  }

  Future<void> loadMatches() async {
    try {
      state = const AsyncValue.loading();
      final matches = await _apiClient.getMatches();
      state = AsyncValue.data(matches);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
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
      final newMatches = await _apiClient.getNewMatches();
      state = AsyncValue.data(newMatches);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
