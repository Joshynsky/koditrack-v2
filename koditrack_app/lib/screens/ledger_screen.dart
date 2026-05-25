import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../providers/property_provider.dart';
import '../theme/koditrack_theme.dart';

class LedgerScreen extends StatefulWidget {
  const LedgerScreen({super.key});

  @override
  State<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends State<LedgerScreen> {
  String _searchQuery = '';
  String? _methodFilter; // null = all, 'M-Pesa', 'Cash', 'Bank Transfer'
  bool _searchVisible = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchAllPayments();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Filtering & grouping ─────────────────────────────────────────────

  List<Payment> _filter(List<Payment> payments) {
    return payments.where((p) {
      if (_methodFilter != null && p.paymentMethod != _methodFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (p.tenantName ?? '').toLowerCase();
        final ref = (p.reference ?? '').toLowerCase();
        return name.contains(q) || ref.contains(q);
      }
      return true;
    }).toList();
  }

  Map<String, List<Payment>> _groupByDate(List<Payment> payments) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<Payment>> groups = {};

    for (final p in payments) {
      final date = DateTime(p.paymentDate.year, p.paymentDate.month, p.paymentDate.day);
      String label;

      if (date == today) {
        label = 'Today';
      } else if (date == yesterday) {
        label = 'Yesterday';
      } else {
        label = '${date.day}/${date.month}/${date.year}';
      }

      groups.putIfAbsent(label, () => []);
      groups[label]!.add(p);
    }

    return groups;
  }

  // ─── Summary calculations ─────────────────────────────────────────────

  Map<String, dynamic> _getSummary(List<Payment> payments) {
    final now = DateTime.now();
    double total = 0;
    int mpesa = 0, cash = 0, bank = 0;

    for (final p in payments) {
      if (p.paymentDate.year == now.year && p.paymentDate.month == now.month) {
        total += p.amount;
      }
      final method = (p.paymentMethod ?? '').toLowerCase();
      if (method.contains('mpesa')) {
        mpesa++;
      } else if (method.contains('cash')) cash++;
      else if (method.contains('bank')) bank++;
    }

    return {
      'total': total,
      'count': payments.length,
      'mpesa': mpesa,
      'cash': cash,
      'bank': bank,
    };
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  // ─── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    return Scaffold(
      appBar: AppBar(
        title: _searchVisible
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search name or ref...',
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Ledger'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_searchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _searchVisible = !_searchVisible;
                if (!_searchVisible) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.selectedTenantPayments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = provider.selectedTenantPayments;
          final filtered = _filter(all);
          final summary = _getSummary(all);
          final groups = _groupByDate(filtered);

          return RefreshIndicator(
            onRefresh: () => provider.fetchAllPayments(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                _buildSummaryCard(context, summary),
                const SizedBox(height: 14),
                _buildFilterChips(context),
                const SizedBox(height: 16),

                // ── Grouped list ──
                if (filtered.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text(
                        'No payments match your filters',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: context.cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                  )
                else
                  ...groups.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(context, entry.key, entry.value.length),
                          const SizedBox(height: 8),
                          ...entry.value.map((p) => _PaymentRow(payment: p)),
                          const SizedBox(height: 16),
                        ],
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Summary card ─────────────────────────────────────────────────────

  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> s) {
    final kt = context.kt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kt.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kt.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: kt.brandGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text('This Month',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'KES ${_fmt(s['total'])}',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: kt.brandGreenDark),
          ),
          const SizedBox(height: 6),
          Text(
            '${s['count']} payments · ${s['mpesa']} M-Pesa · ${s['cash']} Cash · ${s['bank']} Bank',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final kt = context.kt;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: _methodFilter == null,
            onTap: () => setState(() => _methodFilter = null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'M-Pesa',
            selected: _methodFilter == 'M-Pesa',
            color: kt.brandGreen,
            bgColor: kt.brandGreenLight,
            onTap: () => setState(() => _methodFilter = 'M-Pesa'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Cash',
            selected: _methodFilter == 'Cash',
            color: kt.accentAmber,
            bgColor: kt.accentAmberLight,
            onTap: () => setState(() => _methodFilter = 'Cash'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Bank',
            selected: _methodFilter == 'Bank Transfer',
            color: kt.accentBlue,
            bgColor: kt.accentBlueLight,
            onTap: () => setState(() => _methodFilter = 'Bank Transfer'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String label, int count) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 6),
        Text('· $count',
            style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ─── Filter chip widget ──────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final Color? bgColor;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? (bgColor ?? kt.brandGreenLight) : kt.cardBackground,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? (color ?? kt.brandGreen).withValues(alpha: 0.4)
                : kt.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? (color ?? kt.brandGreen)
                : context.cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─── Payment row ─────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final Payment payment;

  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    final method = payment.paymentMethod ?? '';
    final isMpesa = method.toLowerCase().contains('mpesa');
    final isCash = method.toLowerCase().contains('cash');

    final Color iconColor;
    final Color iconBg;
    final IconData icon;

    if (isMpesa) {
      iconColor = kt.accentTeal;
      iconBg = kt.accentTealLight;
      icon = Icons.phone_android;
    } else if (isCash) {
      iconColor = kt.accentAmber;
      iconBg = kt.accentAmberLight;
      icon = Icons.money;
    } else {
      iconColor = kt.accentBlue;
      iconBg = kt.accentBlueLight;
      icon = Icons.account_balance;
    }

    return Card(
      color: kt.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: kt.borderSubtle),
      ),
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.tenantName ?? 'Tenant',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        method,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                      if (payment.reference != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: context.cs.onSurfaceVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'REF: ${payment.reference}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: context.cs.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '+${_fmt(payment.amount)}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kt.accentTeal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
}