import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // For launching URLs
// Assuming AppColors

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  // Helper to launch URLs safely
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Handle error: could not launch URL
      print('Could not launch $urlString');
      // Optionally show a snackbar to the user
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Center'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ??
            Theme.of(context).colorScheme.onSurface,
        elevation: Theme.of(context).appBarTheme.elevation ?? 1.0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Your safety is our priority. Find resources and tips below.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // --- Safety Tools Section ---
          _buildSectionHeader(context, 'Safety Tools'),
          _buildSafetyTile(
            context,
            icon: Icons.report_problem_outlined,
            title: 'Reporting Users',
            subtitle: 'Learn how to report inappropriate behavior.',
            onTap: () {
              // TODO: Navigate to a detailed reporting guide or show info dialog
              print('Reporting Users tapped');
            },
          ),
          _buildSafetyTile(
            context,
            icon: Icons.block,
            title: 'Blocking Users',
            subtitle: 'Manage users you have blocked.',
            onTap: () {
              // TODO: Navigate to blocked users list screen
              print('Blocking Users tapped');
            },
          ),
          _buildSafetyTile(
            context,
            icon: Icons.security_outlined,
            title: 'Profile Verification',
            subtitle: 'Learn about our verification process.',
            onTap: () {
              // TODO: Navigate to verification info/start screen
              print('Profile Verification tapped');
            },
          ),
          const Divider(height: 32),

          // --- Tips & Resources Section ---
          _buildSectionHeader(context, 'Tips & Resources'),
          _buildSafetyTile(
            context,
            icon: Icons.lightbulb_outline,
            title: 'Safe Dating Tips',
            subtitle: 'Advice for meeting online matches safely.',
            onTap: () {
              // TODO: Navigate to safe dating tips screen/article
              print('Safe Dating Tips tapped');
            },
          ),
          _buildSafetyTile(
            context,
            icon: Icons.shield_outlined,
            title: 'Online Safety Guide',
            subtitle: 'Protecting your personal information.',
            onTap: () {
              // TODO: Navigate to online safety guide screen/article
              print('Online Safety Guide tapped');
            },
          ),
          _buildSafetyTile(
            context,
            icon: Icons.groups_outlined,
            title: 'Community Guidelines',
            subtitle: 'Our rules for respectful interaction.',
            onTap: () {
              // TODO: Navigate to community guidelines screen/page
              print('Community Guidelines tapped');
            },
          ),
          const Divider(height: 32),

          // --- External Resources Section ---
          _buildSectionHeader(context, 'External Resources'),
          _buildSafetyTile(
            context,
            icon: Icons.emergency_outlined,
            title: 'Emergency Help',
            subtitle: 'Find resources for immediate assistance.',
            onTap: () {
              // TODO: Link to relevant external emergency resources (e.g., RAINN, local hotlines)
              // Example: _launchURL('https://www.rainn.org');
              print('Emergency Help tapped');
              _launchURL(
                  'https://www.google.com/search?q=emergency+help+resources'); // Placeholder Search
            },
          ),
          _buildSafetyTile(
            context,
            icon: Icons.health_and_safety_outlined,
            title: 'Health & Wellbeing',
            subtitle: 'Resources for mental and sexual health.',
            onTap: () {
              // TODO: Link to relevant external health resources
              print('Health & Wellbeing tapped');
              _launchURL(
                  'https://www.google.com/search?q=mental+sexual+health+resources'); // Placeholder Search
            },
          ),
        ],
      ),
    );
  }

  // Helper widget for section headers
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  // Helper widget for safety list tiles
  Widget _buildSafetyTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading:
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      // hoverColor: Theme.of(context).colorScheme.primary.withOpacity(0.05),
    );
  }
}
