import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit.dart';
import '../providers/property_provider.dart';

class AddTenantScreen extends StatefulWidget {
  final String propertyId;
  final int rentDueDay;
  final String? preSelectedUnitId;

  const AddTenantScreen({
    super.key,
    required this.propertyId,
    required this.rentDueDay,
    this.preSelectedUnitId,
  });

  @override
  State<AddTenantScreen> createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _baseRentController = TextEditingController();
  final _serviceChargeController = TextEditingController();
  final _openingBalanceController = TextEditingController();
  bool _whatsappEnabled = true;
  String? _selectedUnitId;
  bool _saving = false;
  List<Unit> _vacantUnits = [];

  @override
  void initState() {
    super.initState();
    _selectedUnitId = widget.preSelectedUnitId;
    _loadVacantUnits();
  }

  Future<void> _loadVacantUnits() async {
    final provider = context.read<PropertyProvider>();
    await provider.fetchUnits(widget.propertyId);
    setState(() {
      _vacantUnits = provider.selectedPropertyUnits
          .where(
            (u) => u.status == 'vacant' || u.id == widget.preSelectedUnitId,
          )
          .toList();
    });

    // Auto-fill rent if unit was pre-selected
    if (_selectedUnitId != null) {
      _autoFillRent(_selectedUnitId!);
    }
  }

  void _onUnitChanged(String? unitId) {
    setState(() {
      _selectedUnitId = unitId;
      if (unitId != null) {
        _autoFillRent(unitId);
      }
    });
  }

  void _autoFillRent(String unitId) {
    final unit = _vacantUnits.firstWhere((u) => u.id == unitId);
    if (unit.defaultRent != null && _baseRentController.text.isEmpty) {
      _baseRentController.text = unit.defaultRent!.toStringAsFixed(0);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tenant name is required')));
      return;
    }
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phone number is required')));
      return;
    }
    if (_baseRentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Base rent is required')));
      return;
    }

    setState(() => _saving = true);

    try {
      await context.read<PropertyProvider>().addTenant(
        propertyId: widget.propertyId,
        unitId: _selectedUnitId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        baseRent: double.parse(_baseRentController.text.trim()),
        serviceCharge: _serviceChargeController.text.trim().isEmpty
            ? 0
            : double.parse(_serviceChargeController.text.trim()),
        openingBalance: _openingBalanceController.text.trim().isEmpty
            ? 0
            : double.parse(_openingBalanceController.text.trim()),
        whatsappEnabled: _whatsappEnabled,
      );

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add tenant: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _baseRentController.dispose();
    _serviceChargeController.dispose();
    _openingBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Tenant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedUnitId,
              decoration: const InputDecoration(
                labelText: 'Assign to Unit',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select a unit (optional)'),
              items: _vacantUnits.map((unit) {
                return DropdownMenuItem(
                  value: unit.id,
                  child: Text('Unit ${unit.unitNumber}'),
                );
              }).toList(),
              onChanged: _onUnitChanged,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g. Jane Muthoni',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: 'e.g. +254712345678',
                border: OutlineInputBorder(),
                prefixText: '🇰🇪 ',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (optional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _baseRentController,
                    decoration: const InputDecoration(
                      labelText: 'Base Rent (KES) *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _serviceChargeController,
                    decoration: const InputDecoration(
                      labelText: 'Service Charge',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _openingBalanceController,
              decoration: InputDecoration(
                labelText: 'Opening Balance (Arrears)',
                hintText: 'e.g. 5000 if they owe from previous month',
                border: const OutlineInputBorder(),
                helperText:
                    'Due day: ${_getDayText(widget.rentDueDay)} of each month',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable WhatsApp Reminders'),
              subtitle: const Text('Send payment reminders via WhatsApp'),
              value: _whatsappEnabled,
              onChanged: (value) => setState(() => _whatsappEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'By adding this tenant, you confirm they have consented to receive payment reminders via WhatsApp.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Tenant'),
              ),
            ),
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
