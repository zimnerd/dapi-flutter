import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../models/user.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/ai_suggestions_provider.dart';
import 'package:giphy_picker/giphy_picker.dart';
import '../config/app_config.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/message.dart';
import '../models/profile.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/ai_suggestions_provider.dart';
import '../providers/providers.dart';
import '../utils/colors.dart';
import '../widgets/message_bubble.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import '../widgets/animated_tap_feedback.dart';
import '../widgets/premium_feature_wrapper.dart';
import '../utils/dummy_data.dart';
import '../providers/chat_message_actions.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Conversation? conversation;
  final Profile? matchProfile;

  const ChatScreen({
    Key? key,
    this.conversation,
    this.matchProfile,
  }) : assert(conversation != null || matchProfile != null),
      super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String _conversationId;
  String? _reactingToMessageId;
  bool _isTextFieldEmpty = true;

  @override
  void initState() {
    super.initState();
    _initializeConversationId();
    _textController.addListener(_textFieldListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _conversationId.isNotEmpty) {
        print("Marking messages as read for $_conversationId");
        ChatMessageActions.markMessagesAsRead(ref, _conversationId);
        _scrollToBottom();
      }
    });
  }

  void _initializeConversationId() {
    if (widget.conversation != null) {
      _conversationId = widget.conversation!.id;
    } else if (widget.matchProfile != null) {
      _conversationId = 'conv_with_${widget.matchProfile!.id}';
    } else {
      _conversationId = 'fallback_conv_id';
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_textFieldListener);
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _textFieldListener() {
    if (mounted) {
      final bool isCurrentlyEmpty = _textController.text.trim().isEmpty;
      if (isCurrentlyEmpty != _isTextFieldEmpty) {
        setState(() {
          _isTextFieldEmpty = isCurrentlyEmpty;
        });
      }
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (jump) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    final messageText = text.trim();
    _textController.clear();

    ChatMessageActions.addMessage(ref, _conversationId, messageText);

    _scrollToBottom(jump: true);
    return;
  }

  Future<void> _pickGif() async {
    GiphyGif? gif;
    try {
      gif = await GiphyPicker.pickGif(
        context: context,
        apiKey: AppConfig.giphyApiKey,
      );
    } catch (e) {
       print("Error picking GIF: $e");
       ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open GIF picker: ${e.toString()}')),
       );
    }

    if (gif != null && gif.images.original != null) {
      final gifUrl = gif.images.original!.url;
      print("Selected GIF URL: $gifUrl");
      ChatMessageActions.addMessage(ref, _conversationId, "GIF: ${gifUrl}");
       _scrollToBottom(jump: true);
    } else {
      print("GIF selection cancelled or failed.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(chatMessagesProvider(_conversationId));

    final participantName = widget.conversation?.participants.first.name ?? widget.matchProfile?.name ?? "Chat";
    final participantAvatarUrl = widget.conversation?.participants.first.profilePictures?.isNotEmpty == true
        ? widget.conversation!.participants.first.profilePictures!.first
        : widget.matchProfile?.photoUrls.isNotEmpty == true
            ? widget.matchProfile!.photoUrls.first
            : null;

    ref.listen(chatMessagesProvider(_conversationId), (_, __) {
      _scrollToBottom(jump: messagesAsyncValue.asData?.value.isNotEmpty ?? false);
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: participantAvatarUrl != null
                  ? NetworkImage(participantAvatarUrl)
                  : const AssetImage('assets/images/placeholder_user.png') as ImageProvider,
              radius: 18,
            ),
            const SizedBox(width: 8),
            Text(participantName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Implement call functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            tooltip: 'Start Video Call',
            onPressed: () {
              // TODO: Implement video call initiation
              print("Video call pressed - Placeholder");
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('In-app video calls coming soon!'), duration: Duration(seconds: 2)),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            tooltip: 'Start Audio Call',
            onPressed: () {
              // TODO: Implement audio call initiation
               print("Audio call pressed - Placeholder");
              ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('In-app audio calls coming soon!'), duration: Duration(seconds: 2)),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (String result) {
              if (result == 'unmatch') {
                _handleUnmatch();
              } else if (result == 'report') {
                _handleReport();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'unmatch',
                child: ListTile(
                   leading: Icon(Icons.person_remove_alt_1_outlined),
                   title: Text('Unmatch'),
                 ),
              ),
              PopupMenuItem<String>(
                value: 'report',
                 child: ListTile(
                   leading: Icon(Icons.report_problem_outlined),
                   title: Text('Report ${widget.conversation?.participants.first.name ?? widget.matchProfile?.name ?? "User"}'),
                 ),
              ),
            ],
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsyncValue.when(
              data: (messages) {
                if (messages.isEmpty) return _buildEmptyState(participantName);
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final showAvatar = !message.isFromCurrentUser &&
                        (index == 0 || messages[index - 1].isFromCurrentUser);

                    return _buildMessageBubble(
                      message,
                      showAvatar: showAvatar,
                      participantAvatarUrl: participantAvatarUrl,
                      conversationId: _conversationId,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading messages: $err')),
            ),
          ),
          _buildIcebreakerSuggestions(),
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String name) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with $name',
            style: TextStyle(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, {
    required bool showAvatar,
    required String? participantAvatarUrl,
    required String conversationId,
  }) {
    // Temporarily hardcode this value until we fix the premium providers
    final isPremium = false; // TODO: Fix premium provider reference
    final isFromCurrentUser = message.isFromCurrentUser;
    final bool showReactionsPicker = _reactingToMessageId == message.id;
    final List<String> availableReactions = ['❤️', '👍', '😂', '😢', '😮', '🔥'];

    void _toggleReaction(String emoji) {
      ChatMessageActions.toggleReaction(ref, conversationId, message.id, emoji);
      setState(() {
        _reactingToMessageId = null;
      });
    }

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
                backgroundImage: participantAvatarUrl != null
                    ? NetworkImage(participantAvatarUrl)
                    : const AssetImage('assets/images/placeholder_user.png') as ImageProvider,
                radius: 16,
              ),
            )
          else if (!isFromCurrentUser)
            const SizedBox(width: 40),
            
          Flexible(
            child: Column(
              crossAxisAlignment: isFromCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (showReactionsPicker)
                  Container(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: availableReactions.map((emoji) =>
                        InkWell(
                          onTap: () => _toggleReaction(emoji),
                          child: Text(emoji, style: const TextStyle(fontSize: 14)),
                        )
                      ).toList(),
                    ),
                  ),
                GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _reactingToMessageId = message.id;
                    });
                  },
                  onTap: () {
                    if (_reactingToMessageId != null) {
                       setState(() {
                         _reactingToMessageId = null;
                       });
                    }
                  },
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
                if (message.reactions != null && message.reactions!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Wrap(
                      spacing: 4.0,
                      children: message.reactions!.map((emoji) => Text(emoji, style: const TextStyle(fontSize: 14))).toList(),
                    ),
                  ),
              ],
            ),
          ),
          
          Padding(
             padding: const EdgeInsets.only(left: 6.0, right: 6.0, bottom: 5),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(
                   _formatTime(message.timestamp),
                   style: TextStyle(
                     fontSize: 10,
                     color: Colors.grey[500],
                   ),
                 ),
                 if (isFromCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: _buildReadReceiptIcon(message.status, isPremium),
                    )
               ],
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildReadReceiptIcon(MessageStatus status, bool isPremium) {
    IconData iconData;
    Color iconColor;
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
      case MessageStatus.error:
        iconData = Icons.error_outline;
        iconColor = Colors.red[400]!;
        break;
    }

    return Icon(iconData, size: iconSize, color: iconColor);
  }

  Widget _buildIcebreakerSuggestions() {
    final suggestionsAsyncValue = ref.watch(icebreakerSuggestionsProvider(_conversationId));

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
      ),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 6.0),
            child: Text(
              "Suggested Icebreakers ✨",
               style: Theme.of(context).textTheme.labelMedium?.copyWith(
                 color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
               ),
            ),
          ),
          suggestionsAsyncValue.when(
             data: (suggestions) {
               if (suggestions.isEmpty) {
                  return const SizedBox(height: 40);
               }
               return SizedBox(
                 height: 40,
                 child: ListView.separated(
                   scrollDirection: Axis.horizontal,
                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                   itemCount: suggestions.length,
                   separatorBuilder: (context, index) => const SizedBox(width: 8),
                   itemBuilder: (context, index) {
                     final suggestion = suggestions[index];
                     return ActionChip(
                       label: Text(suggestion),
                       onPressed: () {
                         _textController.text = suggestion;
                         _textController.selection = TextSelection.fromPosition(
                           TextPosition(offset: _textController.text.length),
                         );
                       },
                       backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                       labelStyle: TextStyle(
                         color: Theme.of(context).colorScheme.secondary,
                         fontSize: 13,
                         fontWeight: FontWeight.w500,
                       ),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(20.0),
                         side: BorderSide(color: Theme.of(context).colorScheme.secondary.withOpacity(0.3)),
                       ),
                     );
                   },
                 ),
               );
             },
              loading: () => const SizedBox(
                 height: 40,
                 child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
              ),
              error: (err, stack) => SizedBox(
                 height: 40,
                 child: Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16.0),
                   child: Center(child: Text('Could not load suggestions.', style: TextStyle(color: Colors.red[400], fontSize: 12))),
                 ),
              ),
          ),
         ],
       ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.gif_box_outlined, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
              tooltip: 'Send GIF',
              onPressed: _pickGif,
            ),
            IconButton(
              icon: Icon(Icons.mic_none_outlined, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
              tooltip: 'Send Voice Message',
              onPressed: () {
                // TODO: Implement voice message recording
                print("Voice message button pressed");
                ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Voice messages not implemented yet.'), duration: Duration(seconds: 2)),
                );
              },
            ),
            Expanded(
              child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 8.0),
                 decoration: BoxDecoration(
                   color: Theme.of(context).colorScheme.background.withOpacity(0.8),
                   borderRadius: BorderRadius.circular(25.0),
                 ),
                child: TextField(
                  controller: _textController,
                  onSubmitted: _isTextFieldEmpty ? null : _handleSubmitted, // Only submit if not empty
                  decoration: InputDecoration(
                    hintText: "Send a message...",
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
                    isCollapsed: true, // Reduces intrinsic height
                  ),
                  keyboardType: TextInputType.multiline,
                  maxLines: null, // Allows multiple lines
                  textCapitalization: TextCapitalization.sentences,
                   style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(child: child, scale: animation);
              },
              child: _isTextFieldEmpty
                  ? IconButton(
                      key: const ValueKey('attach_button'), // Example key for Attach
                      icon: Icon(Icons.attach_file, color: Theme.of(context).iconTheme.color?.withOpacity(0.7)),
                      onPressed: () {
                         // TODO: Implement attachment logic
                          print("Attach file button pressed");
                          ScaffoldMessenger.of(context).showSnackBar(
                             const SnackBar(content: Text('Attachments not implemented yet.'), duration: Duration(seconds: 2)),
                          );
                      },
                    )
                  : IconButton(
                      key: const ValueKey('send_button'), // Key for Send
                      icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                      onPressed: () => _handleSubmitted(_textController.text),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _handleUnmatch() async {
    final userName = widget.conversation?.participants.first.name ?? widget.matchProfile?.name ?? "this user";
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Unmatch $userName?'),
          content: Text('You will no longer be able to message or see each other.\nThis cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Unmatch', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      print("Unmatch confirmed for $userName");
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Show success message and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully unmatched $userName.'), duration: Duration(seconds: 2)),
        );
        // Check if the screen can be popped before popping
        if(Navigator.canPop(context)) {
           Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _handleReport() async {
    final userName = widget.conversation?.participants.first.name ?? widget.matchProfile?.name ?? "this user";
    String? selectedReason;
    final detailsController = TextEditingController();

    // Define report reasons
    final List<String> reportReasons = [
      "Inappropriate messages",
      "Spam or scam",
      "Fake profile / Catfishing",
      "Harassment or bullying",
      "Underage user",
      "Other",
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must interact with the dialog
      builder: (BuildContext context) {
        // Use StatefulBuilder to manage the state within the dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Report $userName'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Please select a reason for reporting this user:'),
                    const SizedBox(height: 16),
                    // Radio buttons for reasons
                    ...reportReasons.map((reason) {
                      return RadioListTile<String>(
                        title: Text(reason),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setDialogState(() {
                            selectedReason = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    // Optional details field, shown if 'Other' is selected
                    if (selectedReason == 'Other') ...[
                       const SizedBox(height: 8),
                       TextField(
                          controller: detailsController,
                          maxLines: 2,
                          decoration: InputDecoration(
                             hintText: 'Please provide details (optional)',
                             border: OutlineInputBorder(),
                          ),
                       ),
                    ]
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  // Disable submit button until a reason is selected
                  onPressed: selectedReason == null
                      ? null
                      : () => Navigator.of(context).pop(true),
                  child: Text('Submit Report', style: TextStyle(color: selectedReason == null ? Colors.grey : Colors.red)),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && selectedReason != null) {
      final reportDetails = selectedReason == 'Other' ? detailsController.text : null;
      print("Report confirmed for $userName");
      print("  Reason: $selectedReason");
      if (reportDetails != null && reportDetails.isNotEmpty) {
         print("  Details: $reportDetails");
      }

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted for $userName. Thank you.'), duration: Duration(seconds: 3)),
        );
      }
    }
    detailsController.dispose(); // Dispose the controller
  }
}

class _ReportReasonsDialog extends StatefulWidget {
  final String reportedUserName;
  final Function(String reason, String details) onSubmit;

  const _ReportReasonsDialog({
    required this.reportedUserName,
    required this.onSubmit,
  });

  @override
  State<_ReportReasonsDialog> createState() => _ReportReasonsDialogState();
}

class _ReportReasonsDialogState extends State<_ReportReasonsDialog> {
  final List<String> _reasons = [
    "Spam or Scam",
    "Inappropriate Photos",
    "Inappropriate Messages",
    "Harassment or Abuse",
    "Underage User",
    "Impersonation / Fake Profile",
    "Other",
  ];
  String? _selectedReason;
  final TextEditingController _detailsController = TextEditingController();
  bool _showDetailsField = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.reportedUserName}'),
      content: SingleChildScrollView(
        child: ListBody(
          children: [
            Text('Please select a reason for reporting:', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ..._reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: _selectedReason,
                  onChanged: (value) {
                    setState(() {
                      _selectedReason = value;
                      _showDetailsField = (value == "Other");
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                )),
            if (_showDetailsField)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Please provide more details (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          onPressed: _selectedReason == null
              ? null
              : () {
                  widget.onSubmit(_selectedReason!, _detailsController.text);
                  Navigator.of(context).pop();
                },
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
} 