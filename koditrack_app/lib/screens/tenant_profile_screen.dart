import 'package:flutter/material.dart';
import '../models/tenant.dart';
import '../models/unit.dart';
import '../theme/koditrack_theme.dart';
import 'record_payment_screen.dart';
import 'transaction_history_screen.dart';
import '../services/whatsapp_service.dart';

class TenantProfileScreen extends StatelessWidget {
  final Tenant tenant;
  final Unit? unit;
  final int rentDueDay;
  final String? propertyName;
  final String? paymentInstructions;

  const TenantProfileScreen({
    super.key,
    required this.tenant,
    this.unit,
    required this.rentDueDay,
    this.propertyName,
    this.paymentInstructions,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.kt;
    final balance = tenant.openingBalance;
    final monthlyBill = tenant.totalMonthlyBill;
    final owesMoreThanMonth = balance > monthlyBill;

    final Color balanceBg;
    final String statusText;
    final Color statusColor;

    if (balance <= 0) {
      balanceBg = colors.brandGreenLight;
      statusText = 'All paid up';
      statusColor = colors.brandGreen;
    } else if (owesMoreThanMonth) {
      balanceBg = colors.accentRedLight;
      statusText = 'Overdue';
      statusColor = colors.accentRed;
    } else {
      balanceBg = colors.accentAmberLight;
      statusText = 'Partially paid';
      statusColor = colors.accentAmber;
    }

    final initials = tenant.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      backgroundColor: colors.pageBackground,
      appBar: AppBar(
        title: const Text('Tenant Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Profile header ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: colors.brandGreenLight,
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: colors.brandGreen,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(tenant.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  if (unit != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.chipBackground,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        'Unit ${unit!.unitNumber}${unit!.block != null ? ' · Block ${unit!.block}' : ''} · Floor ${unit!.floor ?? '?'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Balance card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: balanceBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text('Current Balance',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor.withValues(alpha: 0.8))),
                        const SizedBox(height: 6),
                        Text('KES ${balance.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: statusColor)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(statusText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _MiniStat(label: 'Monthly', value: 'KES ${monthlyBill.toStringAsFixed(0)}'),
                      Container(width: 1, height: 24, color: colors.borderSubtle),
                      _MiniStat(label: 'Base Rent', value: 'KES ${tenant.baseRent.toStringAsFixed(0)}'),
                      Container(width: 1, height: 24, color: colors.borderSubtle),
                      _MiniStat(label: 'Service', value: 'KES ${tenant.serviceCharge.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('Due: ${_dayText(rentDueDay)} of each month',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tenant.whatsappEnabled ? colors.brandGreenLight : colors.chipBackground,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          tenant.whatsappEnabled ? 'WhatsApp ON' : 'WhatsApp OFF',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: tenant.whatsappEnabled ? colors.brandGreen : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Contact info ──
            Container(
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                children: [
                  _ContactRow(icon: Icons.phone, label: 'Phone', value: tenant.phone),
                  if (tenant.email != null) ...[
                    Divider(height: 1, indent: 50, color: colors.borderSubtle),
                    _ContactRow(icon: Icons.email, label: 'Email', value: tenant.email!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Actions ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => RecordPaymentScreen(tenant: tenant, onPaymentRecorded: () {})));
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colors.brandGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.payments),
                label: const Text('Record Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colors.borderSubtle),
              ),
              child: Column(
                children: [
                  _ActionRow(icon: Icons.history, label: 'Payment History', onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => TransactionHistoryScreen(tenant: tenant)));
                  }),
                  if (tenant.whatsappEnabled) ...[
                    Divider(height: 1, indent: 50, color: colors.borderSubtle),
                    _ActionRow(icon: Icons.notifications, label: 'Send Reminder', onTap: () async {
                      final message = WhatsAppService.reminderMessage(
                        name: tenant.name,
                        unitNumber: unit?.unitNumber ?? 'N/A',
                        propertyName: propertyName ?? 'your building',
                        dueDay: rentDueDay,
                        totalDue: monthlyBill + (balance > 0 ? balance : 0),
                        paymentInstructions: paymentInstructions,
                      );
                      await WhatsAppService.sendMessage(tenant.phone, message);
                    }),
                  ],
                  if (tenant.whatsappEnabled && balance > 0) ...[
                    Divider(height: 1, indent: 50, color: colors.borderSubtle),
                    _ActionRow(icon: Icons.warning_amber, label: 'Send Overdue Nudge', iconColor: Colors.orange, onTap: () async {
                      final now = DateTime.now();
                      final dueDate = DateTime(now.year, now.month, rentDueDay);
                      final daysOverdue = now.day > rentDueDay ? now.difference(dueDate).inDays : 0;
                      final message = WhatsAppService.overdueMessage(
                        name: tenant.name,
                        unitNumber: unit?.unitNumber ?? 'N/A',
                        daysOverdue: daysOverdue,
                        balance: balance,
                        paymentInstructions: paymentInstructions,
                      );
                      await WhatsAppService.sendMessage(tenant.phone, message);
                    }),
                  ],
                  if (!tenant.whatsappEnabled) ...[
                    Divider(height: 1, indent: 50, color: colors.borderSubtle),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: Colors.grey),
                          SizedBox(width: 10),
                          Text('WhatsApp disabled for this tenant', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  static String _dayText(int day) {
    if (day == 1) return '1st';
    if (day == 2) return '2nd';
    if (day == 3) return '3rd';
    return '${day}th';
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _ContactRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;
  const _ActionRow({required this.icon, required this.label, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.kt;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? colors.brandGreen),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}