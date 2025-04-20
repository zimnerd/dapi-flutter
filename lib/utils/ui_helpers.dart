import 'package:flutter/material.dart';

/// Utility class for UI helpers and common widgets
class UiHelpers {
  /// Shows a custom snackbar with consistent styling
  static void showSnackBar(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Get appropriate colors based on type
    final colors = _getSnackBarColors(type);

    // Create the snackbar
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(colors.icon, color: colors.contentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.contentColor),
            ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(8),
      duration: duration,
      action: action,
    );

    // Show the snackbar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows a success snackbar
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
      action: action,
    );
  }

  /// Shows an error snackbar
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      action: action,
    );
  }

  /// Shows a warning snackbar
  static void showWarningSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    showSnackBar(
      context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
      action: action,
    );
  }

  /// Gets colors for snackbar based on type
  static _SnackBarColors _getSnackBarColors(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return _SnackBarColors(
          backgroundColor: Colors.green[700]!,
          contentColor: Colors.white,
          icon: Icons.check_circle,
        );
      case SnackBarType.error:
        return _SnackBarColors(
          backgroundColor: Colors.red[700]!,
          contentColor: Colors.white,
          icon: Icons.error,
        );
      case SnackBarType.warning:
        return _SnackBarColors(
          backgroundColor: Colors.orange[700]!,
          contentColor: Colors.white,
          icon: Icons.warning,
        );
      case SnackBarType.info:
      default:
        return _SnackBarColors(
          backgroundColor: Colors.blue[700]!,
          contentColor: Colors.white,
          icon: Icons.info,
        );
    }
  }

  /// Shows a loading dialog
  static Future<void> showLoadingDialog(BuildContext context,
      {String? message}) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Flexible(
                  child: Text(
                    message ?? 'Loading...',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Hides any open dialogs
  static void hideDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Shows a confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                cancelLabel,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                confirmLabel,
                style: TextStyle(color: confirmColor),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }
}

/// Colors for snackbar
class _SnackBarColors {
  final Color backgroundColor;
  final Color contentColor;
  final IconData icon;

  _SnackBarColors({
    required this.backgroundColor,
    required this.contentColor,
    required this.icon,
  });
}

/// Type of snackbar
enum SnackBarType {
  info,
  success,
  error,
  warning,
}
