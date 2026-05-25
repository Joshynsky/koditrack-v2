import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/property_provider.dart';
import '../theme/koditrack_theme.dart';
import 'property_form_screen.dart';
import 'property_detail_screen.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;

    return Scaffold(
      appBar: AppBar(title: const Text('Properties'), centerTitle: true),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertyFormScreen()),
          );
          if (mounted) {
            context.read<PropertyProvider>().fetchProperties();
          }
        },
        backgroundColor: kt.brandGreen,
        foregroundColor: kt.onPrimaryButton,
        icon: const Icon(Icons.add),
        label: const Text('Add Property'),
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.properties.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.properties.isEmpty) {
            return _buildEmptyState(context);
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchProperties(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: provider.properties.length,
              itemBuilder: (context, index) {
                final property = provider.properties[index];
                return _PropertyCard(property: property);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final kt = context.kt;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment_outlined,
                size: 80, color: kt.brandGreen.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No properties yet',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first property',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final Property property;

  const _PropertyCard({required this.property});

  Future<void> _openEdit(BuildContext context) async {
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PropertyFormScreen(property: property),
      ),
    );
    if (updated == true && context.mounted) {
      context.read<PropertyProvider>().fetchProperties();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    final muted = context.cs.onSurfaceVariant;

    return Card(
      color: kt.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: kt.borderSubtle),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: kt.brandGreenLight,
          child: Icon(Icons.apartment, color: kt.brandGreen),
        ),
        title: Text(
          property.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (property.type != null)
              Row(
                children: [
                  Icon(Icons.category_outlined, size: 13, color: muted),
                  const SizedBox(width: 4),
                  Text(property.type!, style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            if (property.address != null) ...[
              const SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 13, color: muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(property.address!,
                        style: TextStyle(fontSize: 12, color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 3),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: muted),
                const SizedBox(width: 4),
                Text('Due: ${_dayText(property.rentDueDay)} of each month',
                    style: TextStyle(fontSize: 12, color: muted)),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: muted),
          onSelected: (value) {
            if (value == 'edit') _openEdit(context);
            if (value == 'open') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(
                    key: ValueKey(property.id),
                    property: property,
                  ),
                ),
              );
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'open', child: Text('Open')),
            const PopupMenuItem(value: 'edit', child: Text('Edit property')),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(
                key: ValueKey(property.id),
                property: property,
              ),
            ),
          );
        },
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
