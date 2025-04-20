import 'package:flutter/foundation.dart' show immutable;
import 'package:collection/collection.dart';

@immutable
class Profile {
  final String id;
  final String? userId;
  final String name;
  final DateTime? birthDate;
  final String? gender;
  final List<String> photoUrls;
  final List<String> interests;
  final dynamic location;
  final double? distance;
  final String? occupation;
  final String? education;
  final String? bio;
  final bool isVerified;
  final List<Map<String, String>> prompts;
  final int? minAgePreference;
  final int? maxAgePreference;
  final int? maxDistance;
  final String? genderPreference;
  final List<String> profilePictures;
  final bool isPremium;
  final DateTime lastActive;

  const Profile({
    required this.id,
    this.userId,
    required this.name,
    this.birthDate,
    this.gender,
    required this.photoUrls,
    required this.interests,
    this.location,
    this.distance,
    this.occupation,
    this.education,
    this.bio,
    this.isVerified = false,
    this.prompts = const [],
    this.minAgePreference,
    this.maxAgePreference,
    this.maxDistance,
    this.genderPreference,
    required this.profilePictures,
    required this.isPremium,
    required this.lastActive,
  });

  // Static method to calculate age from birthdate
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  int? get age {
    if (birthDate == null) return null;
    return calculateAge(birthDate!);
  }

