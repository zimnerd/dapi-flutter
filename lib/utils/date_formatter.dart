import 'package:intl/intl.dart';

/// Helper class for date formatting operations
class DateFormatter {
  /// Format a date for conversation display
  static String formatConversationDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      // Today, show time only
      return DateFormat('h:mm a').format(date);
    } else if (messageDate == yesterday) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      // Within the last week, show day name
      return DateFormat('EEEE').format(date);
    } else {
      // Older, show date
      return DateFormat('MMM d').format(date);
    }
  }
  
  /// Format a date for full display including year if needed
  static String formatFullDate(DateTime date) {
    final now = DateTime.now();
    
    if (date.year == now.year) {
      return DateFormat('MMM d, h:mm a').format(date);
    } else {
      return DateFormat('MMM d, yyyy, h:mm a').format(date);
    }
  }
  
  /// Format a short timestamp for chat bubbles
  static String formatMessageTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
} 