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
import '../providers/matches_provider.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_display.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newMatches = ref.watch(newMatchesProvider);
    final matches = ref.watch(matchesProvider);
    final likes = ref.watch(likesProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Matches & Likes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Matches'),
              Tab(text: 'Likes'),
              Tab(text: 'Conversations'),
            ],
          ),
        ),
        body: Column(
          children: [
            // New Matches Carousel
            newMatches.when(
              data: (matches) => matches.isEmpty
                  ? const SizedBox.shrink()
                  : SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/conversation',
                                arguments: match.id,
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundImage: NetworkImage(
                                      match.matchedUser.profilePictures.first,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    match.matchedUser.name,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  const Text(
                                    'New Match!',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
              loading: () => const SizedBox(
                height: 120,
                child: Center(child: LoadingIndicator()),
              ),
              error: (error, stack) => SizedBox(
                height: 120,
                child: Center(
                  child: ErrorDisplay(message: error.toString()),
                ),
              ),
            ),

            // Divider if new matches exist
            newMatches.when(
              data: (matches) =>
                  matches.isEmpty ? const SizedBox.shrink() : const Divider(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Matches, Likes, and Conversations Tabs
            Expanded(
              child: TabBarView(
                children: [
                  // Matches Tab
                  matches.when(
                    data: (matches) => matches.isEmpty
                        ? const Center(
                            child: Text('No matches yet. Keep swiping!'))
                        : ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final match = matches[index];
                              return MatchCard(
                                match: match,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/conversation',
                                  arguments: match.id,
                                ),
                              );
                            },
                          ),
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (error, stack) => Center(
                      child: ErrorDisplay(message: error.toString()),
                    ),
                  ),

                  // Likes Tab
                  likes.when(
                    data: (profiles) => profiles.isEmpty
                        ? const Center(
                            child: Text('No likes yet. Keep being awesome!'))
                        : GridView.builder(
                            padding: const EdgeInsets.all(8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: profiles.length,
                            itemBuilder: (context, index) {
                              final profile = profiles[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Expanded(
                                      child: Image.network(
                                        profile.profilePictures.first,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${profile.age} • ${profile.location}',
                                            style:
                                                const TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (error, stack) => Center(
                      child: ErrorDisplay(message: error.toString()),
                    ),
                  ),

                  // Conversations Tab
                  matches.when(
                    data: (matches) => matches.isEmpty
                        ? const Center(
                            child:
                                Text('No conversations yet. Start chatting!'))
                        : ListView.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final match = matches[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(
                                    match.matchedUser.profilePictures.first,
                                  ),
                                ),
                                title: Text(match.matchedUser.name),
                                subtitle: Text(
                                  match.lastMessage ?? 'Start a conversation!',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: match.lastMessageAt != null
                                    ? Text(
                                        _formatLastMessageTime(
                                            match.lastMessageAt!),
                                        style: const TextStyle(fontSize: 12),
                                      )
                                    : null,
                                onTap: () => Navigator.pushNamed(
                                  context,
                                  '/conversation',
                                  arguments: match.id,
                                ),
                              );
                            },
                          ),
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (error, stack) => Center(
                      child: ErrorDisplay(message: error.toString()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}
