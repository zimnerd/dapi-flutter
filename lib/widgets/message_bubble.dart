import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../utils/colors.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Time stamp for received messages (left side)
          if (!isFromCurrentUser) _buildTimestamp(),

          // Message bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isFromCurrentUser ? AppColors.primary : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(!isFromCurrentUser ? 4 : 18),
                  topRight: Radius.circular(isFromCurrentUser ? 4 : 18),
                  bottomLeft: const Radius.circular(18),
                  bottomRight: const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isFromCurrentUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Status indicators and time stamp for sent messages (right side)
          if (isFromCurrentUser)
            Row(
              children: [
                const SizedBox(width: 4),
                _buildStatusIndicator(),
                _buildTimestamp(),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    // Only show status for sent messages
    if (!isFromCurrentUser) return const SizedBox();

    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 14,
          color: Colors.grey,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.grey,
        );
      case MessageStatus.read:
        return Icon(
          Icons.done_all,
          size: 14,
          color: AppColors.primary,
        );
      case MessageStatus.error:
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.red,
        );
      default:
        return const SizedBox(width: 14);
    }
  }

  Widget _buildTimestamp() {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, right: 4.0, bottom: 4.0),
      child: Text(
        DateFormat.jm().format(message.timestamp),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
        ),
      ),
    );
  }
}
