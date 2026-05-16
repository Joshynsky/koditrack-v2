import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../models/unit.dart';
import '../models/tenant.dart';
import '../providers/property_provider.dart';
import 'add_unit_screen.dart';
import 'add_tenant_screen.dart';
import 'tenant_profile_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PropertyProvider>();
      provider.fetchUnits(widget.property.id);
      provider.fetchTenants(widget.property.id);
    });
  }

  Tenant? _getTenantForUnit(String unitId) {
    final tenants = context.read<PropertyProvider>().selectedPropertyTenants;
    try {
      return tenants.firstWhere((t) => t.unitId == unitId);
    } catch (_) {
      return null;
    }
  }

  void _showQuickGenerateDialog() {
    final floorsController = TextEditingController(text: '1');
    final unitsController = TextEditingController(text: '1');
    String? unitType;
    final rentController = TextEditingController();
    bool generating = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final floors = int.tryParse(floorsController.text) ?? 1;
            final unitsPerFloor = int.tryParse(unitsController.text) ?? 1;
            final total = floors * unitsPerFloor;

            return AlertDialog(
              title: const Text('Quick Generate Units'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: floorsController,
                            decoration: const InputDecoration(
                              labelText: 'Floors',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: unitsController,
                            decoration: const InputDecoration(
                              labelText: 'Units/Floor',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: unitType,
                      decoration: const InputDecoration(
                        labelText: 'Unit Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          [
                                '1-Bedroom',
                                '2-Bedroom',
                                'Studio',
                                'Shop',
                                'Office',
                                'Other',
                              ]
                              .map(
                                (t) =>
                                    DropdownMenuItem(value: t, child: Text(t)),
                              )
                              .toList(),
                      onChanged: (v) => setDialogState(() => unitType = v),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: rentController,
                      decoration: const InputDecoration(
                        labelText: 'Default Rent (KES)',
                        hintText: 'Optional',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.apartment,
                            color: Theme.of(ctx).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Will create $total unit${total == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(ctx).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: generating ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: generating
                      ? null
                      : () async {
                          setDialogState(() => generating = true);
                          try {
                            await context
                                .read<PropertyProvider>()
                                .generateUnits(
                                  propertyId: widget.property.id,
                                  floors: floors,
                                  unitsPerFloor: unitsPerFloor,
                                  unitType: unitType,
                                  defaultRent:
                                      rentController.text.trim().isEmpty
                                      ? null
                                      : double.tryParse(
                                          rentController.text.trim(),
                                        ),
                                );
                            if (mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$total units created!'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setDialogState(() => generating = false);
                            }
                          }
                        },
                  child: generating
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Generate $total'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.property.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Quick Generate Units',
            onPressed: _showQuickGenerateDialog,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add-tenant',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddTenantScreen(
                    propertyId: widget.property.id,
                    rentDueDay: widget.property.rentDueDay,
                  ),
                ),
              );
              if (result == true && mounted) {
                context.read<PropertyProvider>().fetchUnits(widget.property.id);
                context.read<PropertyProvider>().fetchTenants(
                  widget.property.id,
                );
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add Tenant'),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'add-unit',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddUnitScreen(propertyId: widget.property.id),
                ),
              );
              if (mounted) {
                context.read<PropertyProvider>().fetchUnits(widget.property.id);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Unit'),
          ),
        ],
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.selectedPropertyUnits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final units = provider.selectedPropertyUnits;

          if (units.isEmpty) {
            return _buildEmptyState();
          }

          return _buildUnitSummary(units);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 80,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text('No units yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Add your first unit or generate in bulk',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _showQuickGenerateDialog,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Quick Generate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitSummary(List<Unit> units) {
    final vacant = units.where((u) => u.status == 'vacant').length;
    final occupied = units.where((u) => u.status == 'occupied').length;

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<PropertyProvider>().fetchUnits(widget.property.id);
        await context.read<PropertyProvider>().fetchTenants(widget.property.id);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _StatItem(
                    label: 'Total',
                    value: units.length.toString(),
                    icon: Icons.apartment,
                  ),
                  _StatItem(
                    label: 'Occupied',
                    value: occupied.toString(),
                    icon: Icons.person,
                    color: Colors.orange,
                  ),
                  _StatItem(
                    label: 'Vacant',
                    value: vacant.toString(),
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              final tenant = _getTenantForUnit(unit.id);
              return _UnitCard(
                unit: unit,
                tenant: tenant,
                onAddTenant: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AddTenantScreen(
                        propertyId: widget.property.id,
                        rentDueDay: widget.property.rentDueDay,
                        preSelectedUnitId: unit.id,
                      ),
                    ),
                  );
                  if (result == true && mounted) {
                    context.read<PropertyProvider>().fetchUnits(
                      widget.property.id,
                    );
                    context.read<PropertyProvider>().fetchTenants(
                      widget.property.id,
                    );
                  }
                },
                onTap: tenant != null
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TenantProfileScreen(
                              tenant: tenant,
                              unit: unit,
                              rentDueDay: widget.property.rentDueDay,
                            ),
                          ),
                        );
                      }
                    : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _UnitCard extends StatelessWidget {
  final Unit unit;
  final Tenant? tenant;
  final VoidCallback onAddTenant;
  final VoidCallback? onTap;

  const _UnitCard({
    required this.unit,
    this.tenant,
    required this.onAddTenant,
    this.onTap,
  });

  Color _statusColor() {
    switch (unit.status) {
      case 'occupied':
        return Colors.orange;
      case 'maintenance':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOccupied = tenant != null;

    return Card(
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
                  Flexible(
                    child: Text(
                      unit.unitNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              if (isOccupied) ...[
                const SizedBox(height: 4),
                Text(
                  tenant!.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'KES ${tenant!.totalMonthlyBill.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ] else ...[
                const Spacer(),
                Text(
                  'Vacant',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
              const Spacer(),
              if (!isOccupied)
                SizedBox(
                  width: double.infinity,
                  height: 28,
                  child: OutlinedButton(
                    onPressed: onAddTenant,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Add Tenant'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
