import 'package:flutter/material.dart';
import '../models/match.dart';
import '../utils/colors.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final VoidCallback onTap;

  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 120, // Fixed height
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 40,
                backgroundImage:
                    NetworkImage(match.matchedUser.profilePictures.first),
              ),
              const SizedBox(width: 16),
              // Match Info
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min, // Use minimum space
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match.matchedUser.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.matchedUser.location is Map
                          ? '${match.matchedUser.location['city']}, ${match.matchedUser.location['country']}'
                          : match.matchedUser.location?.toString() ??
                              'Unknown location',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.lastMessage ?? 'Start a conversation!',
                      style: TextStyle(
                        fontSize: 14,
                        color: match.lastMessage != null
                            ? Colors.black87
                            : AppColors.primary,
                        fontStyle: match.lastMessage != null
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Icon(
          Icons.person,
          size: 50,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
