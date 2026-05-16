import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/property_provider.dart';

class CreatePropertyScreen extends StatefulWidget {
  const CreatePropertyScreen({super.key});

  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedType;
  int _rentDueDay = 5;
  bool _saving = false;

  final _propertyTypes = ['Apartment', 'Commercial', 'Mixed-Use', 'Other'];

  final _dueDays = [1, 5, 10, 15, 20, 25, 30];

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Property name is required')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await context.read<PropertyProvider>().addProperty(
        name: _nameController.text.trim(),
        type: _selectedType,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        rentDueDay: _rentDueDay,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save property: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Property')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Property Name *',
                hintText: 'e.g. Karen Apartments',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Property Type',
                border: OutlineInputBorder(),
              ),
              items: _propertyTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _selectedType = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'e.g. Karen Road, Nairobi',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _rentDueDay,
              decoration: const InputDecoration(
                labelText: 'Rent Due Day',
                border: OutlineInputBorder(),
                helperText: 'Applies to all tenants in this property',
              ),
              items: _dueDays
                  .map(
                    (day) => DropdownMenuItem(
                      value: day,
                      child: Text(day == 1 ? '1st' : '${day}th'),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _rentDueDay = value);
              },
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
                    : const Text('Save Property'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
