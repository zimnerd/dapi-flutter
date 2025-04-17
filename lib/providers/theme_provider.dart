import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to manage the current theme mode
// Defaults to system theme mode initially
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