  // Factory constructor to create Profile from JSON
  factory Profile.fromJson(Map<String, dynamic> json) {
    // Handle birthDate - can come as String or DateTime
    DateTime? parsedBirthDate;
    if (json['birth_date'] != null) {
      try {
        parsedBirthDate = DateTime.parse(json['birth_date'].toString());
      } catch (e) {
        print('Error parsing birth_date: $e');
      }
    } else if (json['birthDate'] != null) {
      try {
        parsedBirthDate = DateTime.parse(json['birthDate'].toString());
      } catch (e) {
        print('Error parsing birthDate: $e');
      }
    }

    // Handle photos which might be under 'photos' or 'photoUrls'
    List<String> photos = [];
    if (json['photos'] != null) {
      try {
        if (json['photos'] is List) {
          photos = (json['photos'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        }
      } catch (e) {
        print('Error parsing photos: $e');
      }
    } else if (json['photoUrls'] != null) {
      try {
        if (json['photoUrls'] is List) {
          photos = (json['photoUrls'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        }
      } catch (e) {
        print('Error parsing photoUrls: $e');
      }
    } else if (json['photo_urls'] != null) {
      try {
        if (json['photo_urls'] is List) {
          photos = (json['photo_urls'] as List<dynamic>)
              .map((e) => e.toString())
              .toList();
        }
      } catch (e) {
        print('Error parsing photo_urls: $e');
      }
    }

    // Handle interests which might be under different keys
    List<String> parsedInterests = [];
    if (json['interests'] != null) {
      parsedInterests = (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
    }

    // Handle prompts
    List<Map<String, String>> promptsList = [];
    if (json['prompts'] != null) {
      try {
        promptsList = (json['prompts'] as List<dynamic>?)
                ?.map((e) => Map<String, String>.from(e as Map))
                .toList() ??
            [];
      } catch (e) {
        print('Error parsing prompts: $e');
      }
    }

    return Profile(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      name: json['name']?.toString() ?? '',
      birthDate: parsedBirthDate,
      gender: json['gender']?.toString(),
      photoUrls: photos,
      interests: parsedInterests,
      location: json['location'],
      distance: json['distance'] != null
          ? double.tryParse(json['distance'].toString())
          : null,
      occupation: json['occupation']?.toString(),
      education: json['education']?.toString(),
      bio: json['bio']?.toString(),
      isVerified: json['is_verified'] == true || json['isVerified'] == true,
      prompts: promptsList,
      minAgePreference: json['min_age_preference'] != null
          ? int.tryParse(json['min_age_preference'].toString())
          : json['minAgePreference'] != null
              ? int.tryParse(json['minAgePreference'].toString())
              : null,
      maxAgePreference: json['max_age_preference'] != null
          ? int.tryParse(json['max_age_preference'].toString())
          : json['maxAgePreference'] != null
              ? int.tryParse(json['maxAgePreference'].toString())
              : null,
      maxDistance: json['max_distance'] != null
          ? int.tryParse(json['max_distance'].toString())
          : json['maxDistance'] != null
              ? int.tryParse(json['maxDistance'].toString())
              : null,
      genderPreference: json['gender_preference']?.toString() ??
          json['genderPreference']?.toString(),
      profilePictures: photos,
      isPremium: json['isPremium'] as bool? ?? false,
      lastActive: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  // Convert Profile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'birth_date': birthDate?.toIso8601String(),
      'gender': gender,
      'photo_urls': photoUrls,
      'interests': interests,
      'location': location,
      'distance': distance,
      'occupation': occupation,
      'education': education,
      'bio': bio,
      'is_verified': isVerified,
      'prompts': prompts,
      'min_age_preference': minAgePreference,
      'max_age_preference': maxAgePreference,
      'max_distance': maxDistance,
      'gender_preference': genderPreference,
      'profilePictures': profilePictures,
      'isPremium': isPremium,
      'lastActive': lastActive.toIso8601String(),
    };
  }

  // Copy with method for immutable updates
  Profile copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? birthDate,
    String? gender,
    List<String>? photoUrls,
    List<String>? interests,
    dynamic location,
    double? distance,
    String? occupation,
    String? education,
    String? bio,
    bool? isVerified,
    List<Map<String, String>>? prompts,
    int? minAgePreference,
    int? maxAgePreference,
    int? maxDistance,
    String? genderPreference,
    List<String>? profilePictures,
    bool? isPremium,
    DateTime? lastActive,
  }) {
    return Profile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      photoUrls: photoUrls ?? this.photoUrls,
      interests: interests ?? this.interests,
      location: location ?? this.location,
      distance: distance ?? this.distance,
      occupation: occupation ?? this.occupation,
      education: education ?? this.education,
      bio: bio ?? this.bio,
      isVerified: isVerified ?? this.isVerified,
      prompts: prompts ?? this.prompts,
      minAgePreference: minAgePreference ?? this.minAgePreference,
      maxAgePreference: maxAgePreference ?? this.maxAgePreference,
      maxDistance: maxDistance ?? this.maxDistance,
      genderPreference: genderPreference ?? this.genderPreference,
      profilePictures: profilePictures ?? this.profilePictures,
      isPremium: isPremium ?? this.isPremium,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;
    final mapEquals = const DeepCollectionEquality().equals;

    return other is Profile &&
        other.id == id &&
        other.userId == userId &&
        other.name == name &&
        other.birthDate == birthDate &&
        other.gender == gender &&
        listEquals(other.photoUrls, photoUrls) &&
        listEquals(other.interests, interests) &&
        other.location == location &&
        other.distance == distance &&
        other.occupation == occupation &&
        other.education == education &&
        other.bio == bio &&
        other.isVerified == isVerified &&
        listEquals(other.prompts, prompts) &&
        other.minAgePreference == minAgePreference &&
        other.maxAgePreference == maxAgePreference &&
        other.maxDistance == maxDistance &&
        other.genderPreference == genderPreference &&
        listEquals(other.profilePictures, profilePictures) &&
        other.isPremium == isPremium &&
        other.lastActive == lastActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      bio,
      age,
      gender,
      Object.hashAll(interests),
      location,
      minAgePreference,
      maxAgePreference,
      maxDistance,
      genderPreference,
      Object.hashAll(profilePictures),
      isPremium,
      lastActive,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, name: $name, age: $age, gender: $gender, location: $location, isPremium: $isPremium)';
  }
}
