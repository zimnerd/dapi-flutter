import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../providers/providers.dart';
import '../utils/colors.dart';
import '../widgets/conversation_tile.dart';
import '../screens/conversation_screen.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';

// State provider for managing conversations
final conversationsProvider = StateProvider<List<dynamic>>((ref) => []);
final conversationsLoadingProvider = StateProvider<bool>((ref) => false);
final conversationsErrorProvider = StateProvider<String?>((ref) => null);

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize socket connection when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Make sure auth service is properly initialized before proceeding
      await _ensureAuthServiceInitialized();
      _initializeChat();
      _loadConversations();
    });
  }

  Future<void> _ensureAuthServiceInitialized() async {
    final chatService = ref.read(chatServiceProvider);
    final authService = ref.read(authServiceProvider);

    // Explicitly initialize the auth service in the chat service
    chatService.initializeAuthService(authService);
    print('Auth service explicitly initialized in messages screen');

    // Small delay to ensure initialization completes
    await Future.delayed(const Duration(milliseconds: 100));
  }

  void _initializeChat() {
    final chatService = ref.read(chatServiceProvider);
    chatService.initSocket(); // Initialize socket

    // Listen for new messages and update conversations list
    chatService.onNewMessage.listen((message) {
      _loadConversations(); // Refresh conversations when a new message arrives
    });
  }

  Future<void> _loadConversations() async {
    final chatService = ref.read(chatServiceProvider);

    // Set loading state
    ref.read(conversationsLoadingProvider.notifier).state = true;
    ref.read(conversationsErrorProvider.notifier).state = null;

    try {
      final conversations = await chatService.getConversations();
      ref.read(conversationsProvider.notifier).state = conversations;
      ref.read(conversationsLoadingProvider.notifier).state = false;
    } catch (e) {
      print('Error loading conversations: $e');
      ref.read(conversationsLoadingProvider.notifier).state = false;
      ref.read(conversationsErrorProvider.notifier).state =
          'Could not load conversations';
    }
  }

  void _navigateToConversation(dynamic conversation) {
    try {
      // Convert dynamic conversation to Conversation model if needed
      final conversationModel = Conversation.fromJson(conversation);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ConversationScreen(conversation: conversationModel),
        ),
      ).then((_) {
        // Refresh conversations when returning from conversation screen
        _loadConversations();
      });
    } catch (e) {
      print('Error navigating to conversation: $e');
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Could not open conversation. Error: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildConversationsList() {
    final conversations = ref.watch(conversationsProvider);
    final bool isLoading = ref.watch(conversationsLoadingProvider);
    final String? errorMessage = ref.watch(conversationsErrorProvider);

    if (isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: ErrorDisplay(
          message: errorMessage,
          onRetry: () {
            _loadConversations();
          },
        ),
      );
    }

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Match with someone to start chatting',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadConversations();
      },
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          // Safely convert conversation data to Conversation model
          try {
            final conversationModel = Conversation.fromJson(conversation);
            return ConversationTile(
              conversation: conversationModel,
              onTap: () => _navigateToConversation(conversation),
            );
          } catch (e) {
            print('Error rendering conversation at index $index: $e');
            print('Conversation data: $conversation');
            // Return a placeholder for invalid conversations
            return ListTile(
              title: Text('Invalid conversation data'),
              subtitle: Text('Tap to retry'),
              onTap: () => _loadConversations(),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: _buildConversationsList(),
    );
  }
}
