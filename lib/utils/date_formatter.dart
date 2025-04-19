import 'package:intl/intl.dart';

/// Utility class for formatting dates in a consistent way
class DateFormatter {
  /// Format a timestamp for display in message bubbles
  static String formatMessageTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }
  
  /// Format a date for message date dividers
  static String formatMessageDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEEE').format(date); // Weekday name
    } else {
      return DateFormat('MMM d, y').format(date); // Jan 1, 2023
    }
  }
  
  /// Format a date for conversation list
  static String formatConversationDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return DateFormat('h:mm a').format(date);
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return DateFormat('EEE').format(date); // Short weekday name
    } else {
      return DateFormat('M/d/yy').format(date); // 1/1/23
    }
  }
  
  /// Format a timestamp for display in a detailed format
  static String formatDetailedDateTime(DateTime date) {
    return DateFormat('MMM d, y • h:mm a').format(date); // Jan 1, 2023 • 12:00 PM
  }
  
  /// Format how long ago a date was (e.g., "2 hours ago", "3 days ago")
  static String formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
} 