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
import '../utils/connectivity/connectivity_provider.dart';
import '../utils/date_formatter.dart';
import '../utils/connectivity/network_manager.dart';
import '../providers/offline_message_queue_provider.dart';
import '../services/socket_service.dart';
import '../providers/notification_provider.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ConversationScreen({Key? key, required this.conversation}) : super(key: key);

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  Profile? _participant;
  Timer? _typingTimer;
  bool _isTyping = false;
  
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadParticipant();
    
    // Add focus listener for typing events
    _messageController.addListener(_onTypingChanged);
    
    // Start listening for new messages immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSocketListeners();
      
      // Cancel any notifications for this conversation
      ref.read(notificationManagerProvider).cancelConversationNotifications(
        widget.conversation.id
      );
    });
  }
  
  @override
  void dispose() {
    _messageController.removeListener(_onTypingChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    
    // Stop sending typing notifications when leaving the screen
    _sendTypingNotification(false);
    
    super.dispose();
  }
  
  void _setupSocketListeners() {
    final socketService = ref.read(socketServiceProvider);
    final conversationId = widget.conversation.id;
    
    // Join the conversation room
    socketService.joinConversation(conversationId);
    
    // Listen for new messages
    socketService.onMessageReceived((data) {
      if (data != null && data['conversationId'] == conversationId) {
        final newMessage = Message.fromJson(data);
        setState(() {
          _addMessage(newMessage);
        });
      }
    });
    
    // Listen for typing events
    socketService.onTypingStatusChanged((data) {
      if (data != null && 
          data['conversationId'] == conversationId && 
          data['userId'] != ref.read(authServiceProvider).getUserId()) {
        setState(() {
          _isTyping = data['isTyping'] == true;
        });
      }
    });
    
    // Send read receipts for this conversation
    _sendReadReceipt();
    
    // Process offline queue if available
    _processOfflineQueue();
  }
  
  void _processOfflineQueue() {
    final socketService = ref.read(socketServiceProvider);
    final offlineQueue = ref.read(offlineMessageQueueProvider.notifier);
    
    if (socketService.isConnected) {
      final queuedMessages = offlineQueue.getMessagesForConversation(widget.conversation.id);
      
      for (final message in queuedMessages) {
        // Send queued message through socket
        socketService.sendMessage(
          conversationId: message.conversationId,
          content: message.content,
          senderId: message.senderId
        );
        
        // Remove from queue after sending
        offlineQueue.removeMessage(message.id);
      }
    }
  }
  
  void _sendReadReceipt() {
    final socketService = ref.read(socketServiceProvider);
    final userId = ref.read(authServiceProvider).getUserId();
    
    if (socketService.isConnected) {
      socketService.sendReadReceipt(
        conversationId: widget.conversation.id,
        userId: userId
      );
    }
  }
  
  void _onTypingChanged() {
    // If user is typing, send notification
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      _sendTypingNotification(true);
    }
    
    // Reset the timer that tracks when user stops typing
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        _sendTypingNotification(false);
      }
    });
  }
  
  void _sendTypingNotification(bool isTyping) {
    final socketService = ref.read(socketServiceProvider);
    final userId = ref.read(authServiceProvider).getUserId();
    
    if (socketService.isConnected) {
      socketService.sendTypingStatus(
        conversationId: widget.conversation.id,
        userId: userId,
        isTyping: isTyping
      );
    }
  }
  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final chatService = ref.read(chatServiceProvider);
      final List<Message> messages = await chatService.getMessages(widget.conversation.id);
      
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
        _isLoading = false;
      });
      
      // After loading messages, scroll to bottom
      _scrollToBottom();
    } catch (e) {
      print('⟹ [ConversationScreen] Error loading messages: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadParticipant() async {
    try {
      // Get the other participant (not the current user)
      final userId = ref.read(authServiceProvider).getUserId();
      final participantId = widget.conversation.participants
          .firstWhere((p) => p != userId, orElse: () => '');
      
      if (participantId.isNotEmpty) {
        final profileService = ref.read(profileServiceProvider);
        final profile = await profileService.getProfile(participantId);
        
        setState(() {
          _participant = profile;
        });
      }
    } catch (e) {
      print('⟹ [ConversationScreen] Error loading participant: $e');
    }
  }
  
  void _addMessage(Message message) {
    if (!_messages.any((m) => m.id == message.id)) {
      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    }
  }
  
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }
  
  bool _shouldShowAvatar(int index) {
    // Show avatar only for the first message in a group
    if (index == 0) return true;
    
    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];
    
    // Different sender means show avatar
    if (currentMessage.senderId != previousMessage.senderId) return true;
    
    // If messages are more than 2 minutes apart, show avatar
    final timeDifference = currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes;
    return timeDifference >= 2;
  }
  
  bool _shouldShowTimestamp(int index) {
    // Show timestamp for the first message
    if (index == 0) return true;
    
    final currentMessage = _messages[index];
    final previousMessage = _messages[index - 1];
    
    // If messages are from different senders, show timestamp
    if (currentMessage.senderId != previousMessage.senderId) return true;
    
    // If messages are more than 5 minutes apart, show timestamp
    final timeDifference = currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes;
    return timeDifference >= 5;
  }
  
  Widget _buildMessageItem(Message message, bool isFromCurrentUser, bool showAvatar, bool showTime) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromCurrentUser && showAvatar)
            CircleAvatar(
              backgroundImage: _participant?.profilePictures?.isNotEmpty == true
                  ? NetworkImage(_participant!.profilePictures!.first)
                  : const AssetImage('assets/images/placeholder_user.png') as ImageProvider,
              radius: 16,
            )
          else if (!isFromCurrentUser && !showAvatar)
            const SizedBox(width: 32), // Space for avatar alignment
            
          const SizedBox(width: 8),
          
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showTime)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      DateFormatter.formatTime(message.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser ? Colors.blue[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.content,
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (isFromCurrentUser) 
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                message.status == MessageStatus.sent 
                                  ? Icons.check 
                                  : message.status == MessageStatus.delivered 
                                    ? Icons.done_all
                                    : message.status == MessageStatus.read
                                      ? Icons.done_all
                                      : Icons.access_time,
                                size: 14,
                                color: message.status == MessageStatus.read
                                  ? Colors.blue
                                  : Colors.grey,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 8),
          
          if (isFromCurrentUser && showAvatar)
            CircleAvatar(
              backgroundImage: const AssetImage('assets/images/placeholder_user.png'),
              radius: 16,
            )
          else if (isFromCurrentUser && !showAvatar)
            const SizedBox(width: 32), // Space for avatar alignment
        ],
      ),
    );
  }
  
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 5,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                // Attachment functionality
              },
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                maxLines: null,
              ),
            ),
            _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
          ],
        ),
      ),
    );
  }
  
  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    setState(() {
      _isSending = true;
    });
    
    _messageController.clear();
    
    // Stop typing when sending a message
    _isTyping = false;
    _sendTypingNotification(false);
    
    final userId = ref.read(authServiceProvider).getUserId();
    final userName = ref.read(authServiceProvider).getUserName() ?? 'You';
    
    // Create a temporary message with pending status
    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
      conversationId: widget.conversation.id,
      senderId: userId,
      senderName: userName,
      content: message,
      timestamp: DateTime.now(),
      status: MessageStatus.pending
    );
    
    // Add to UI immediately
    setState(() {
      _addMessage(newMessage);
    });
    
    // Scroll to bottom
    _scrollToBottom();
    
    final socketService = ref.read(socketServiceProvider);
    
    // Check if socket is connected
    if (socketService.isConnected) {
      // Send via socket for real-time delivery
      socketService.sendMessage(
        conversationId: widget.conversation.id,
        content: message,
        senderId: userId
      );
    } else {
      // Add to offline queue if not connected
      ref.read(offlineMessageQueueProvider.notifier).addMessage(newMessage);
      
      // Also try to send via HTTP fallback
      try {
        await ref.read(chatServiceProvider).sendMessage(
          widget.conversation.id,
          message
        );
      } catch (e) {
        print('⟹ [ConversationScreen] Failed to send message via HTTP: $e');
        // Message will be sent when connection is restored from queue
      }
    }
    
    setState(() {
      _isSending = false;
    });
  }
  
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isFromCurrentUser = message.senderId == ref.read(authServiceProvider).getUserId();
        
        // Group messages by sender and time (within 2 minutes)
        final bool showAvatar = _shouldShowAvatar(index);
        final bool showTime = _shouldShowTimestamp(index);
        
        return _buildMessageItem(message, isFromCurrentUser, showAvatar, showTime);
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
  
  @override
  Widget build(BuildContext context) {
    // Watch socket connection status for network indicator
    final isSocketConnected = ref.watch(socketServiceProvider.select((s) => s.isConnected));
    final isUserTyping = ref.watch(typingUsersProvider.select(
      (typing) => typing.isUserTypingInConversation(widget.conversation.id)
    ));
    final typingUserName = ref.watch(typingUsersProvider.select(
      (typing) => typing.getTypingUserNameForConversation(widget.conversation.id)
    ));
    
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
              backgroundImage: _participant?.profilePictures?.isNotEmpty == true
                  ? NetworkImage(_participant!.profilePictures!.first)
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
                    _participant?.name ?? 'Chat',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isSocketConnected) 
                    const Text(
                      'Offline - Messages will be sent when reconnected',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // Show profile info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildMessageList(),
          ),
          
          // Typing indicator
          TypingIndicator(
            isTyping: isUserTyping,
            userName: typingUserName,
          ),
          
          _buildMessageInput(),
        ],
      ),
    );
  }
} 