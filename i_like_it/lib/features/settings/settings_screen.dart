import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/auth/user_session_manager.dart';
import '../../core/database/database_helper.dart';
import '../../core/sync/sync_manager.dart';
import '../../core/theme/theme_manager.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_screen.dart';
import '../onboarding/initial_setup_screen.dart';
import 'recovery_settings.dart';
import '../../core/widgets/gradient_scaffold.dart'; // New
import '../../core/widgets/glass_container.dart'; // New

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      // Re-check role (or pass it in)
      // Optimization: Could pass this from FolderScreen, but fetching here is safe too
      // Assuming role is checked by SyncManager's datasource or session
      // For now, simpler: let's re-use the logic from FolderScreen or just fetch
      final role = await SyncManager.instance.remoteDataSource.fetchUserRole();
      if (mounted && role == 'admin') {
        setState(() => _isAdmin = true);
      }
        } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GradientScaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance'),
          const SizedBox(height: 12),
          _buildThemeSelector(),
          
          const SizedBox(height: 32),
          _buildSectionHeader('Account'),
          const SizedBox(height: 12),
          
          _buildSettingsTile(
            icon: Icons.person,
            title: 'Account Settings',
            subtitle: 'Manage your email',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecoverySettingsScreen()),
              );
            },
          ),
          
          if (_isAdmin) ...[
            const SizedBox(height: 12),
            _buildSettingsTile(
              icon: Icons.admin_panel_settings,
              title: 'Admin Dashboard',
              subtitle: 'Manage users and system',
              iconColor: colorScheme.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminScreen()),
                );
              },
            ),
          ],
          
          const SizedBox(height: 12),
          _buildSettingsTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out and clear local data',
            iconColor: colorScheme.error,
            textColor: colorScheme.error,
            onTap: _handleLogout,
          ),
          
          const SizedBox(height: 48),
          Center(
            child: Text(
              'I Like It v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.instance.themeModeNotifier,
      builder: (context, currentMode, _) {
        return GlassContainer(
          padding: EdgeInsets.zero,
          enableBlur: false, // Optimize performance
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              _buildRadioTile('System Default', ThemeMode.system, currentMode),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildRadioTile('Light Mode', ThemeMode.light, currentMode),
              Divider(height: 1, color: Theme.of(context).dividerColor.withOpacity(0.2)),
              _buildRadioTile('Dark Mode', ThemeMode.dark, currentMode),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadioTile(String title, ThemeMode mode, ThemeMode current) {
    final isSelected = mode == current;
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: () => ThemeManager.instance.setThemeMode(mode),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    
    return GlassContainer(
      padding: EdgeInsets.zero,
      enableBlur: false, // Optimize performance
      borderRadius: BorderRadius.circular(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (iconColor ?? theme.colorScheme.onSurface).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon, 
                    color: iconColor ?? theme.colorScheme.onSurface, 
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: textColor ?? theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                             color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded, 
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Are you sure you want to log out? You will need to verify your email to sign back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
      await UserSessionManager.clearSession();
      await DatabaseHelper.instance.clearAllData();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const InitialSetupScreen()),
          (route) => false,
        );
      }
    }
  }
}
