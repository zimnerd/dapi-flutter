import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' as foundation;

class Profile {
  final int id;
  final String name;
  final int age;
  final String gender;
  final String? bio;
  final List<String> photoUrls;
  final String? profileImageUrl;
  final String? occupation;
  final String? education;
  final double? distance;
  final List<String> interests;
  final bool isOnline;
  final DateTime birthDate;
  final String? location;
  final int minAgePreference;
  final int maxAgePreference;
  final double maxDistance;
  final String? genderPreference;
  final bool? isVerified;
  final Map<String, String>? prompts;
  final String? videoIntroUrl;
  final String? audioIntroUrl;

  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    this.bio,
    required this.photoUrls,
    this.profileImageUrl,
    this.occupation,
    this.education,
    this.distance,
    required this.interests,
    this.isOnline = false,
    required this.birthDate,
    this.location,
    this.minAgePreference = 18,
    this.maxAgePreference = 50,
    this.maxDistance = 50.0,
    this.genderPreference,
    this.isVerified,
    this.prompts,
    this.videoIntroUrl,
    this.audioIntroUrl,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    // Handle ID which could be an int or string
    int id;
    if (json['id'] is int) {
      id = json['id'];
    } else if (json['id'] is String) {
      id = int.tryParse(json['id']) ?? 0;
    } else {
      id = 0;
    }
    
    // Handle age
    int age;
    if (json['age'] is int) {
      age = json['age'];
    } else if (json['age'] is String) {
      age = int.tryParse(json['age']) ?? 0;
    } else if (json['birth_date'] != null) {
      // Calculate age from birth date
      final birthDate = DateTime.parse(json['birth_date']);
      final today = DateTime.now();
      age = today.year - birthDate.year;
      if (today.month < birthDate.month || 
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
    } else {
      age = 0;
    }
    
    // Handle photos, which could be a list or a single string, assign to photoUrls
    List<String> photoUrls = [];
    if (json['photos'] != null) {
      if (json['photos'] is List) {
        photoUrls = (json['photos'] as List).map((e) => e.toString()).toList();
      } else if (json['photos'] is String) {
        photoUrls = [json['photos']];
      }
    } else if (json['photoUrls'] != null) {
       if (json['photoUrls'] is List) {
        photoUrls = (json['photoUrls'] as List).map((e) => e.toString()).toList();
      } else if (json['photoUrls'] is String) {
        photoUrls = [json['photoUrls']];
      }
    }
    
    // Handle interests, which could be a list of strings or objects
    List<String> interests = [];
    if (json['interests'] != null) {
      if (json['interests'] is List) {
        interests = (json['interests'] as List).map((e) {
          if (e is String) {
            return e;
          } else if (e is Map) {
            return e['name']?.toString() ?? '';
          }
          return e.toString();
        }).where((s) => s.isNotEmpty).toList().cast<String>();
      }
    }
    
    // Handle birth date
    DateTime birthDate;
    if (json['birth_date'] != null) {
      try {
        birthDate = DateTime.parse(json['birth_date']);
      } catch (e) {
        birthDate = DateTime.now().subtract(Duration(days: 365 * age));
      }
    } else {
      birthDate = DateTime.now().subtract(Duration(days: 365 * age));
    }
    
    // Handle distances
    double? distance;
    if (json['distance'] != null) {
      if (json['distance'] is num) {
        distance = (json['distance'] as num).toDouble();
      } else if (json['distance'] is String) {
        distance = double.tryParse(json['distance']);
      }
    }
    
    return Profile(
      id: id,
      name: json['name'] ?? 'Unknown',
      age: age,
      gender: json['gender'] ?? 'unknown',
      bio: json['bio'],
      photoUrls: photoUrls,
      profileImageUrl: photoUrls.isNotEmpty ? photoUrls[0] : null,
      occupation: json['occupation'],
      education: json['education'],
      distance: distance,
      interests: interests,
      isOnline: json['isOnline'] ?? false,
      birthDate: birthDate,
      location: json['location'],
      minAgePreference: json['min_age_preference'] is int 
          ? json['min_age_preference'] 
          : (json['min_age_preference'] is String 
              ? int.tryParse(json['min_age_preference']) ?? 18 
              : 18),
      maxAgePreference: json['max_age_preference'] is int 
          ? json['max_age_preference'] 
          : (json['max_age_preference'] is String 
              ? int.tryParse(json['max_age_preference']) ?? 50 
              : 50),
      maxDistance: json['max_distance'] is num 
          ? (json['max_distance'] as num).toDouble() 
          : (json['max_distance'] is String 
              ? double.tryParse(json['max_distance']) ?? 50.0 
              : 50.0),
      genderPreference: json['gender_preference'],
      isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
      prompts: json['prompts'] as Map<String, String>?,
      videoIntroUrl: json['videoIntroUrl'] as String?,
      audioIntroUrl: json['audioIntroUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'bio': bio,
      'photoUrls': photoUrls,
      'occupation': occupation,
      'education': education,
      'distance': distance,
      'interests': interests,
      'isOnline': isOnline,
      'birth_date': birthDate.toIso8601String(),
      'location': location,
      'min_age_preference': minAgePreference,
      'max_age_preference': maxAgePreference,
      'max_distance': maxDistance,
      'gender_preference': genderPreference,
      'is_verified': isVerified,
      'prompts': prompts,
      'videoIntroUrl': videoIntroUrl,
      'audioIntroUrl': audioIntroUrl,
    };
  }
  
  // Helper method to calculate age from birthDate
  static int calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}