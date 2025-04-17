import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added Riverpod
// import '../services/auth_service.dart'; // Remove direct import
import '../providers/providers.dart'; // Import main providers
import '../utils/colors.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_indicator.dart';

// Changed to ConsumerWidget to access providers via ref
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

// Changed to ConsumerState
class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // FIX: Remove direct service instantiation, use provider via ref
  // final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... existing code ...
  }

  Future<void> _handleForgotPassword() async {
    // ... existing code ...

    try {
      // FIX: Access AuthService via provider
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(_emailController.text);
      setState(() {
        _successMessage = 'Password reset email sent! Please check your inbox.';
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }
} 