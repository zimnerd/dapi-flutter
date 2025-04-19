import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message.dart';
import '../../utils/colors.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isFromCurrentUser;
  final VoidCallback? onRetry;
  final VoidCallback? onLongPress;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isFromCurrentUser,
    this.onRetry,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Align(
      alignment: isFromCurrentUser 
          ? Alignment.centerRight 
          : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: EdgeInsets.only(
            left: isFromCurrentUser ? 64.0 : 8.0,
            right: isFromCurrentUser ? 8.0 : 64.0,
            top: 4.0,
            bottom: 4.0,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: isFromCurrentUser 
                ? AppColors.primary 
                : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(18.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Message text
              Text(
                message.messageText,
                style: TextStyle(
                  color: isFromCurrentUser 
                      ? Colors.white 
                      : Colors.black87,
                  fontSize: 16.0,
                ),
              ),
              
              const SizedBox(height: 4.0),
              
              // Bottom row with time and status
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Time
                  Text(
                    message.formattedTime,
                    style: TextStyle(
                      color: isFromCurrentUser 
                          ? Colors.white.withOpacity(0.7) 
                          : Colors.black54,
                      fontSize: 12.0,
                    ),
                  ),
                  
                  // Space
                  const SizedBox(width: 4.0),
                  
                  // Status indicator (only for outgoing messages)
                  if (isFromCurrentUser) _buildStatusIndicator(),
                ],
              ),
              
              // Retry button for failed messages
              if (isFromCurrentUser && message.status == MessageStatus.failed)
                _buildRetryButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusIndicator() {
    switch (message.status) {
      case MessageStatus.pending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
          ),
        );
        
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 14,
          color: Colors.white.withOpacity(0.7),
        );
        
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 14,
          color: Colors.white.withOpacity(0.7),
        );
        
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.lightBlueAccent,
        );
        
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.redAccent,
        );
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        margin: const EdgeInsets.only(top: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.refresh,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4.0),
            Text(
              'Retry',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 