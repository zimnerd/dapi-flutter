import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../utils/colors.dart';
import '../providers/chat_provider.dart';

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isFromCurrentUser;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isFromCurrentUser,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('h:mm a');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser)
            const CircleAvatar(
              radius: 12,
              backgroundImage: AssetImage('assets/images/placeholder_user.png'),
            ),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? AppColors.primary
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isFromCurrentUser
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeFormat.format(message.timestamp),
                        style: TextStyle(
                          color: isFromCurrentUser
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (isFromCurrentUser) ...[
                        const SizedBox(width: 4),
                        _buildStatusIndicator(context, ref),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          if (isFromCurrentUser && message.status == MessageStatus.error) ...[
            SizedBox(width: 4),
            _buildRetryButton(context, ref),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusIndicator(BuildContext context, WidgetRef ref) {
    switch (message.status) {
      case MessageStatus.sending:
        return SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 16,
          color: Colors.white.withOpacity(0.8),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.check,
          size: 16,
          color: Colors.white.withOpacity(0.8),
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 16,
          color: Colors.white.withOpacity(0.8),
        );
      case MessageStatus.error:
        return Icon(
          Icons.error_outline,
          size: 16,
          color: Colors.red[400],
        );
      default:
        return SizedBox.shrink();
    }
  }
  
  Widget _buildRetryButton(BuildContext context, WidgetRef ref) {
    return InkWell(
      onTap: () {
        // Get the chat notifier for this conversation
        final chatNotifier = ref.read(
          chatMessagesProvider(message.conversationId).notifier
        );
        // Resend the message
        chatNotifier.resendMessage(message.id);
      },
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          Icons.refresh,
          size: 16,
          color: AppColors.error,
        ),
      ),
    );
  }
} 