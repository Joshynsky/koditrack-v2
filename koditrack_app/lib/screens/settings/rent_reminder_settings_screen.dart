import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/property_provider.dart';
import '../../theme/koditrack_theme.dart';

class RentReminderSettingsScreen extends StatefulWidget {
  const RentReminderSettingsScreen({super.key});

  @override
  State<RentReminderSettingsScreen> createState() =>
      _RentReminderSettingsScreenState();
}

class _RentReminderSettingsScreenState extends State<RentReminderSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PropertyProvider>().fetchProperties();
    });
  }

  String _dayText(int day) {
    if (day == 1) return '1st';
    if (day == 2) return '2nd';
    if (day == 3) return '3rd';
    return '${day}th';
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(title: const Text('Rent Due Days')),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.properties.isEmpty) {
            return const Center(child: Text('No properties yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            itemCount: provider.properties.length,
            itemBuilder: (context, index) {
              final property = provider.properties[index];
              return _PropertyDueRow(
                propertyId: property.id,
                name: property.name,
                currentDay: property.rentDueDay,
              );
            },
          );
        },
      ),
    );
  }
}

class _PropertyDueRow extends StatefulWidget {
  final String propertyId;
  final String name;
  final int currentDay;

  const _PropertyDueRow({
    required this.propertyId,
    required this.name,
    required this.currentDay,
  });

  @override
  State<_PropertyDueRow> createState() => _PropertyDueRowState();
}

class _PropertyDueRowState extends State<_PropertyDueRow> {
  late int _selectedDay;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.currentDay;
  }

  Future<void> _updateDay(int day) async {
    setState(() {
      _saving = true;
      _selectedDay = day;
    });

    try {
      await context.read<PropertyProvider>().updateProperty(
            id: widget.propertyId,
            name: widget.name,
            rentDueDay: day,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.name} updated to ${_dayText(day)}')),
        );
      }
    } catch (e) {
      setState(() => _selectedDay = widget.currentDay); // Revert on failure
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showDayPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final kt = Theme.of(ctx).extension<KoditrackColors>() ?? KoditrackColors.light;
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rent due day for ${widget.name}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap a date to select',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              // Day grid
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(31, (index) {
                  final day = index + 1;
                  final isSelected = day == _selectedDay;
                  return GestureDetector(
                    onTap: () {
                      _updateDay(day);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected ? kt.brandGreen : kt.chipBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? null
                            : Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : null,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _dayText(int day) {
    if (day == 1) return '1st';
    if (day == 2) return '2nd';
    if (day == 3) return '3rd';
    return '${day}th';
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;

    return Card(
      color: kt.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: _showDayPicker,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(widget.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kt.brandGreenLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dayText(_selectedDay),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: kt.brandGreen,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.calendar_today, size: 14, color: kt.brandGreen),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}