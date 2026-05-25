import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../theme/koditrack_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _autoRefresh = true;
  int _graceDays = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<SettingsProvider>().profile;
    if (p != null) {
      _autoRefresh = p.dashboardAutoRefresh;
      _graceDays = p.overdueGraceDays;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await context.read<SettingsProvider>().updateProfile(
            settingsPatch: {
              'dashboard_auto_refresh': _autoRefresh,
              'overdue_grace_days': _graceDays,
            },
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dashboard auto-refresh'),
            subtitle: const Text('Refresh dashboard data every 15 seconds'),
            value: _autoRefresh,
            activeThumbColor: kt.brandGreen,
            onChanged: (v) => setState(() => _autoRefresh = v),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _graceDays,
            decoration: InputDecoration(
              labelText: 'Overdue grace period (days)',
              helperText: 'Extra days after due date before showing as overdue',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: kt.cardBackground,
            ),
            items: [0, 1, 2, 3, 5, 7]
                .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d == 0 ? 'None' : '$d days'),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _graceDays = v);
            },
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: kt.brandGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
