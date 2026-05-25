import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_method_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/koditrack_theme.dart';
import '../../widgets/settings_section.dart';
import 'account_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'payment_methods_screen.dart';
import 'rent_reminder_settings_screen.dart';
import 'theme_settings_screen.dart';

/// Full settings list — opened from Profile → Settings.
class SettingsHubScreen extends StatefulWidget {
  const SettingsHubScreen({super.key});

  @override
  State<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends State<SettingsHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentMethodProvider>().fetchMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    final isDark = context.watch<ThemeProvider>().isDark;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SettingsSection(
            title: 'PAYMENTS',
            children: [
              SettingsTile(
                icon: Icons.payments_outlined,
                label: 'Payment Methods',
                subtitle: 'M-Pesa Send Money, Paybill, Till',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PaymentMethodsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'PREFERENCES',
            children: [
              SettingsTile(
                icon: Icons.calendar_month_outlined,
                label: 'Rent & Reminders',
                subtitle: 'Default due day and WhatsApp',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RentReminderSettingsScreen(),
                  ),
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                subtitle: 'Dashboard refresh and overdue rules',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen(),
                  ),
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.palette_outlined,
                label: 'Theme',
                subtitle: isDark ? 'Dark mode' : 'Light mode',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThemeSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SettingsSection(
            title: 'ACCOUNT',
            children: [
              SettingsTile(
                icon: Icons.person_outline,
                label: 'Account',
                subtitle: 'Name, phone, password',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AccountSettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
