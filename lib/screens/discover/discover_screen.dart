import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/profile.dart';
import '../../widgets/profile_card.dart';
import '../../utils/colors.dart';

// Filter provider definition
final profileFiltersProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {
    'minAge': 18,
    'maxAge': 50,
    'distance': 50,
    'gender': ['female', 'male', 'non-binary'],
  };
});

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  
  List<Profile> _profiles = [];
  bool _isLoading = false;
  String? _error;
  int _currentProfileIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.2).animate(_controller);
    
    // Wrap autoLogin in Future.microtask to avoid Riverpod state modification during build
    Future.microtask(() => _autoLogin());
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Filter listener will be automatically removed when the widget is disposed
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _autoLogin() async {
    final authState = ref.read(authStateProvider);
    if (authState.status == AuthStatus.authenticated) {
      await _fetchProfiles();
    }
  }

  Future<void> _fetchProfiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profileService = ref.read(profileServiceProvider);
      final profiles = await profileService.getDiscoverProfiles();
      
      if (mounted) {
        setState(() {
          _profiles = profiles;
          _isLoading = false;
          _currentProfileIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load profiles: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _handleFilterUpdate() {
    // Reload profiles with new filters
    _fetchProfiles();
  }

  void _handleLike() {
    if (_currentProfileIndex >= _profiles.length) return;
    
    // Apply animation
    _controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _currentProfileIndex++;
      });
      _controller.reset();
    });
    
    // In a real app, send like to API
    final currentProfile = _profiles[_currentProfileIndex];
    print('Liked profile: ${currentProfile.name}');
  }

  void _handleDislike() {
    if (_currentProfileIndex >= _profiles.length) return;
    
    // Apply animation
    _controller.forward().then((_) {
      if (!mounted) return;
      setState(() {
        _currentProfileIndex++;
      });
      _controller.reset();
    });
    
    // In a real app, send dislike to API
    final currentProfile = _profiles[_currentProfileIndex];
    print('Disliked profile: ${currentProfile.name}');
  }

  @override
  Widget build(BuildContext context) {
    // Listen to filter changes
    ref.listen<Map<String, dynamic>>(profileFiltersProvider, (previous, next) {
      if (previous != next) {
        _handleFilterUpdate();
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Show filters dialog/screen
              Navigator.pushNamed(context, '/filters');
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProfiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_profiles.isEmpty) {
      return const Center(
        child: Text('No profiles available at the moment. Check back later!'),
      );
    }

    if (_currentProfileIndex >= _profiles.length) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No more profiles available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchProfiles,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    // Show current profile card with action buttons
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ProfileCard(
                profile: _profiles[_currentProfileIndex],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                icon: Icons.close,
                color: Colors.red,
                onPressed: _handleDislike,
              ),
              _buildActionButton(
                icon: Icons.favorite,
                color: AppColors.primary,
                onPressed: _handleLike,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 32),
        onPressed: onPressed,
        padding: const EdgeInsets.all(16),
      ),
    );
  }
}