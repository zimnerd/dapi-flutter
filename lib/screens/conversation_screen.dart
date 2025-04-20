import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // For Timer
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/chat_message_actions.dart';
import '../services/chat_service.dart';
import '../utils/colors.dart';
import '../widgets/message_bubble.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';

class ConversationScreen extends ConsumerStatefulWidget {
  final Conversation conversation;

  const ConversationScreen({super.key, required this.conversation});

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  User? _participant;
  String? _currentUserId;
  List<Message> _messages = []; // Local list to manage messages
  bool _isLoadingInitialMessages = true;
  String? _initialError;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _initWebSocket();

    _messageController.addListener(_handleTyping);
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoadingInitialMessages = true;
      });

      // Get current user ID from ProviderScope
      _currentUserId = ref.read(userIdProvider);

      // Determine which participant is the other person (not current user)
      final participantId = widget.conversation.participants
          .firstWhere((p) => p.id != _currentUserId)
          .id;

      // Fetch participant details if needed (assuming Conversation model has basic info)
      _participant = widget.conversation.participants
          .firstWhere((p) => p.id == participantId);

      // Fetch initial messages via HTTP
      final initialMessages = await ref
          .read(chatServiceProvider)
          .getMessages(widget.conversation.id);
      setState(() {
        // Convert dynamic messages to Message objects
        _messages = initialMessages
            .map((data) => Message.fromJson(
                data['id'] as String, data as Map<String, dynamic>))
            .toList();
        _isLoadingInitialMessages = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      // Mark as read after loading
      ref
          .read(chatServiceProvider)
          .markConversationAsRead(widget.conversation.id);
    } catch (e) {
      print('Error loading participant or initial messages: $e');
      setState(() {
        _isLoadingInitialMessages = false;
        _initialError = e.toString();
      });
    }
  }

  void _initWebSocket() {
    final chatService = ref.read(chatServiceProvider);
    chatService.initSocket(); // Initialize connection

    // Listen for incoming messages from the stream
    final messageSubscription = ref.listenManual(messageStreamProvider,
        (prev, AsyncValue<Map<String, dynamic>> next) {
      next.whenData((messageData) {
        // Convert dynamic message to Message object
        final message =
            Message.fromJson(messageData['id'] as String, messageData);

        // Add message only if it belongs to this conversation
        if (message.conversationId == widget.conversation.id) {
          setState(() {
            // Avoid duplicates if message was already added optimistically
            if (!_messages.any((m) => m.id == message.id)) {
              _messages.add(message);
            }
            _messages.sort(
                (a, b) => a.timestamp.compareTo(b.timestamp)); // Ensure order
          });
          WidgetsBinding.instance
              .addPostFrameCallback((_) => _scrollToBottom());
          // Mark as read if received while screen is active
          if (message.senderId != _currentUserId) {
            chatService.markConversationAsRead(widget.conversation.id);
          }
        }
      });
    });

    // Listen for typing status changes
    final typingSubscription = ref
        .listenManual(typingStatusProvider(widget.conversation.id),
            (prev, AsyncValue<Map<String, bool>> next) {
      next.whenData((typingStatusMap) {
        final otherUserId = _participant?.id;
        if (otherUserId != null) {
          final isOtherUserTyping = typingStatusMap[otherUserId] ?? false;
          if (_isTyping != isOtherUserTyping) {
            setState(() {
              _isTyping = isOtherUserTyping;
            });
          }
        }
      });
    });

    // Keep track of subscriptions to dispose them later
    // (Consider using ref.onDispose for automatic cleanup)
  }

  void _handleTyping() {
    final chatService = ref.read(chatServiceProvider);
    final recipientId = _participant?.id;
    if (recipientId == null) return;

    if (_messageController.text.isNotEmpty) {
      chatService.startTyping(recipientId);
      // Debounce stop typing event
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        chatService.stopTyping(recipientId);
      });
    } else {
      _typingTimer?.cancel();
      chatService.stopTyping(recipientId);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    // Disconnect socket when screen is disposed
    // Consider if socket should stay connected longer (e.g., app lifecycle)
    // ref.read(chatServiceProvider).dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _participant == null) return;

    final chatService = ref.read(chatServiceProvider);
    final recipientId = _participant!.id;
    final currentUserId = _currentUserId ?? 'unknown_user'; // Fallback

    _messageController.clear();
    _typingTimer?.cancel(); // Stop typing timer on send
    chatService.stopTyping(recipientId); // Ensure stop typing is emitted

    // Optimistically add message to UI
    final optimisticMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
      conversationId: widget.conversation.id,
      senderId: currentUserId,
      text: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    setState(() {
      _messages.add(optimisticMessage);
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _scrollToBottom(jump: true));

    // Send via WebSocket
    chatService.sendPrivateMessage(recipientId, text);

    // Note: We don't need to handle _isSending state manually anymore
    // The actual message confirmation would come via the WebSocket 'new_message' event
    // or potentially a specific 'message_sent' acknowledgement event if implemented.
  }

  Widget _buildMessageList() {
    if (_isLoadingInitialMessages) {
      return const Center(child: LoadingIndicator());
    }

    if (_initialError != null) {
      return Center(
        child: ErrorDisplay(message: 'Error loading messages: $_initialError'),
      );
    }

    if (_messages.isEmpty) {
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

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isCurrentUser = message.senderId == _currentUserId;
        return MessageBubble(
          message: message,
          isFromCurrentUser: isCurrentUser,
        );
      },
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
        child: Row(
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
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10.0),
                ),
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
              onPressed: _sendMessage,
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
    final participant = _participant;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: participant == null
            ? const Text("Loading...",
                style: TextStyle(color: Colors.black87, fontSize: 16))
            : Row(
                children: [
                  CircleAvatar(
                    backgroundImage: participant.profilePictures?.isNotEmpty ==
                            true
                        ? NetworkImage(participant.profilePictures!.first)
                        : const AssetImage('assets/images/placeholder_user.png')
                            as ImageProvider,
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
                      ],
                    ),
                  ),
                ],
              ),
        actions: [
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
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Container(
              height: _isTyping ? 24.0 : 0.0,
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: _isTyping
                  ? Text(
                      "${participant?.name ?? 'User'} is typing...",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}
