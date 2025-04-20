import 'package:flutter/material.dart';
import '../models/message.dart';
import '../utils/colors.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isFromCurrentUser;
  final bool showAvatar;
  final String? participantAvatarUrl;
  final bool isPremium;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isFromCurrentUser,
    required this.showAvatar,
    this.participantAvatarUrl,
    this.isPremium = false,
  });

  Widget _buildReadReceiptIcon(MessageStatus status) {
    IconData iconData = Icons.help_outline;
    Color iconColor = Colors.grey[500]!;
    double iconSize = 14.0;

    switch (status) {
      case MessageStatus.sending:
        iconData = Icons.access_time;
        iconColor = Colors.grey[500]!;
        break;
      case MessageStatus.sent:
        iconData = Icons.done;
        iconColor = Colors.grey[500]!;
        break;
      case MessageStatus.delivered:
        iconData = Icons.done_all;
        iconColor = Colors.grey[500]!;
        break;
      case MessageStatus.read:
        iconData = Icons.done_all;
        iconColor = isPremium ? Colors.blue[400]! : Colors.grey[500]!;
        break;
      case MessageStatus.failed:
        iconData = Icons.error_outline;
        iconColor = Colors.red[400]!;
        break;
    }

    return Icon(iconData, size: iconSize, color: iconColor);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  ImageProvider _getAvatarImage() {
    if (participantAvatarUrl != null &&
        participantAvatarUrl!.startsWith('http')) {
      return NetworkImage(participantAvatarUrl!);
    }
    return const AssetImage('assets/images/placeholder_user.png');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser && showAvatar)
            Padding(
              padding: const EdgeInsets.only(right: 8.0, bottom: 20),
              child: CircleAvatar(
                backgroundImage: _getAvatarImage(),
                radius: 16,
              ),
            )
          else if (!isFromCurrentUser)
            const SizedBox(width: 40),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: isFromCurrentUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 5),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                if (isFromCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: _buildReadReceiptIcon(message.status),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
