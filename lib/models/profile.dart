import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Map<String, dynamic>? location;
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
    // Handle potential null/type variations from different API responses
    final id = json['id']?.toString() ?? '';
    
    // Handle birthDate - can come as String or DateTime
    DateTime? parsedBirthDate;
    if (json['birth_date'] != null) {
      // Try to parse the birth_date from string 
      try {
        parsedBirthDate = DateTime.parse(json['birth_date'].toString());
      } catch (e) {
        print('Error parsing birth_date: $e');
      }
    } else if (json['birthDate'] != null) {
      // Try alternative key
      try {
        parsedBirthDate = DateTime.parse(json['birthDate'].toString());
      } catch (e) {
        print('Error parsing birthDate: $e');
      }
    }

    // Handle photos which might be under 'photos' or 'photoUrls'
    List<String> photos = [];
    if (json['photos'] != null) {
      photos = (json['photos'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
    } else if (json['photoUrls'] != null) {
      photos = (json['photoUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
    } else if (json['photo_urls'] != null) {
      photos = (json['photo_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
    }

    // Handle interests which might be under different keys
    List<String> parsedInterests = [];
    if (json['interests'] != null) {
      parsedInterests = (json['interests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? [];
    }

    // Handle location - could be a string or a map
    Map<String, dynamic>? locationMap;
    if (json['location'] is Map) {
      locationMap = json['location'] as Map<String, dynamic>;
    } else if (json['location'] is String) {
      locationMap = {'city': json['location'], 'country': ''};
    }

    // Handle prompts
    List<Map<String, String>> promptsList = [];
    if (json['prompts'] != null) {
      try {
        promptsList = (json['prompts'] as List<dynamic>?)
            ?.map((e) => Map<String, String>.from(e as Map))
            .toList() ?? [];
      } catch (e) {
        print('Error parsing prompts: $e');
      }
    }

    return Profile(
      id: id,
      userId: json['user_id']?.toString() ?? json['userId']?.toString(),
      name: json['name']?.toString() ?? '',
      birthDate: parsedBirthDate,
      gender: json['gender']?.toString(),
      photoUrls: photos,
      interests: parsedInterests,
      location: locationMap,
      distance: json['distance'] != null ? double.tryParse(json['distance'].toString()) : null,
      occupation: json['occupation']?.toString(),
      education: json['education']?.toString(),
      bio: json['bio']?.toString(),
      isVerified: json['is_verified'] == true || json['isVerified'] == true,
      prompts: promptsList,
      minAgePreference: json['min_age_preference'] != null ? int.tryParse(json['min_age_preference'].toString()) : 
                         json['minAgePreference'] != null ? int.tryParse(json['minAgePreference'].toString()) : null,
      maxAgePreference: json['max_age_preference'] != null ? int.tryParse(json['max_age_preference'].toString()) : 
                         json['maxAgePreference'] != null ? int.tryParse(json['maxAgePreference'].toString()) : null,
      maxDistance: json['max_distance'] != null ? int.tryParse(json['max_distance'].toString()) : 
                    json['maxDistance'] != null ? int.tryParse(json['maxDistance'].toString()) : null,
      genderPreference: json['gender_preference']?.toString() ?? json['genderPreference']?.toString(),
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
    Map<String, dynamic>? location,
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
        mapEquals(other.location, location) &&
        other.distance == distance &&
        other.occupation == occupation &&
        other.education == education &&
        other.bio == bio &&
        other.isVerified == isVerified &&
        listEquals(other.prompts, prompts) &&
        other.minAgePreference == minAgePreference &&
        other.maxAgePreference == maxAgePreference &&
        other.maxDistance == maxDistance &&
        other.genderPreference == genderPreference;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      name,
      birthDate,
      gender,
      Object.hashAll(photoUrls),
      Object.hashAll(interests),
      location,
      distance,
      occupation,
      education,
      bio,
      isVerified,
      Object.hashAll(prompts),
      minAgePreference,
      maxAgePreference,
      maxDistance,
      genderPreference,
    );
  }
}