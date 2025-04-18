// Login Response Models for the Dating App API
import 'profile.dart'; // Import the main Profile model

class LoginResponse {
  final String message;
  final LoginData data;
  
  LoginResponse({required this.message, required this.data});
  
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      data: LoginData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

class LoginData {
  final UserData user;
  final Profile profile;
  final String token;
  final String refreshToken;
  
  LoginData({
    required this.user,
    required this.profile,
    required this.token,
    required this.refreshToken,
  });
  
  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: UserData.fromJson(json['user'] as Map<String, dynamic>),
      profile: Profile.fromJson(json['profile'] as Map<String, dynamic>),
      token: json['token'] ?? '',
      refreshToken: json['refreshToken'] ?? json['refresh_token'] ?? '',
    );
  }
}

// Renamed from User to UserData to avoid conflicts
class UserData {
  final String id;
  final String email;
  final String name;
  
  UserData({
    required this.id,
    required this.email,
    required this.name,
  });
  
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class Profile {
  final String id;
  final String userId;
  final String name;
  final String birthDate;
  final String gender;
  final String bio;
  final String location;
  final int minAgePreference;
  final int maxAgePreference;
  final int maxDistance;
  final String createdAt;
  final String updatedAt;
  
  Profile({
    required this.id,
    required this.userId,
    required this.name,
    required this.birthDate,
    required this.gender,
    required this.bio,
    required this.location,
    required this.minAgePreference,
    required this.maxAgePreference,
    required this.maxDistance,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? '',
      birthDate: json['birth_date'] ?? '',
      gender: json['gender'] ?? '',
      bio: json['bio'] ?? '',
      location: json['location'] ?? '',
      minAgePreference: json['min_age_preference'] ?? 18,
      maxAgePreference: json['max_age_preference'] ?? 50,
      maxDistance: json['max_distance'] ?? 50,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
} 