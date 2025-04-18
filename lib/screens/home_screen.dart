import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import 'discover_screen.dart';
import 'matches_screen.dart';
import 'conversations_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = '';
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      final userName = ref.read(userNameProvider);
      _userName = userName ?? 'User';
      _isLoading = false;
    });
  }
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  Future<void> _logout() async {
    await ref.read(authStateProvider.notifier).logout();
    if (mounted) {
       Navigator.pushReplacementNamed(context, '/login');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final userName = ref.watch(userNameProvider);
    final currentUserName = userName ?? 'User';
    
    return Scaffold(
      appBar: _selectedIndex != 0 && _selectedIndex != 4 ? AppBar(
        title: Text(_isLoading ? 'Loading...' : 'Hi, $currentUserName'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings screen
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ) : null,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Matches',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Events',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody() {
    // Show different screens based on selected tab
    switch (_selectedIndex) {
      case 0: // Discover
        return DiscoverScreen();
      case 1: // Matches
        return MatchesScreen();
      case 2: // Messages
        return ConversationsScreen();
      case 3: // Events
        return EventsScreen();
      case 4: // Profile
        return ProfileScreen();
      default:
        return Center(child: Text('Unknown screen'));
    }
  }
}