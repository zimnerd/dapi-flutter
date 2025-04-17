import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/biometric_service.dart';
import '../providers/auth_provider.dart';
import '../providers/providers.dart';
import '../utils/colors.dart';
import '../screens/profile_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final BiometricService _biometricService = BiometricService();
  
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _isLoading = true;
  String? _userEmail;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final biometricAvailable = await _biometricService.isBiometricAvailable();
      final biometricEnabled = await _biometricService.isBiometricEnabled();
      _userEmail = ref.read(userEmailProvider);
      
      setState(() {
        _biometricAvailable = biometricAvailable;
        _biometricEnabled = biometricEnabled;
      });
    } catch (e) {
      print('Error loading biometric settings: $e');
    } finally {
      if (mounted) {
         setState(() {
           _isLoading = false;
         });
      }
    }
  }
  
  Future<void> _toggleBiometricAuth(bool value) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (value) {
        final email = ref.read(userEmailProvider);
        
        if (email != null && email.isNotEmpty) {
          final success = await _biometricService.enableBiometrics(email);
          if (mounted) {
             setState(() {
               _biometricEnabled = success;
             });
          }
        } else {
          if (mounted) {
            setState(() {
               _biometricEnabled = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Unable to enable biometric login. User email not found.')),
            );
          }
        }
      } else {
        final success = await _biometricService.disableBiometrics();
        if (mounted) {
          setState(() {
             _biometricEnabled = !success;
          });
        }
      }
    } catch (e) {
      print('Error toggling biometric auth: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error changing biometric settings: $e')),
        );
      }
    } finally {
       if (mounted) {
          setState(() {
            _isLoading = false;
          });
       }
    }
  }

  Future<void> _logout() async {
     await ref.read(authStateProvider.notifier).logout();
     if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
     }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account Settings Section
                    _buildSectionHeader('Account Settings'),
                    _buildSettingsCard(
                      child: Column(
                        children: [
                          _buildSettingsItem(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen())),
                          ),
                          const Divider(),
                          _buildSettingsItem(
                            icon: Icons.lock_outline,
                            title: 'Change Password',
                            onTap: () => print("Navigate to change password"),
                          ),
                          const Divider(),
                          _buildSettingsItem(
                            icon: Icons.email_outlined,
                            title: 'Email Preferences',
                            onTap: () => print("Navigate to email preferences"),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // App Settings Section
                    _buildSectionHeader('App Settings'),
                    _buildSettingsCard(
                      child: Column(
                        children: [
                          _buildSwitchItem(
                            icon: Icons.dark_mode_outlined,
                            title: 'Dark Mode',
                            value: _darkModeEnabled,
                            onChanged: (value) {
                              setState(() {
                                _darkModeEnabled = value;
                              });
                            },
                          ),
                          const Divider(),
                          _buildSwitchItem(
                            icon: Icons.notifications_outlined,
                            title: 'Push Notifications',
                            value: _notificationsEnabled,
                            onChanged: (value) {
                              setState(() {
                                _notificationsEnabled = value;
                              });
                            },
                          ),
                          const Divider(),
                          _buildSwitchItem(
                            icon: Icons.location_on_outlined,
                            title: 'Enable Location',
                            value: _locationEnabled,
                            onChanged: (value) {
                              setState(() {
                                _locationEnabled = value;
                              });
                            },
                          ),
                          if (_biometricAvailable) ...[
                            const Divider(),
                            _buildSwitchItem(
                              icon: Icons.fingerprint,
                              title: 'Biometric Login',
                              subtitle: _biometricEnabled 
                                  ? 'Enabled for ${_userEmail ?? "your account"}' 
                                  : 'Quick login with fingerprint or face',
                              value: _biometricEnabled,
                              onChanged: _toggleBiometricAuth,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Support Section
                    _buildSectionHeader('Support'),
                    _buildSettingsCard(
                      child: Column(
                        children: [
                          _buildSettingsItem(
                            icon: Icons.help_outline,
                            title: 'Help Center',
                            onTap: () => print("Navigate to Help Center"),
                          ),
                          const Divider(),
                          _buildSettingsItem(
                            icon: Icons.privacy_tip_outlined,
                            title: 'Privacy Policy',
                            onTap: () => print("Navigate to Privacy Policy"),
                          ),
                          const Divider(),
                          _buildSettingsItem(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            onTap: () => print("Navigate to Terms"),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Logout Button
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _logout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildSectionHeader(String title, {Color color = Colors.black87}) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 12.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
  
  Widget _buildSettingsCard({required Widget child, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
  
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color titleColor = Colors.black87,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
} 