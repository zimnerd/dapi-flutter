import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/profile_service.dart';
import 'providers.dart';

/// Verification state class
class VerificationState {
  final bool isVerified;
  final bool isVerifying;
  final String? verificationToken;
  final String? verificationStatus;
  final String? message;
  final String? error;

  const VerificationState({
    this.isVerified = false,
    this.isVerifying = false,
    this.verificationToken,
    this.verificationStatus,
    this.message,
    this.error,
  });

  VerificationState copyWith({
    bool? isVerified,
    bool? isVerifying,
    String? verificationToken,
    String? verificationStatus,
    String? message,
    String? error,
  }) {
    return VerificationState(
      isVerified: isVerified ?? this.isVerified,
      isVerifying: isVerifying ?? this.isVerifying,
      verificationToken: verificationToken ?? this.verificationToken,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      message: message ?? this.message,
      error: error,
    );
  }
}

/// Verification notifier class
class VerificationNotifier extends StateNotifier<VerificationState> {
  final ProfileService _profileService;

  VerificationNotifier(this._profileService) : super(const VerificationState()) {
    _checkVerificationStatus();
  }

  /// Check current verification status
  Future<void> _checkVerificationStatus() async {
    try {
      final response = await _profileService.checkVerificationStatus();
      final status = response['status'] as String?;
      final message = response['message'] as String?;
      
      state = state.copyWith(
        isVerified: status == 'verified',
        verificationStatus: status,
        message: message,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Request verification
  Future<void> requestVerification() async {
    if (state.isVerified || state.isVerifying) return;

    state = state.copyWith(isVerifying: true, error: null);
    try {
      final response = await _profileService.requestVerification();
      final status = response['status'] as String?;
      final token = response['token'] as String?;
      final message = response['message'] as String?;
      
      state = state.copyWith(
        isVerifying: false,
        verificationToken: token,
        verificationStatus: status,
        message: message,
      );
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: e.toString(),
      );
    }
  }

  /// Complete verification with token
  Future<void> completeVerification({String? selfieImagePath}) async {
    if (state.isVerified || state.verificationToken == null || state.verificationToken!.isEmpty) return;

    state = state.copyWith(isVerifying: true, error: null);
    try {
      final response = await _profileService.completeVerification(
        state.verificationToken!,
        selfieImagePath,
      );
      
      final status = response['status'] as String?;
      final message = response['message'] as String?;
      
      state = state.copyWith(
        isVerifying: false,
        isVerified: status == 'verified',
        verificationStatus: status,
        message: message,
        verificationToken: null,
      );
    } catch (e) {
      state = state.copyWith(
        isVerifying: false,
        error: e.toString(),
      );
    }
  }

  /// Reset verification state
  void resetVerification() {
    state = const VerificationState();
  }
}

/// Verification provider
final verificationProvider = StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  return VerificationNotifier(profileService);
}); 