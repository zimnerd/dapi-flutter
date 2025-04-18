import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/profile_provider.dart';

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  void _handleSubmit() async {
    try {
      final profileService = ref.read(profileProvider);
      // ... rest of the method
    } catch (e) {
      // ... error handling
    }
  }
} 