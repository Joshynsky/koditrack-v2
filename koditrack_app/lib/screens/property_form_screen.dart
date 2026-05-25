import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/property.dart';
import '../providers/payment_method_provider.dart';
import '../providers/property_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/koditrack_theme.dart';

class PropertyFormScreen extends StatefulWidget {
  final Property? property;

  const PropertyFormScreen({super.key, this.property});

  bool get isEditing => property != null;

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedType;
  int _rentDueDay = 5;
  String? _selectedPaymentMethodId;
  bool _saving = false;

  final _propertyTypes = ['Apartment', 'Commercial', 'Mixed-Use', 'Other'];

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    if (p != null) {
      _nameController.text = p.name;
      _addressController.text = p.address ?? '';
      _selectedType = p.type;
      _rentDueDay = p.rentDueDay;
      _selectedPaymentMethodId = p.paymentMethodId;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<PaymentMethodProvider>().fetchMethods();
      final settings = context.read<SettingsProvider>();
      if (!widget.isEditing && _rentDueDay == 5) {
        await settings.fetchProfile();
        if (mounted && settings.profile != null) {
          setState(() => _rentDueDay = settings.profile!.defaultRentDueDay);
        }
      }
      if (!widget.isEditing && _selectedPaymentMethodId == null) {
        final def = context.read<PaymentMethodProvider>().defaultMethod;
        if (def != null) setState(() => _selectedPaymentMethodId = def.id);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _showDayPicker() {
    final kt = context.kt;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select rent due day',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Tap a day — applies to all tenants in this property',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(31, (index) {
                  final day = index + 1;
                  final isSelected = day == _rentDueDay;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _rentDueDay = day);
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

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property name is required')),
      );
      return;
    }

    final pm = context.read<PaymentMethodProvider>();
    if (pm.hasMethods && _selectedPaymentMethodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (widget.isEditing &&
        widget.property!.rentDueDay != _rentDueDay) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Change rent due day?'),
          content: const Text(
            'This updates the due day for the property. Existing tenant leases are unchanged.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Update')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _saving = true);
    try {
      final provider = context.read<PropertyProvider>();
      final name = _nameController.text.trim();
      final address = _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim();

      if (widget.isEditing) {
        await provider.updateProperty(
          id: widget.property!.id,
          name: name,
          type: _selectedType,
          address: address,
          rentDueDay: _rentDueDay,
          paymentMethodId: _selectedPaymentMethodId,
        );
      } else {
        await provider.addProperty(
          name: name,
          type: _selectedType,
          address: address,
          rentDueDay: _rentDueDay,
          paymentMethodId: _selectedPaymentMethodId,
        );
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
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
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Property' : 'Add Property'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.isEditing)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAEEDA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFBA7517), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'To add Block B or more units, use Add Units on the property page.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kt.brandGreenLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: kt.brandGreen, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Set up your property. The rent due day applies to all tenants in this property.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Property Name *',
                hintText: 'e.g. Karen Apartments',
                prefixIcon: const Icon(Icons.apartment, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: kt.inputFill,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: InputDecoration(
                labelText: 'Property Type',
                prefixIcon: const Icon(Icons.category_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: kt.inputFill,
              ),
              items: _propertyTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                hintText: 'e.g. Karen Road, Nairobi',
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: kt.inputFill,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _showDayPicker(),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Rent Due Day',
                  prefixIcon: const Icon(Icons.calendar_today, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: kt.inputFill,
                  helperText: 'All tenants in this property use this due day',
                ),
                child: Text(
                  _rentDueDay == 1 ? '1st of each month' : '${_rentDueDay}th of each month',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<PaymentMethodProvider>(
              builder: (context, pm, _) {
                if (!pm.hasMethods) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: kt.accentAmberLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kt.accentAmber.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: kt.accentAmber, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Add a payment method in Settings before assigning one to this property.',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                );
                }
                return DropdownButtonFormField<String>(
                  initialValue: _selectedPaymentMethodId,
                  decoration: InputDecoration(
                    labelText: 'Tenant payment method *',
                    prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: kt.inputFill,
                    helperText: 'Shown to tenants in WhatsApp reminders',
                  ),
                  items: pm.methods
                      .map((m) => DropdownMenuItem(
                            value: m.id,
                            child: Text('${m.displayName} (${m.subtitle})',
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedPaymentMethodId = v),
                );
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: kt.brandGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        widget.isEditing ? 'Save Changes' : 'Save Property',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
