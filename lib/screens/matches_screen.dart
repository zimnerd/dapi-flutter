import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../widgets/empty_state.dart';
import '../utils/colors.dart';
import '../services/chat_service.dart';
import '../services/profile_service.dart';
import 'chat_screen.dart';
import '../widgets/match_card.dart';
import '../widgets/conversation_card.dart';
import 'conversation_screen.dart';
import '../providers/subscription_provider.dart';
import 'premium_screen.dart';
import '../providers/providers.dart';
import '../utils/logger.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Profile> _matches = [];
  List<Profile> _likes = [];
  List<Conversation> _conversations = [];
  String? _error;
  final _logger = Logger('MatchesScreen');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait(
          [_fetchMatches(), _fetchLikes(), _fetchConversations()]);
    } catch (e) {
      setState(() {
        _error = "Failed to load data. Please try again.";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMatches() async {
    try {
      final profileService = ref.read(profileServiceProvider);
      // We'll use the discover API to get matches for now
      final matches = await profileService.getDiscoverProfiles(limit: 20);
      setState(() {
        _matches = matches;
      });
    } catch (e) {
      _logger.error("Error fetching matches: $e");
      // Don't set error here, we'll let the parent method handle it
    }
  }

  Future<void> _fetchLikes() async {
    try {
      final profileService = ref.read(profileServiceProvider);
      // This would be a separate API endpoint in a real app
      // For now we'll just use a subset of discover profiles
      final likes = await profileService.getDiscoverProfiles(limit: 10);
      setState(() {
        _likes = likes;
      });
    } catch (e) {
      _logger.error("Error fetching likes: $e");
    }
  }

  Future<void> _fetchConversations() async {
    try {
      final chatService = ref.read(chatServiceProvider);
      final dynamicConversations = await chatService.getConversations();

      // Convert dynamic data to Conversation objects
      final conversations = dynamicConversations.map((data) {
        // Create Conversation object from JSON data
        return Conversation.fromJson(data);
      }).toList();

      setState(() {
        _conversations = conversations;
      });
    } catch (e) {
      _logger.error("Error fetching conversations: $e");
    }
  }

  Future<void> _startConversation(Profile match) async {
    try {
      final chatService = ref.read(chatServiceProvider);

      // Try to create conversation via API
      Conversation conversation;
      try {
        // Try to create a real conversation through the API
        final apiConversation = await chatService.createConversation(match.id);
        conversation = apiConversation;
      } catch (e) {
        _logger.error("Error creating conversation via API: $e");
        // Create a mock conversation as fallback
        final currentUserId = ref.read(userIdProvider);
        final currentUserName = ref.read(userNameProvider);

        if (currentUserId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Cannot create conversation: Not logged in')),
            );
          }
          return;
        }

        // Create a local conversation object for demo purposes
        conversation = Conversation(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
          participants: [
            User(
              id: currentUserId,
              email: '',
              name: currentUserName ?? 'You',
            ),
            User(
              id: match.id,
              email: '',
              name: match.name,
            ),
          ],
          lastMessage: Message(
            id: 'msg-temp',
            conversationId: 'temp-conv',
            senderId: match.id,
            text: 'Demo conversation - API failed, using mock data',
            timestamp: DateTime.now(),
            status: MessageStatus.sent,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          unreadCount: 0,
        );
      }

      // Navigate to conversation screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversation: conversation,
            ),
          ),
        ).then((_) => _fetchConversations());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to start conversation: ${e.toString()}')),
        );
      }
    }
  }

  Widget _buildMatchesTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_matches.isEmpty) {
      return const Center(
        child: Text('No matches yet. Keep swiping!'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMatches,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _matches.length,
        itemBuilder: (context, index) {
          return MatchCard(
            profile: _matches[index],
            onTap: () => _startConversation(_matches[index]),
          );
        },
      ),
    );
  }

  Widget _buildConversationsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchInitialData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Text('No conversations yet. Start chatting with your matches!'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          if (index >= _conversations.length) {
            _logger.error(
                "Index out of range in conversation list: $index/${_conversations.length}");
            return const SizedBox.shrink();
          }

          final conversation = _conversations[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ConversationCard(
              conversation: conversation,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ConversationScreen(
                      conversation: conversation,
                    ),
                  ),
                ).then((_) => _fetchConversations());
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLikesTab() {
    final isPremiumAsync = ref.watch(premiumProvider);
    bool isPremium = false;

    // Extract the value from AsyncValue
    isPremiumAsync.whenData((value) {
      isPremium = value;
    });

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!isPremium) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.favorite_outline,
                  size: 70, color: AppColors.primary.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'See Who Likes You!',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Upgrade to Premium to see everyone who already liked your profile and match instantly.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 44,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star_border_purple500_outlined,
                      size: 18),
                  label: const Text('Go Premium'),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PremiumScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_likes.isEmpty) {
      return const Center(
        child: Text('No one has liked you yet. Keep improving your profile!'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLikes,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _likes.length,
        itemBuilder: (context, index) {
          return MatchCard(
            profile: _likes[index],
            onTap: () => _startConversation(_likes[index]),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches & Likes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Matches'),
            Tab(text: 'Likes'),
            Tab(text: 'Conversations'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3.0,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMatchesTab(),
          _buildLikesTab(),
          _buildConversationsTab(),
        ],
      ),
    );
  }
}
