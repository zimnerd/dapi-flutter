import 'package:flutter/material.dart';
import '../utils/colors.dart'; // Assuming AppColors are defined here

class InterestBadge extends StatelessWidget {
  final String interest;
  final VoidCallback? onDeleted; // Optional: For profile editing screen

  const InterestBadge({
    super.key,
    required this.interest,
    this.onDeleted,
  });

  // Simple mapping of interest keywords to icons (expand as needed)
  static final Map<String, IconData> _interestIcons = {
    // General
    'reading': Icons.menu_book,
    'writing': Icons.edit_note,
    'movies': Icons.theaters,
    'music': Icons.music_note,
    'gaming': Icons.sports_esports,
    'travel': Icons.flight_takeoff,
    'food': Icons.restaurant,
    'cooking': Icons.soup_kitchen,
    'baking': Icons.cake,
    'photography': Icons.camera_alt,
    'art': Icons.palette,
    'dancing': Icons.nightlife, // Or a specific dance icon if available
    'singing': Icons.mic,
    'fashion': Icons.checkroom,
    'technology': Icons.computer,
    'science': Icons.science,
    'history': Icons.history_edu,
    'politics': Icons.gavel,
    'volunteering': Icons.volunteer_activism,
    'animals': Icons.pets,
    'dogs': Icons.pets, // More specific
    'cats': Icons.pets, // More specific
    'gardening': Icons.local_florist,

    // Activities / Sports
    'hiking': Icons.hiking,
    'camping': Icons.landscape, // Or Icons.terrain
    'running': Icons.directions_run,
    'walking': Icons.directions_walk,
    'cycling': Icons.directions_bike,
    'swimming': Icons.pool,
    'yoga': Icons.self_improvement,
    'meditation': Icons.self_improvement,
    'gym': Icons.fitness_center,
    'weights': Icons.fitness_center,
    'climbing': Icons.filter_hdr, // Or a specific climbing icon
    'skiing': Icons.downhill_skiing,
    'snowboarding': Icons.snowboarding,
    'surfing': Icons.surfing,
    'sailing': Icons.sailing,
    'kayaking': Icons.kayaking,
    'soccer': Icons.sports_soccer,
    'basketball': Icons.sports_basketball,
    'tennis': Icons.sports_tennis,
    'golf': Icons.sports_golf,
    'baseball': Icons.sports_baseball,
    'football': Icons.sports_football, // American football

    // Default/Fallback
    'default': Icons.interests, // Generic fallback
  };

  // Helper function to get icon based on interest text
  IconData _getIconForInterest(String interestText) {
    final lowerCaseInterest = interestText.toLowerCase();
    // Try direct match first
    if (_interestIcons.containsKey(lowerCaseInterest)) {
      return _interestIcons[lowerCaseInterest]!;
    }
    // Try matching keywords within the interest text
    for (var keyword in _interestIcons.keys) {
      if (lowerCaseInterest.contains(keyword) && keyword != 'default') {
        return _interestIcons[keyword]!;
      }
    }
    // Return default icon if no match found
    return _interestIcons['default']!;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForInterest(interest);

    // Define badge style
    final Color backgroundColor = AppColors.primaryLight.withOpacity(0.6);
    final Color foregroundColor = AppColors.primary; // Or AppColors.textDark?
    final double borderRadius = 16.0;
    final double paddingHorizontal =
        onDeleted != null ? 6.0 : 12.0; // Less padding if delete icon exists
    final double paddingVertical = 8.0;

    Widget badgeContent = Row(
      mainAxisSize: MainAxisSize.min, // Keep row tight
      children: [
        Icon(icon, size: 16, color: foregroundColor),
        const SizedBox(width: 6),
        Text(
          interest,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w500,
            fontSize: 13, // Slightly smaller text
          ),
        ),
      ],
    );

    // Wrap with Chip structure only if onDeleted is provided (for the 'x' button)
    if (onDeleted != null) {
      return Chip(
        padding: EdgeInsets.symmetric(
            horizontal: paddingHorizontal,
            vertical: paddingVertical - 4), // Chip adds its own padding
        labelPadding:
            EdgeInsets.only(left: 4), // Adjust label padding if needed
        avatar: Icon(icon,
            size: 16, color: foregroundColor), // Use avatar for icon in Chip
        label: Text(
          interest,
          style: TextStyle(
            color: foregroundColor,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        backgroundColor: backgroundColor,
        onDeleted: onDeleted,
        deleteIcon: Icon(Icons.close,
            size: 16, color: foregroundColor.withOpacity(0.7)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side:
              BorderSide(color: Colors.transparent), // Hide default Chip border
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    } else {
      // Use a simple Container for display-only badges
      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: paddingHorizontal, vertical: paddingVertical),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: badgeContent,
      );
    }
  }
}
