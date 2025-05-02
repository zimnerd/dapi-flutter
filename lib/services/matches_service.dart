import 'package:dating_app/services/api_client.dart';

enum MatchStatus {
  pending,
  accepted,
  rejected,
  expired,
}

class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final MatchStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'],
      user1Id: json['user1Id'],
      user2Id: json['user2Id'],
      status: MatchStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  bool isMatch(String userId) => user1Id == userId || user2Id == userId;
  String getOtherUserId(String userId) => user1Id == userId ? user2Id : user1Id;
}

class MatchesService {
  final ApiClient _apiClient;

  MatchesService(this._apiClient);

  Future<List<Match>> getAllMatches() async {
    final response = await _apiClient.get('/matches');
    return (response.data as List).map((json) => Match.fromJson(json)).toList();
  }

  Future<List<Match>> getPendingMatches() async {
    final response = await _apiClient.get('/matches/pending');
    return (response.data as List).map((json) => Match.fromJson(json)).toList();
  }

  Future<Match> updateMatchStatus(String matchId, MatchStatus status) async {
    final response = await _apiClient.put(
      '/matches/$matchId/status',
      data: {'status': status.toString().split('.').last},
    );
    return Match.fromJson(response.data);
  }

  Future<void> deleteMatch(String matchId) async {
    await _apiClient.delete('/matches/$matchId');
  }

  // Helper method to get matches with a specific user
  Future<List<Match>> getMatchesWithUser(String userId) async {
    final allMatches = await getAllMatches();
    return allMatches.where((match) => match.isMatch(userId)).toList();
  }

  // Helper method to check if there's a match with a specific user
  Future<bool> hasMatchWithUser(String userId) async {
    final matches = await getMatchesWithUser(userId);
    return matches.isNotEmpty;
  }

  // Fetch match connections (matches with conversations)
  Future<List<Match>> getConnections() async {
    final response = await _apiClient.get('/matches/connections');
    return (response.data as List).map((json) => Match.fromJson(json)).toList();
  }

  // Like a profile
  Future<Match?> likeProfile(String profileId) async {
    try {
      final response = await _apiClient
          .post('/matches/like', data: {'profileId': profileId});
      return Match.fromJson(response.data);
    } catch (e) {
      // Handle 409 or already liked gracefully
      return null;
    }
  }

  // Pass on a profile
  Future<Match?> passProfile(String profileId) async {
    try {
      final response = await _apiClient
          .post('/matches/pass', data: {'profileId': profileId});
      return Match.fromJson(response.data);
    } catch (e) {
      // Handle 409 or already passed gracefully
      return null;
    }
  }
}
