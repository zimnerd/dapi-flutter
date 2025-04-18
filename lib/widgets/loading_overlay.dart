import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  
  const LoadingOverlay({
    Key? key,
    required this.child,
    required this.isLoading,
    this.message,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: 16.0),
                        Text(
                          message!,
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  // Convenience method to show a loading overlay
  static Future<T> show<T>({
    required BuildContext context,
    required Future<T> Function() future,
    String? message,
  }) async {
    // Show loading indicator
    final overlayEntry = OverlayEntry(
      builder: (context) => Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16.0),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 14.0,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    
    Overlay.of(context).insert(overlayEntry);
    
    try {
      // Execute the future
      final result = await future();
      
      // Remove loading indicator
      overlayEntry.remove();
      
      return result;
    } catch (e) {
      // Remove loading indicator
      overlayEntry.remove();
      
      // Rethrow the error
      rethrow;
    }
  }
} 