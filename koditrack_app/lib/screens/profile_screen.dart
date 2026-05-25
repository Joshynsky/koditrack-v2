import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/supabase_service.dart';
import '../theme/koditrack_theme.dart';
import '../utils/user_display.dart';
import '../widgets/settings_section.dart';
import 'login_screen.dart';
import 'settings/about_screen.dart';
import 'settings/account_settings_screen.dart';
import 'settings/settings_hub_screen.dart';

/// Bottom-nav Profile tab — account summary and entry to Settings.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    final user = SupabaseService.client.auth.currentUser;
    final email = user?.email ?? 'Unknown';
    final displayName = resolveUserDisplayName(context);

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kt.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kt.borderSubtle),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: kt.brandGreenLight,
                    child: Text(
                      displayName[0].toUpperCase(),
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: kt.brandGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to edit account',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          SettingsSection(
            children: [
              SettingsTile(
                icon: Icons.settings_outlined,
                label: 'Settings',
                subtitle: 'Payment, reminders, notifications, theme',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsHubScreen()),
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.info_outline,
                label: 'About KodiTrack',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await SupabaseService.client.auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
