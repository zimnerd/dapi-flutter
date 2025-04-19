import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/message_provider.dart';
import '../../providers/typing_provider.dart';
import '../../utils/colors.dart';
import '../../utils/logger.dart';

class MessageInput extends ConsumerStatefulWidget {
  final String conversationId;
  final FocusNode? focusNode;
  final bool isOnline;
  final VoidCallback? onMessageSent;

  const MessageInput({
    Key? key,
    required this.conversationId,
    this.focusNode,
    this.isOnline = true,
    this.onMessageSent,
  }) : super(key: key);

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;
  final Logger _logger = Logger('MessageInput');

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _typingTimer?.cancel();
    // Make sure to stop typing indicator when disposed
    if (_isTyping) {
      _stopTyping();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    
    // Start typing indicator
    if (text.isNotEmpty && !_isTyping) {
      _startTyping();
    }
    
    // Reset typing timer
    _typingTimer?.cancel();
    if (text.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
    } else if (_isTyping) {
      _stopTyping();
    }
  }

  void _startTyping() {
    _isTyping = true;
    try {
      ref.read(typingUsersProvider.notifier).sendTypingStart(widget.conversationId);
      _logger.debug('⟹ [MessageInput] Started typing in ${widget.conversationId}');
    } catch (e) {
      _logger.error('Failed to send typing status: $e');
    }
  }

  void _stopTyping() {
    if (!_isTyping) return;
    
    _isTyping = false;
    _typingTimer?.cancel();
    _typingTimer = null;
    
    try {
      ref.read(typingUsersProvider.notifier).sendTypingStop(widget.conversationId);
      _logger.debug('⟹ [MessageInput] Stopped typing in ${widget.conversationId}');
    } catch (e) {
      _logger.error('Failed to send typing status: $e');
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    try {
      // Clear text first for responsive feel
      _controller.clear();
      
      // Stop typing indicator
      _stopTyping();
      
      // Send message
      ref.read(messagesProvider.notifier).sendMessage(widget.conversationId, text);
      _logger.debug('⟹ [MessageInput] Sent message in ${widget.conversationId}');
      
      // Call callback if provided
      widget.onMessageSent?.call();
    } catch (e) {
      _logger.error('Failed to send message: $e');
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          // Attachment button (optional)
          IconButton(
            icon: Icon(
              Icons.photo,
              color: AppColors.primary,
            ),
            onPressed: () {
              // TODO: Implement attachment feature
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Attachments coming soon!'),
                ),
              );
            },
          ),
          
          // Text field
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: widget.focusNode,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: widget.isOnline 
                    ? 'Type a message...' 
                    : 'Offline mode - messages will be sent when back online',
                hintStyle: TextStyle(
                  color: widget.isOnline 
                      ? AppColors.textSecondary 
                      : AppColors.error.withOpacity(0.7),
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
              ),
              enabled: true, // Always enabled, even when offline
            ),
          ),
          
          // Send button
          Container(
            margin: const EdgeInsets.only(left: 8.0),
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(24.0),
                onTap: _sendMessage,
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 