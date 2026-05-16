import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/property_provider.dart';
import 'create_property_screen.dart';
import 'property_detail_screen.dart';
<<<<<<< HEAD
import '../services/whatsapp_service.dart';
import '../models/tenant.dart';
=======
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
<<<<<<< HEAD
  double _expected = 0;
  double _received = 0;

=======
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
<<<<<<< HEAD
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<PropertyProvider>();
    await provider.fetchProperties();
    final summary = await provider.getMonthlySummary();
    if (mounted) {
      setState(() {
        _expected = summary['expected'] ?? 0;
        _received = summary['received'] ?? 0;
      });
    }
  }

  Future<void> _showOverdueDialog() async {
    final provider = context.read<PropertyProvider>();
    
    // Collect all overdue tenants
    final now = DateTime.now();
    final overdueTenants = <Map<String, dynamic>>[];

    for (final property in provider.properties) {
      await provider.fetchTenants(property.id);
      
      for (final tenant in provider.selectedPropertyTenants) {
        if (tenant.openingBalance > 0 && tenant.whatsappEnabled) {
          final dueDate = DateTime(now.year, now.month, property.rentDueDay);
          final daysOverdue = now.day > property.rentDueDay
              ? now.difference(dueDate).inDays
              : 0;
          
          if (daysOverdue > 0) {
            // Find unit name
            String unitName = 'N/A';
            try {
              await provider.fetchUnits(property.id);
              final unit = provider.selectedPropertyUnits
                  .where((u) => u.id == tenant.unitId)
                  .firstOrNull;
              if (unit != null) unitName = unit.unitNumber;
            } catch (_) {}
            
            overdueTenants.add({
              'tenant': tenant,
              'propertyName': property.name,
              'unitName': unitName,
              'daysOverdue': daysOverdue,
              'rentDueDay': property.rentDueDay,
            });
          }
        }
      }
    }

    if (!mounted) return;

    if (overdueTenants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No overdue tenants — everyone is up to date! 🎉')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Overdue Tenants (${overdueTenants.length})'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: overdueTenants.length,
            itemBuilder: (_, index) {
              final item = overdueTenants[index];
              final tenant = item['tenant'] as Tenant;
              
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: const Icon(Icons.warning, color: Colors.orange),
                ),
                title: Text(tenant.name),
                subtitle: Text(
                  'Unit ${item['unitName']} · ${item['daysOverdue']} days overdue\n'
                  'Owes: KES ${tenant.openingBalance.toStringAsFixed(0)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    final message = WhatsAppService.overdueMessage(
                      name: tenant.name,
                      unitNumber: item['unitName'],
                      daysOverdue: item['daysOverdue'],
                      balance: tenant.openingBalance,
                    );
                    await WhatsAppService.sendMessage(tenant.phone, message);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koditrack'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.campaign),
            tooltip: 'Nudge Overdue Tenants',
            onPressed: _showOverdueDialog,
          ),
        ],
      ),
=======
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koditrack'), centerTitle: true),
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePropertyScreen()),
          );
<<<<<<< HEAD
          if (mounted) _loadData();
=======
          if (mounted) {
            context.read<PropertyProvider>().fetchProperties();
          }
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.properties.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

<<<<<<< HEAD
          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Money Gauge Card
                if (_expected > 0) _buildMoneyGauge(),
                if (_expected > 0) const SizedBox(height: 16),

                // Properties
                if (provider.properties.isEmpty)
                  _buildEmptyState()
                else
                  ...provider.properties.map(
                    (property) => _PropertyCard(property: property),
                  ),
              ],
            ),
          );
=======
          if (provider.properties.isEmpty) {
            return _buildEmptyState();
          }

          return _buildPropertyList(provider.properties);
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
        },
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildMoneyGauge() {
    final progress = _expected > 0 ? (_received / _expected).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).round();
    final remaining = _expected - _received;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'This Month',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      color: progress >= 1
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percentage%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'collected',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _GaugeStat(
                  label: 'Expected',
                  value: 'KES ${_expected.toStringAsFixed(0)}',
                  color: Theme.of(context).colorScheme.primary,
                ),
                _GaugeStat(
                  label: 'Received',
                  value: 'KES ${_received.toStringAsFixed(0)}',
                  color: Colors.green,
                ),
                _GaugeStat(
                  label: 'Remaining',
                  value: 'KES ${remaining > 0 ? remaining.toStringAsFixed(0) : '0'}',
                  color: remaining > 0 ? Colors.orange : Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

=======
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apartment_outlined,
              size: 80,
<<<<<<< HEAD
              color: Theme.of(context)
                  .colorScheme
                  .primary
                  .withValues(alpha: 0.4),
=======
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.4),
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
            ),
            const SizedBox(height: 16),
            Text(
              'No properties yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to add your first property',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}

class _GaugeStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _GaugeStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
=======

  Widget _buildPropertyList(List<Property> properties) {
    return RefreshIndicator(
      onRefresh: () => context.read<PropertyProvider>().fetchProperties(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: properties.length,
        itemBuilder: (context, index) {
          final property = properties[index];
          return _PropertyCard(property: property);
        },
      ),
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Property property;

  const _PropertyCard({required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.apartment,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(
          property.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (property.type != null) Text(property.type!),
            if (property.address != null) Text(property.address!),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: property),
            ),
<<<<<<< HEAD
          ).then((_) {
            // Refresh when coming back
            final provider = context.read<PropertyProvider>();
            provider.fetchProperties();
          });
=======
          );
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
        },
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> 21d3d737173cf0b9fb48c5ad6be502abfe9511ea
