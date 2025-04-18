import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/profile.dart';
import '../models/conversation.dart';
import '../widgets/empty_state.dart';
import '../utils/colors.dart';
import '../utils/dummy_data.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../widgets/match_card.dart';
import '../widgets/conversation_card.dart';
import 'conversation_screen.dart';
import '../providers/subscription_provider.dart';
import 'premium_screen.dart';
import '../providers/providers.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  _MatchesScreenState createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMatches() async {
    print("Fetching matches...");
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _fetchConversations() async {
    print("Fetching conversations...");
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> _startConversation(Profile match) async {
    print("Starting conversation with ${match.name}");
  }

  Widget _buildMatchesTab() {
    final matches = DummyData.getMatches();

    if (matches.isEmpty) {
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
        itemCount: matches.length,
        itemBuilder: (context, index) {
          return MatchCard(
            profile: matches[index],
            onTap: () => _startConversation(matches[index]),
          );
        },
      ),
    );
  }

  Widget _buildConversationsTab() {
    final conversations = DummyData.getConversations();

    if (conversations.isEmpty) {
      return const Center(
        child: Text('No conversations yet. Start chatting with your matches!'),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchConversations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          if (index >= conversations.length) {
            print("⟹ [MatchesScreen] Index out of range in conversation list: $index/${conversations.length}");
            return const SizedBox.shrink();
          }
          
          final conversation = conversations[index];
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

    if (!isPremium) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.favorite_outline, size: 70, color: AppColors.primary.withOpacity(0.6)),
              const SizedBox(height: 16),
              Text(
                'See Who Likes You!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Upgrade to Premium to see everyone who already liked your profile and match instantly.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                height: 44,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.star_border_purple500_outlined, size: 18),
                  label: const Text('Go Premium'),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const PremiumScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('People who liked you will appear here.', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 20),
        ],
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
            Tab(icon: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [Icon(Icons.favorite_border), SizedBox(width: 4), Text('Likes')],
            )),
            Tab(text: 'Conversations'),
          ],
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