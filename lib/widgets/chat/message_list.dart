import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/message.dart';
import '../../providers/message_provider.dart';
import '../../providers/typing_provider.dart';
import '../../utils/colors.dart';
import '../../widgets/chat/message_bubble.dart';
import '../../widgets/chat/typing_indicator.dart';

class MessageList extends ConsumerWidget {
  final String conversationId;
  final String currentUserId;
  final Map<String, String> participantNames;
  final ScrollController scrollController;
  final bool isOnline;

  const MessageList({
    Key? key,
    required this.conversationId,
    required this.currentUserId,
    required this.participantNames,
    required this.scrollController,
    this.isOnline = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch messages state for this conversation
    final messagesState = ref.watch(messagesProvider);
    final messages = messagesState.conversationMessages[conversationId] ?? [];
    final loadingState = messagesState.loadingStates[conversationId] ?? MessageLoadingState.initial;
    final errorMessage = messagesState.errorMessages[conversationId];
    
    // Watch typing state for this conversation
    final isAnyoneTyping = ref.watch(
      typingUsersProvider.select(
        (typingState) => typingState.containsKey(conversationId) &&
                         typingState[conversationId]?.isNotEmpty == true
      )
    );
    
    final typingUserId = isAnyoneTyping 
        ? ref.read(typingUsersProvider.notifier).getFirstTypingUser(conversationId)
        : null;
    
    final typingUserName = typingUserId != null && participantNames.containsKey(typingUserId)
        ? participantNames[typingUserId]
        : 'Someone';
    
    // If initial state, load messages
    if (loadingState == MessageLoadingState.initial) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(messagesProvider.notifier).loadMessages(conversationId);
      });
      return const Center(child: CircularProgressIndicator());
    }
    
    // If loading
    if (loadingState == MessageLoadingState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // If error
    if (loadingState == MessageLoadingState.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              errorMessage ?? 'Failed to load messages',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.error),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(messagesProvider.notifier).loadMessages(conversationId),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }
    
    // If empty
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Say hello to start the conversation!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Create message groups by date
    final groupedMessages = _groupMessagesByDate(messages);
    
    return ListView.builder(
      controller: scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      itemCount: groupedMessages.length + (isAnyoneTyping ? 1 : 0),
      itemBuilder: (context, index) {
        // Show typing indicator as the first item (when list is reversed)
        if (index == 0 && isAnyoneTyping) {
          return Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 64.0, top: 8.0, bottom: 8.0),
            child: TypingIndicator(
              isTyping: true,
              userName: typingUserName ?? '',
            ),
          );
        }
        
        // Adjust index if typing indicator is showing
        final itemIndex = isAnyoneTyping ? index - 1 : index;
        final item = groupedMessages[itemIndex];
        
        // If it's a date header
        if (item is String) {
          return _buildDateSeparator(item);
        }
        
        // Otherwise it's a message
        final message = item as Message;
        final isFromCurrentUser = message.senderId == currentUserId;
        
        return MessageBubble(
          message: message,
          isFromCurrentUser: isFromCurrentUser,
          onRetry: message.status == MessageStatus.failed
              ? () => ref.read(messagesProvider.notifier).retryMessage(message.id)
              : null,
        );
      },
    );
  }
  
  Widget _buildDateSeparator(String date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          const Expanded(
            child: Divider(thickness: 0.5),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(
            child: Divider(thickness: 0.5),
          ),
        ],
      ),
    );
  }
  
  /// Group messages by date, inserting date headers
  List<dynamic> _groupMessagesByDate(List<Message> messages) {
    final result = <dynamic>[];
    String? currentDate;
    
    // Iterate through messages (assuming they're already sorted)
    for (final message in messages) {
      final messageDate = message.formattedDate;
      
      // If date changed, add a date separator
      if (messageDate != currentDate) {
        result.add(messageDate);
        currentDate = messageDate;
      }
      
      result.add(message);
    }
    
    return result.reversed.toList(); // Reverse for displaying newest at bottom
  }
} 