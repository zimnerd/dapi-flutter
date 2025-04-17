import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation.dart';
import '../utils/colors.dart';

class ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;
  
  const ConversationTile({
    Key? key,
    required this.conversation,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final otherUser = conversation.participants.first;
    final hasUnread = conversation.unreadCount > 0;
    
    return ListTile(
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: otherUser.profilePictures != null && otherUser.profilePictures!.isNotEmpty
            ? NetworkImage(otherUser.profilePictures!.first)
            : null,
        backgroundColor: otherUser.profilePictures == null || otherUser.profilePictures!.isEmpty
            ? AppColors.primary.withOpacity(0.2)
            : null,
        child: otherUser.profilePictures == null || otherUser.profilePictures!.isEmpty
            ? Text(
                otherUser.name.isNotEmpty ? otherUser.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              )
            : null,
      ),
      title: Text(
        otherUser.name,
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        conversation.lastMessage?.text ?? 'No messages yet',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessage?.timestamp),
            style: TextStyle(
              color: hasUnread ? AppColors.primary : AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          if (hasUnread)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                conversation.unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
  
  String _formatTime(DateTime? time) {
    if (time == null) {
      return '';
    }
    
    final now = DateTime.now();
    if (now.difference(time).inDays > 0) {
      if (now.difference(time).inDays == 1) {
        return 'Yesterday';
      } else if (now.difference(time).inDays < 7) {
        return DateFormat('EEEE').format(time).substring(0, 3);  // First three letters of day name
      } else {
        return '${time.day}/${time.month}';
      }
    } else {
      return DateFormat('HH:mm').format(time);
    }
  }
} 