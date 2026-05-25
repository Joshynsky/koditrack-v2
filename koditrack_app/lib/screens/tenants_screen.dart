import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tenant.dart';
import '../providers/property_provider.dart';
import '../theme/koditrack_theme.dart';
import 'tenant_profile_screen.dart';

class TenantsScreen extends StatefulWidget {
  const TenantsScreen({super.key});

  @override
  State<TenantsScreen> createState() => _TenantsScreenState();
}

class _TenantsScreenState extends State<TenantsScreen> {
  List<Tenant> _allTenants = [];
  List<Tenant> _filteredTenants = [];
  bool _loading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllTenants();
  }

  Future<void> _loadAllTenants() async {
    setState(() => _loading = true);
    final provider = context.read<PropertyProvider>();
    await provider.fetchProperties();

    final tenants = <Tenant>[];
    for (final property in provider.properties) {
      await provider.fetchTenants(property.id);
      tenants.addAll(provider.selectedPropertyTenants);
    }

    if (mounted) {
      setState(() {
        _allTenants = tenants;
        _filteredTenants = tenants;
        _loading = false;
      });
    }
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredTenants = _allTenants;
      } else {
        _filteredTenants = _allTenants
            .where((t) =>
                t.name.toLowerCase().contains(query.toLowerCase()) ||
                t.phone.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    return Scaffold(
      appBar: AppBar(title: const Text('Tenants'), centerTitle: true),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: kt.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Summary row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                _SummaryChip(
                  label: '${_allTenants.length} total',
                  color: kt.brandGreen,
                  bgColor: kt.brandGreenLight,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label:
                      '${_allTenants.where((t) => t.openingBalance > 0).length} owe',
                  color: kt.accentRed,
                  bgColor: kt.accentRedLight,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label:
                      '${_allTenants.where((t) => t.openingBalance <= 0).length} paid',
                  color: kt.brandGreenDark,
                  bgColor: kt.brandGreenLight,
                ),
                if (_searchQuery.isNotEmpty) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () => _filter(''),
                    child: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),

          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredTenants.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No tenants match "$_searchQuery"'
                              : 'No tenants yet',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: context.cs.onSurfaceVariant,
                              ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAllTenants,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filteredTenants.length,
                          itemBuilder: (context, index) {
                            final tenant = _filteredTenants[index];
                            return _TenantCard(tenant: tenant);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary chip ──────────────────────────────────────────────────────────

class _SummaryChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _SummaryChip({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─── Tenant card ───────────────────────────────────────────────────────────

class _TenantCard extends StatelessWidget {
  final Tenant tenant;

  const _TenantCard({required this.tenant});

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    final balance = tenant.openingBalance;
    final bool inCredit = balance < 0;
    final bool owes = balance > 0;
    final bool isClean = balance == 0;

    // Dynamic colours per state
    final Color accentColor;
    final Color accentBg;
    final Color accentDark;
    final String statusLabel;

    if (owes) {
      accentColor = kt.accentRed;
      accentBg = kt.accentRedLight;
      accentDark = kt.accentRedDark;
      statusLabel = 'owes';
    } else if (inCredit) {
      accentColor = kt.brandGreen;
      accentBg = kt.brandGreenLight;
      accentDark = kt.brandGreenDark;
      statusLabel = 'in credit';
    } else {
      accentColor = kt.accentAmber;
      accentBg = kt.accentAmberLight;
      accentDark = kt.accentAmberDark;
      statusLabel = 'settled';
    }

    final initials = tenant.name
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final displayBalance = balance.abs();

    return Card(
      color: kt.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: owes
            ? BorderSide(color: kt.accentRed.withValues(alpha: 0.25))
            : BorderSide(color: kt.borderSubtle),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: accentBg,
          child: Text(
            initials,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: accentDark,
            ),
          ),
        ),
        title: Text(tenant.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Row(
          children: [
            Icon(Icons.phone_outlined, size: 13, color: context.cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(tenant.phone,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'KES ${_fmt(displayBalance)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: accentColor,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: accentBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                inCredit ? 'credit' : statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: accentDark,
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TenantProfileScreen(
                tenant: tenant,
                rentDueDay: 5,
              ),
            ),
          );
        },
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