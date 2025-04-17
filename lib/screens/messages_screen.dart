import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../providers/providers.dart';
import '../providers/auth_provider.dart';
// import '../providers/chat_provider.dart'; // Removed, using DummyData for now
import '../utils/colors.dart';
import '../widgets/conversation_tile.dart';
import '../screens/conversation_screen.dart'; // FIX: Correct import path
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';
import '../utils/dummy_data.dart'; // FIX: Import DummyData

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToConversation(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(conversation: conversation),
      ),
    ).then((_) {
    });
  }

  Widget _buildConversationsList() {
    final conversations = DummyData.getConversations();
    final bool isLoading = false;
    final String? errorMessage = null;

    if (isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: ErrorDisplay(
          message: errorMessage,
          onRetry: () {
            print("Retry triggered - Provider needed");
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
        print("Refresh triggered - Provider needed");
      },
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: conversations.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return ConversationTile(
            conversation: conversation,
            onTap: () => _navigateToConversation(conversation),
          );
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