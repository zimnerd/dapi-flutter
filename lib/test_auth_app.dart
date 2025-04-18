import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'test_auth.dart';

/// Entry point for the auth test application
void main() {
  runApp(
    const ProviderScope(
      child: AuthTestApp(),
    ),
  );
}

/// The main application for testing authentication
class AuthTestApp extends StatelessWidget {
  const AuthTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auth Flow Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthTest(),
    );
  }
} 