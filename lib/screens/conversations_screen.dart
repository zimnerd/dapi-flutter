import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../utils/colors.dart';
import '../providers/providers.dart';
import '../widgets/conversation_list_item.dart';
import '../utils/logger.dart';

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key});

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  List<Conversation>? _conversations;
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _getCurrentUserId();
    await _loadConversations();
  }

  Future<void> _getCurrentUserId() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.getCurrentUser();
      setState(() {
        _currentUserId = user.id;
      });
    } catch (e) {
      logger.error('Error getting current user: $e');
    }
  }

  Future<void> _loadConversations() async {
    if (_currentUserId == null) {
      setState(() {
        _errorMessage = 'Not logged in';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chatService = ref.read(chatServiceProvider);
      final dynamicConversations = await chatService.getConversations();

      // Convert dynamic data to Conversation objects
      final conversations = dynamicConversations.map((data) {
        return Conversation.fromJson(data);
      }).toList();

      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      logger.error('Error loading conversations: $e');
      setState(() {
        _errorMessage = 'Could not load conversations';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: AppColors.primary,
            ),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConversations,
        color: AppColors.primary,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_conversations == null || _conversations!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.primary.withAlpha((0.5 * 255).toInt()),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Match with someone to start a conversation',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to discover screen
                Navigator.pushNamed(context, '/discover');
              },
              icon: const Icon(Icons.person_search),
              label: const Text('Find Matches'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    // Sort conversations by the most recent message
    final sortedConversations = List<Conversation>.from(_conversations!)
      ..sort((a, b) {
        final aTime =
            a.lastMessage != null ? a.lastMessage!.timestamp : a.updatedAt;
        final bTime =
            b.lastMessage != null ? b.lastMessage!.timestamp : b.updatedAt;
        return bTime.compareTo(aTime); // Descending: most recent first
      });

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: sortedConversations.length,
      itemBuilder: (context, index) {
        return ConversationListItem(
          conversation: sortedConversations[index],
          currentUserId: _currentUserId!,
        );
      },
    );
  }
}
