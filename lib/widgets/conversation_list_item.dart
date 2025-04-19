import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import '../screens/conversation_screen.dart';
import '../utils/colors.dart';
import '../utils/date_formatter.dart';
import '../providers/providers.dart';

class ConversationListItem extends ConsumerWidget {
  final Conversation conversation;
  final String currentUserId;

  const ConversationListItem({
    Key? key,
    required this.conversation,
    required this.currentUserId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUser = conversation.getOtherParticipant(currentUserId);
    final hasUnread = conversation.unreadCount > 0;
    
    // Check if the other user is typing
    final isTyping = ref.watch(
      typingUsersProvider.select((state) => 
        state.isAnyoneTypingInConversation(conversation.id)
      )
    );
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversation: conversation,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasUnread ? AppColors.primary.withOpacity(0.05) : null,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildAvatar(otherUser),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          otherUser.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormatter.formatConversationDate(
                          conversation.lastMessage?.timestamp ?? 
                          conversation.updatedAt ?? 
                          conversation.createdAt
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: hasUnread 
                              ? AppColors.primary 
                              : AppColors.textSecondary,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: isTyping 
                          ? _buildTypingIndicator() 
                          : Text(
                              conversation.lastMessage?.text ?? 'Start a conversation!',
                              style: TextStyle(
                                fontSize: 14,
                                color: hasUnread 
                                    ? AppColors.textPrimary 
                                    : AppColors.textSecondary,
                                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                      ),
                      if (hasUnread) _buildUnreadBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Row(
      children: [
        Text(
          'typing',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 4),
        _buildTypingDots(),
      ],
    );
  }

  Widget _buildTypingDots() {
    return Row(
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 200)),
            curve: Curves.easeInOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildAvatar(User user) {
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundImage: user.profilePictures?.isNotEmpty == true
              ? NetworkImage(user.profilePictures!.first)
              : null,
          backgroundColor: user.profilePictures?.isNotEmpty != true
              ? AppColors.primary.withOpacity(0.2)
              : null,
          child: user.profilePictures?.isNotEmpty != true
              ? const Icon(Icons.person, color: Colors.white, size: 30)
              : null,
        ),
        if (conversation.isMatched)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnreadBadge() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        conversation.unreadCount.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 