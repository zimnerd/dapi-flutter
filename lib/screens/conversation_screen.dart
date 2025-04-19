import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_message_actions.dart';
import '../providers/typing_provider.dart';
import '../utils/colors.dart';
import '../widgets/message_bubble.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import '../widgets/chat/typing_indicator.dart';
import '../utils/connectivity/network_manager.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ConversationScreen({Key? key, required this.conversation}) : super(key: key);

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  User? _participant;
  
  bool _isSending = false;
  
  @override
  void initState() {
    super.initState();
    _loadParticipant();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ChatMessageActions.markMessagesAsRead(ref, widget.conversation.id);
      _scrollToBottom();
    });
    
    // Set up message input listener for typing status
    _messageController.addListener(_onTypingChanged);
  }
  
  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    
    // Ensure typing is stopped when leaving screen
    ChatMessageActions.stopTyping(ref, widget.conversation.id);
    
    super.dispose();
  }
  
  void _onTypingChanged() {
    if (_messageController.text.isNotEmpty) {
      ChatMessageActions.handleTyping(ref, widget.conversation.id);
    }
  }
  
  Future<void> _loadParticipant() async {
    try {
      _participant = widget.conversation.participants.first;
    } catch (e) {
      print('Error loading participant: $e');
    }
  }
  
  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    _messageController.clear();
    _scrollToBottom(jump: true);
    
    try {
      // Check network status
      final networkStatus = ref.read(networkStatusProvider);
      if (networkStatus == NetworkStatus.offline) {
        // Show offline snackbar
        NetworkManager.showOfflineSnackBar(context);
      }
      
      // Send/queue the message
      ChatMessageActions.addMessage(ref, widget.conversation.id, text);
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }
  
  Widget _buildMessageList() {
    final messages = ref.watch(chatMessagesProvider(widget.conversation.id));
    final currentUserId = ref.watch(userIdProvider);

    if (messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            "Start a conversation with ${_participant?.name ?? 'this person'}!",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isCurrentUser = message.senderId == currentUserId;
        return MessageBubble(
          message: message,
          isFromCurrentUser: isCurrentUser,
        );
      },
    );
  }
  
  Widget _buildOfflineIndicator() {
    final networkStatus = ref.watch(networkStatusProvider);
    
    if (networkStatus == NetworkStatus.offline) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        color: Colors.orange,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Text(
              'You are offline. Messages will be sent when you reconnect.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
  
  Widget _buildTypingIndicator() {
    final typingUsers = ref.watch(typingUsersProvider);
    
    // Check if anyone is typing in this conversation
    final isTyping = typingUsers.containsKey(widget.conversation.id) && 
                   typingUsers[widget.conversation.id]?.isNotEmpty == true;
    
    // Get name of first typing user if available
    String typingUserName = '';
    if (isTyping && _participant != null) {
      final typingUserId = typingUsers[widget.conversation.id]?.keys.first;
      if (typingUserId == _participant?.id) {
        typingUserName = _participant!.name;
      }
    }
    
    return TypingIndicator(
      isTyping: isTyping,
      userName: typingUserName,
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingIndicator(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    ),
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isSending 
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.send, color: Theme.of(context).primaryColor),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        if (jump) {
          _scrollController.jumpTo(maxScroll);
        } else {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final participant = widget.conversation.participants.first;
    
    // Check if participant is online
    final isParticipantOnline = false; // This would ideally come from a provider
    
    // Check if participant is typing
    final typingUsers = ref.watch(typingUsersProvider);
    final isParticipantTyping = typingUsers.containsKey(widget.conversation.id) && 
                             typingUsers[widget.conversation.id]?.containsKey(participant.id) == true;
    
    // Check if we are connected
    final networkStatus = ref.watch(networkStatusProvider);
    final socketStatus = ref.watch(socketServiceProvider).status;
    final isConnected = networkStatus == NetworkStatus.online && 
                       (socketStatus == SocketConnectionStatus.connected || 
                        socketStatus == SocketConnectionStatus.authenticated);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: participant.profilePictures?.isNotEmpty == true
                  ? NetworkImage(participant.profilePictures!.first)
                  : const AssetImage('assets/images/placeholder_user.png') as ImageProvider,
              radius: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    participant.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isParticipantTyping 
                      ? 'Typing...' 
                      : (isParticipantOnline ? 'Online' : 'Offline'),
                    style: TextStyle(
                      color: isParticipantTyping 
                        ? AppColors.primary 
                        : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Connection status indicator
          if (!isConnected)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Icon(
                Icons.wifi_off,
                color: Colors.orange,
                size: 20,
              ),
            ),
          IconButton(
            icon: Icon(
              Icons.call,
              color: AppColors.primary,
            ),
            onPressed: () {
              // TODO: Implement call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calling feature coming soon!'),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Colors.black87,
            ),
            onPressed: () {
              // TODO: Show conversation options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildOfflineIndicator(),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
} 