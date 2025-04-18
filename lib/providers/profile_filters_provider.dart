import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

class ProfileFilters {
  final double maxDistance;
  final RangeValues ageRange;
  final String genderPreference;

  const ProfileFilters({
    required this.maxDistance,
    required this.ageRange,
    required this.genderPreference,
  });

  // Initial state with default values
  factory ProfileFilters.initial() {
      return ProfileFilters(
        maxDistance: AppConfig.maxDistance,
        ageRange: RangeValues(AppConfig.minAge.toDouble(), AppConfig.maxAge.toDouble()),
        genderPreference: 'All',
      );
  }

  // CopyWith method for immutability
  ProfileFilters copyWith({
    double? maxDistance,
    RangeValues? ageRange,
    String? genderPreference,
  }) {
    return ProfileFilters(
      maxDistance: maxDistance ?? this.maxDistance,
      ageRange: ageRange ?? this.ageRange,
      genderPreference: genderPreference ?? this.genderPreference,
    );
  }

  // Equality check
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProfileFilters &&
        other.maxDistance == maxDistance &&
        other.ageRange.start == ageRange.start &&
        other.ageRange.end == ageRange.end &&
        other.genderPreference == genderPreference;
  }

  @override
  int get hashCode => Object.hash(
        maxDistance,
        ageRange.start,
        ageRange.end,
        genderPreference,
      );
}

// StateNotifier to manage profile filters
class ProfileFiltersNotifier extends StateNotifier<ProfileFilters> {
  ProfileFiltersNotifier() : super(ProfileFilters.initial());

  void updateFilters({
    double? maxDistance,
    RangeValues? ageRange,
    String? genderPreference,
  }) {
    state = state.copyWith(
      maxDistance: maxDistance,
      ageRange: ageRange,
      genderPreference: genderPreference,
    );
  }

  void resetFilters() {
    state = ProfileFilters.initial();
  }
}

// Provider for profile filters
final profileFiltersProvider = StateNotifierProvider<ProfileFiltersNotifier, ProfileFilters>((ref) {
  return ProfileFiltersNotifier();
}); 