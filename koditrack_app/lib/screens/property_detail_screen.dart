import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../models/tenant.dart';
import '../providers/payment_method_provider.dart';
import '../providers/property_provider.dart';
import '../theme/koditrack_theme.dart';
import 'add_unit_screen.dart';
import 'add_tenant_screen.dart';
import 'property_form_screen.dart';
import 'tenant_profile_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  // Local state — immune to dashboard refreshes
  List<Unit> _units = [];
  List<Tenant> _tenants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    final provider = context.read<PropertyProvider>();
    
    await Future.wait([
      provider.fetchUnits(widget.property.id),
      provider.fetchTenants(widget.property.id),
    ]);
    
    if (mounted) {
      setState(() {
        _units = List.from(provider.selectedPropertyUnits);
        _tenants = List.from(provider.selectedPropertyTenants);
        _loading = false;
      });
    }
  }

  Tenant? _getTenantForUnit(String unitId) {
    try {
      return _tenants.firstWhere((t) => t.unitId == unitId);
    } catch (_) {
      return null;
    }
  }

  Map<String?, Map<int, List<Unit>>> _groupUnits(List<Unit> units) {
    final map = <String?, Map<int, List<Unit>>>{};
    for (final u in units) {
      final block = u.block;
      final floor = u.floor ?? 1;
      map.putIfAbsent(block, () => {});
      map[block]!.putIfAbsent(floor, () => []);
      map[block]![floor]!.add(u);
    }
    for (final block in map.values) {
      for (final floor in block.values) {
        floor.sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
      }
    }
    return map;
  }

  Widget _buildFloorHeader(int floor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Floor $floor',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: Colors.grey.withValues(alpha: 0.15))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    final dueDayText = widget.property.rentDueDay == 1 ? '1st' : '${widget.property.rentDueDay}th';

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.property.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('Due: $dueDayText of each month', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit property',
            onPressed: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyFormScreen(property: widget.property),
                ),
              );
              if (updated == true && mounted) {
                await context.read<PropertyProvider>().fetchProperties();
                final list = context.read<PropertyProvider>().properties;
                final refreshed = list.where((p) => p.id == widget.property.id).firstOrNull;
                if (refreshed != null && mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailScreen(property: refreshed),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add-tenant',
            backgroundColor: kt.brandGreen,
            foregroundColor: kt.onPrimaryButton,
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTenantScreen(propertyId: widget.property.id, rentDueDay: widget.property.rentDueDay),
                ),
              );
              if (result == true && mounted) _fetchData();
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Tenant'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add-unit',
            backgroundColor: kt.cardBackground,
            foregroundColor: kt.brandGreen,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddUnitScreen(propertyId: widget.property.id, propertyName: widget.property.name),
                ),
              );
              if (mounted) _fetchData();
            },
            icon: Icon(Icons.add, color: kt.brandGreen),
            label: Text('Add Units', style: TextStyle(color: kt.brandGreen)),
          ),
        ],
      ),
      body: _loading && _units.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _units.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: kt.brandGreen,
                  onRefresh: _fetchData,
                  child: _buildContent(_units),
                ),
    );
  }

  Widget _buildEmptyState() {
    final kt = context.kt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.meeting_room_outlined, size: 80, color: kt.brandGreen.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No units yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Tap + to add your first unit', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Unit> units) {
    final vacant = units.where((u) => u.status == 'vacant').length;
    final occupied = units.where((u) => u.status == 'occupied').length;
    final grouped = _groupUnits(units);
    final hasMultipleBlocks = grouped.length > 1 || (grouped.length == 1 && grouped.keys.first != null);
    final sortedBlocks = grouped.keys.toList()..sort((a, b) => (a ?? 'ZZ').compareTo(b ?? 'ZZ'));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        _buildStatsCard(units.length, occupied, vacant),
        const SizedBox(height: 20),
        for (final block in sortedBlocks) ...[
          if (hasMultipleBlocks) _buildBlockHeader(block),
          if (hasMultipleBlocks) const SizedBox(height: 12),
          for (final floor in grouped[block]!.keys.toList()..sort()) ...[
            _buildFloorHeader(floor),
            const SizedBox(height: 8),
            _buildUnitGrid(grouped[block]![floor]!),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildStatsCard(int total, int occupied, int vacant) {
    final kt = context.kt;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kt.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kt.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(label: 'Total', value: '$total', icon: Icons.apartment, color: kt.brandGreen),
          Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.15)),
          _StatItem(label: 'Occupied', value: '$occupied', icon: Icons.person, color: Colors.orange),
          Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.15)),
          _StatItem(label: 'Vacant', value: '$vacant', icon: Icons.check_circle_outline, color: kt.brandGreen),
        ],
      ),
    );
  }

  Widget _buildBlockHeader(String? block) {
    final kt = context.kt;
    final label = block ?? 'Unassigned';
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: kt.brandGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: kt.brandGreen.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.domain, size: 14, color: kt.brandGreen),
            const SizedBox(width: 6),
            Text('Block $label', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kt.brandGreen)),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitGrid(List<Unit> blockUnits) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.15,
      ),
      itemCount: blockUnits.length,
      itemBuilder: (context, index) {
        final unit = blockUnits[index];
        final tenant = _getTenantForUnit(unit.id);
        return _UnitCard(
          unit: unit,
          tenant: tenant,
          onAddTenant: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTenantScreen(propertyId: widget.property.id, rentDueDay: widget.property.rentDueDay, preSelectedUnitId: unit.id),
              ),
            );
            if (result == true && mounted) _fetchData();
          },
          onTap: tenant != null
              ? () {
                  final pay = context.read<PaymentMethodProvider>().getById(widget.property.paymentMethodId);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TenantProfileScreen(
                        tenant: tenant,
                        unit: unit,
                        rentDueDay: widget.property.rentDueDay,
                        propertyName: widget.property.name,
                        paymentInstructions: pay?.paymentInstructions,
                      ),
                    ),
                  );
                }
              : null,
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _UnitCard extends StatelessWidget {
  final Unit unit;
  final Tenant? tenant;
  final VoidCallback onAddTenant;
  final VoidCallback? onTap;
  const _UnitCard({required this.unit, this.tenant, required this.onAddTenant, this.onTap});

  Color _statusColor(BuildContext context) {
    switch (unit.status) {
      case 'occupied': return Colors.orange;
      case 'maintenance': return Colors.grey;
      default: return context.kt.brandGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = tenant != null;
    final kt = context.kt;
    return Card(
      color: kt.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: kt.borderSubtle)),
      child: InkWell(
        onTap: isOccupied ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(unit.unitNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: _statusColor(context), shape: BoxShape.circle)),
                ],
              ),
              const SizedBox(height: 2),
              Text('Floor ${unit.floor ?? '?'} · ${unit.unitType ?? 'Unit'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              const Spacer(),
              if (isOccupied) ...[
                Text(tenant!.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('KES ${tenant!.totalMonthlyBill.toStringAsFixed(0)}/mo', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ] else ...[
                Text('Vacant', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  height: 26,
                  child: OutlinedButton(
                    onPressed: onAddTenant,
                    style: OutlinedButton.styleFrom(padding: EdgeInsets.zero, textStyle: const TextStyle(fontSize: 11), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
                    child: const Text('＋ Add Tenant'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}