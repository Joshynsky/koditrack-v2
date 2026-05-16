import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';

class AddUnitScreen extends StatefulWidget {
  final String propertyId;

  const AddUnitScreen({super.key, required this.propertyId});

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  final _unitNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _rentController = TextEditingController();
  String? _selectedType;
  bool _saving = false;

  final _unitTypes = [
    '1-Bedroom',
    '2-Bedroom',
    'Studio',
    'Shop',
    'Office',
    'Other',
  ];

  Future<void> _save() async {
    if (_unitNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unit number is required')));
      return;
    }

    setState(() => _saving = true);

    try {
      await context.read<PropertyProvider>().addUnit(
        propertyId: widget.propertyId,
        unitNumber: _unitNumberController.text.trim(),
        floor: _floorController.text.trim().isEmpty
            ? null
            : int.tryParse(_floorController.text.trim()),
        unitType: _selectedType,
        defaultRent: _rentController.text.trim().isEmpty
            ? null
            : double.tryParse(_rentController.text.trim()),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add unit: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _unitNumberController.dispose();
    _floorController.dispose();
    _rentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Unit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _unitNumberController,
              decoration: const InputDecoration(
                labelText: 'Unit Number *',
                hintText: 'e.g. A1, B12',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _floorController,
              decoration: const InputDecoration(
                labelText: 'Floor',
                hintText: 'e.g. 1, 2, 3',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Unit Type',
                border: OutlineInputBorder(),
              ),
              items: _unitTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rentController,
              decoration: const InputDecoration(
                labelText: 'Default Rent (KES)',
                hintText: 'Optional - can set on tenant later',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
                    : const Text('Save Unit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
