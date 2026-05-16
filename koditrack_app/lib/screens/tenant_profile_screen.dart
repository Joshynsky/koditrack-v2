import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../models/unit.dart';
import 'record_payment_screen.dart';
import 'transaction_history_screen.dart';
import '../services/whatsapp_service.dart';

class TenantProfileScreen extends StatelessWidget {
  final Tenant tenant;
  final Unit? unit;
  final int rentDueDay;

  const TenantProfileScreen({
    super.key,
    required this.tenant,
    this.unit,
    required this.rentDueDay,
  });

  @override
  Widget build(BuildContext context) {
    final balance =
        tenant.openingBalance; // Will be updated when payments exist
    final balanceColor = balance <= 0 ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(title: Text(tenant.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      child: Text(
                        tenant.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      tenant.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (unit != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Unit ${unit!.unitNumber}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Contact info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: tenant.phone,
                    ),
                    if (tenant.email != null) ...[
                      const Divider(),
                      _InfoRow(
                        icon: Icons.email,
                        label: 'Email',
                        value: tenant.email!,
                      ),
                    ],
                    const Divider(),
                    _InfoRow(
                      icon: tenant.whatsappEnabled
                          ? Icons.check_circle
                          : Icons.cancel,
                      label: 'WhatsApp',
                      value: tenant.whatsappEnabled ? 'Enabled' : 'Disabled',
                      valueColor: tenant.whatsappEnabled
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rent details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rent Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InfoRow(
                      icon: Icons.home,
                      label: 'Base Rent',
                      value: 'KES ${tenant.baseRent.toStringAsFixed(0)}',
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.build,
                      label: 'Service Charge',
                      value: 'KES ${tenant.serviceCharge.toStringAsFixed(0)}',
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.calendar_today,
                      label: 'Due Day',
                      value: '${_getDayText(rentDueDay)} of each month',
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.receipt_long,
                      label: 'Total Monthly',
                      value:
                          'KES ${tenant.totalMonthlyBill.toStringAsFixed(0)}',
                      valueBold: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Balance card
            Card(
              color: balance <= 0
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Current Balance',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'KES ${balance.toStringAsFixed(0)}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: balanceColor,
                          ),
                    ),
                    Text(
                      balance <= 0 ? 'All paid up' : 'Outstanding',
                      style: TextStyle(color: balanceColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Record Payment button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecordPaymentScreen(
                        tenant: tenant,
                        onPaymentRecorded: () {},
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.payments),
                label: const Text('Record Payment'),
              ),
            ),
            const SizedBox(height: 12),

            // Transaction history button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionHistoryScreen(tenant: tenant),
                    ),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('View Payment History'),
              ),
            ),
            const SizedBox(height: 12),

            // WhatsApp buttons
            if (tenant.whatsappEnabled) ...[
              // Send Reminder
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.tonalIcon(
                  onPressed: () async {
                    final propertyName = unit != null
                        ? 'Property' // We don't have property name here, could pass it
                        : 'your building';
                    final message = WhatsAppService.reminderMessage(
                      name: tenant.name,
                      unitNumber: unit?.unitNumber ?? 'N/A',
                      propertyName: propertyName,
                      dueDay: rentDueDay,
                      totalDue: tenant.totalMonthlyBill + (tenant.openingBalance > 0 ? tenant.openingBalance : 0),
                    );
                    final success = await WhatsAppService.sendMessage(
                      tenant.phone,
                      message,
                    );
                    if (!success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open WhatsApp')),
                      );
                    }
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('Send Reminder'),
                ),
              ),
              const SizedBox(height: 8),

              // Overdue Nudge (only if balance > 0)
              if (tenant.openingBalance > 0)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final dueDate = DateTime(now.year, now.month, rentDueDay);
                      final daysOverdue = now.day > rentDueDay
                          ? now.difference(dueDate).inDays
                          : 0;

                      final message = WhatsAppService.overdueMessage(
                        name: tenant.name,
                        unitNumber: unit?.unitNumber ?? 'N/A',
                        daysOverdue: daysOverdue,
                        balance: tenant.openingBalance,
                      );
                      final success = await WhatsAppService.sendMessage(
                        tenant.phone,
                        message,
                      );
                      if (!success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not open WhatsApp')),
                        );
                      }
                    },
                    icon: const Icon(Icons.warning_amber),
                    label: const Text('Send Overdue Nudge'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ),
            ] else ...[
              // WhatsApp disabled warning
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WhatsApp reminders are disabled for this tenant.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDayText(int day) {
    if (day == 1) return '1st';
    if (day == 2) return '2nd';
    if (day == 3) return '3rd';
    return '${day}th';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: valueBold ? FontWeight.bold : null,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
