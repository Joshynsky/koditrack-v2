import 'package:flutter/material.dart';
import '../providers/unit_generator.dart';
import '../theme/koditrack_theme.dart';
import '../providers/property_provider.dart';
import 'package:provider/provider.dart';

class AddUnitScreen extends StatefulWidget {
  final String propertyId;
  final String propertyName;

  const AddUnitScreen({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<AddUnitScreen> createState() => _AddUnitScreenState();
}

class _AddUnitScreenState extends State<AddUnitScreen> {
  @override
  Widget build(BuildContext context) {
    final kt = context.kt;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(
        title: Text(widget.propertyName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Units', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Choose how you\'d like to build your property',
                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            _OptionCard(
              icon: Icons.grid_view_rounded,
              iconBg: kt.brandGreenLight,
              iconColor: kt.brandGreen,
              title: 'Simple Setup',
              subtitle: 'All floors identical, same layout throughout. Best for symmetrical apartment blocks.',
              badge: 'Fastest',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SimpleBuilderScreen(propertyId: widget.propertyId))),
            ),
            const SizedBox(height: 14),
            _OptionCard(
              icon: Icons.dashboard_customize_rounded,
              iconBg: kt.accentAmberLight,
              iconColor: kt.accentAmber,
              title: 'Custom Builder',
              subtitle: 'Different layouts per floor, multiple blocks, mixed unit types. Full control.',
              badge: 'Flexible',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomBuilderScreen(propertyId: widget.propertyId))),
            ),
            const SizedBox(height: 14),
            _OptionCard(
              icon: Icons.add_home_work_rounded,
              iconBg: kt.accentBlueLight,
              iconColor: kt.accentBlue,
              title: 'Single Unit',
              subtitle: 'Add one unit at a time. Useful for small additions or irregular properties.',
              badge: null,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SingleUnitScreen(propertyId: widget.propertyId))),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;

  const _OptionCard({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.subtitle, this.badge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    return Card(
      color: kt.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: kt.borderSubtle)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: iconColor, size: 24)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: kt.brandGreenLight, borderRadius: BorderRadius.circular(99)), child: Text(badge!, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: kt.brandGreen))),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIMPLE BUILDER
// ═══════════════════════════════════════════════════════════════════════════

class SimpleBuilderScreen extends StatefulWidget {
  final String propertyId;
  const SimpleBuilderScreen({super.key, required this.propertyId});
  @override
  State<SimpleBuilderScreen> createState() => _SimpleBuilderScreenState();
}

class _SimpleBuilderScreenState extends State<SimpleBuilderScreen> {
  final _blocksController = TextEditingController();
  final _floorsController = TextEditingController();
  final _unitsController = TextEditingController();
  final _rentController = TextEditingController();
  String? _unitType;
  bool _generating = false;

  final _unitTypes = ['1-Bedroom', '2-Bedroom', 'Studio', 'Shop', 'Office', 'Penthouse', 'Other'];

  Future<void> _generate() async {
    final blocks = int.tryParse(_blocksController.text) ?? 1;
    final floors = int.tryParse(_floorsController.text) ?? 1;
    final unitsPerFloor = int.tryParse(_unitsController.text) ?? 1;
    final total = blocks * floors * unitsPerFloor;
    if (total == 0) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter valid numbers'))); return; }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Generation'),
        content: Text('$blocks block${blocks > 1 ? 's' : ''} × $floors floor${floors > 1 ? 's' : ''} × $unitsPerFloor unit${unitsPerFloor > 1 ? 's' : ''} = $total units total\n\nNaming: Block A: A1-A${floors * unitsPerFloor}${blocks > 1 ? ', Block B: B1-B${floors * unitsPerFloor}' : ''}\nType: ${_unitType ?? 'Not specified'}\nRent: ${_rentController.text.isNotEmpty ? 'KES ${_rentController.text}' : 'Not set'}'),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate'))],
      ),
    );
    if (confirmed != true) return;

    setState(() => _generating = true);
    try {
      await UnitGenerator().generateBlockUnits(propertyId: widget.propertyId, blocks: blocks, floors: floors, unitsPerFloor: unitsPerFloor, unitType: _unitType, defaultRent: _rentController.text.trim().isEmpty ? null : double.tryParse(_rentController.text.trim()));
      context.read<PropertyProvider>().invalidateCache(widget.propertyId);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$total units created!'))); Navigator.pop(context); Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); }
    finally { if (mounted) setState(() => _generating = false); }
  }

  @override
  void dispose() { _blocksController.dispose(); _floorsController.dispose(); _unitsController.dispose(); _rentController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    final blocks = int.tryParse(_blocksController.text) ?? 1;
    final floors = int.tryParse(_floorsController.text) ?? 1;
    final unitsPerFloor = int.tryParse(_unitsController.text) ?? 1;
    final total = blocks * floors * unitsPerFloor;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(title: const Text('Simple Setup')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kt.brandGreenLight, borderRadius: BorderRadius.circular(14)), child: Row(children: [Icon(Icons.info_outline, color: kt.brandGreen, size: 20), const SizedBox(width: 10), Expanded(child: Text('All floors will have the same number of units and type. For mixed layouts, use Custom Builder.', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)))])),
            const SizedBox(height: 24),
            _LabeledField(label: 'Number of Blocks', hint: 'e.g. 1, 2, 3', controller: _blocksController, icon: Icons.domain, onChanged: (_) => setState(() {})),
            const SizedBox(height: 16),
            _LabeledField(label: 'Floors per Block', hint: 'e.g. 5', controller: _floorsController, icon: Icons.layers, onChanged: (_) => setState(() {})),
            const SizedBox(height: 16),
            _LabeledField(label: 'Units per Floor', hint: 'e.g. 4', controller: _unitsController, icon: Icons.door_back_door, onChanged: (_) => setState(() {})),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(value: _unitType, decoration: InputDecoration(labelText: 'Unit Type', prefixIcon: const Icon(Icons.category_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kt.inputFill), items: _unitTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _unitType = v)),
            const SizedBox(height: 16),
            TextField(controller: _rentController, decoration: InputDecoration(labelText: 'Default Rent (KES)', hintText: 'Optional — can set per tenant later', prefixIcon: const Icon(Icons.payments_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kt.inputFill), keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kt.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: kt.borderSubtle)), child: Row(children: [Container(width: 40, height: 40, decoration: BoxDecoration(color: kt.brandGreenLight, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.apartment, color: kt.brandGreen, size: 20)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('$total unit${total == 1 ? '' : 's'} total', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)), Text('$blocks block${blocks > 1 ? 's' : ''} · $floors floor${floors > 1 ? 's' : ''} · $unitsPerFloor per floor', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))]))])),
            const SizedBox(height: 24),
            SizedBox(height: 52, child: FilledButton(onPressed: _generating ? null : _generate, style: FilledButton.styleFrom(backgroundColor: kt.brandGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: _generating ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text('Generate $total Unit${total == 1 ? '' : 's'}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          ],
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label; final String hint; final TextEditingController controller; final IconData icon; final ValueChanged<String>? onChanged;
  const _LabeledField({required this.label, required this.hint, required this.controller, required this.icon, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    return TextField(controller: controller, keyboardType: TextInputType.number, onChanged: onChanged, decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kt.inputFill));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CUSTOM BUILDER
// ═══════════════════════════════════════════════════════════════════════════

class CustomBuilderScreen extends StatefulWidget {
  final String propertyId;
  const CustomBuilderScreen({super.key, required this.propertyId});
  @override
  State<CustomBuilderScreen> createState() => _CustomBuilderScreenState();
}

class _CustomBuilderScreenState extends State<CustomBuilderScreen> {
  final _unitTypes = ['1-Bedroom', '2-Bedroom', 'Studio', 'Shop', 'Office', 'Penthouse', 'Other'];
  final List<_FloorRow> _floors = [];
  String _currentBlock = 'A';
  bool _generating = false;

  @override
  void initState() { super.initState(); _addFloor(); }

  void _addFloor() { final nextFloor = _floors.length + 1; setState(() { _floors.add(_FloorRow(block: _currentBlock, floor: nextFloor, countController: TextEditingController(), type: null, rentController: TextEditingController())); }); }
  void _addBlock() { final nextBlock = String.fromCharCode(65 + _blocksCount()); setState(() => _currentBlock = nextBlock); _addFloor(); }
  int _blocksCount() => _floors.map((f) => f.block).toSet().length;
  int _totalUnits() => _floors.fold(0, (sum, f) => sum + (int.tryParse(f.countController.text) ?? 0));

  Future<void> _generate() async {
    final configs = <Map<String, dynamic>>[];
    for (int i = 0; i < _floors.length; i++) {
      final f = _floors[i]; final count = int.tryParse(f.countController.text) ?? 0;
      if (count == 0) continue;
      configs.add({'block': f.block, 'floor': f.floor, 'count': count, 'unit_type': f.type, 'default_rent': f.rentController.text.trim().isEmpty ? null : double.tryParse(f.rentController.text.trim()), 'floor_label': String.fromCharCode(65 + i)});
    }
    if (configs.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one floor with units'))); return; }
    final total = _totalUnits();
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Confirm Generation'), content: Text('Generate $total units across ${_floors.length} floors?'), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Generate'))]));
    if (confirmed != true) return;
    setState(() => _generating = true);
    try {
      await UnitGenerator().generateCustomUnits(propertyId: widget.propertyId, floorConfigs: configs);
      context.read<PropertyProvider>().invalidateCache(widget.propertyId);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$total units created!'))); Navigator.pop(context); Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); }
    finally { if (mounted) setState(() => _generating = false); }
  }

  @override
  void dispose() { for (final f in _floors) { f.countController.dispose(); f.rentController.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(title: const Text('Custom Builder')),
      body: Column(children: [
        Expanded(child: ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), itemCount: _floors.length + 1, itemBuilder: (context, index) => index == _floors.length ? _buildAddButtons() : _buildFloorRow(index))),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: kt.cardBackground, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))]), child: SafeArea(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${_totalUnits()} units · ${_floors.length} floors', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)), Text('${_blocksCount()} block${_blocksCount() > 1 ? 's' : ''}', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant))])), SizedBox(height: 48, child: FilledButton(onPressed: _generating ? null : _generate, style: FilledButton.styleFrom(backgroundColor: kt.brandGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _generating ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Generate All')))]))),
      ]),
    );
  }

  Widget _buildAddButtons() => Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [Expanded(child: OutlinedButton.icon(onPressed: _addFloor, icon: const Icon(Icons.add, size: 18), label: const Text('Add Floor'), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)))), const SizedBox(width: 10), Expanded(child: OutlinedButton.icon(onPressed: _addBlock, icon: const Icon(Icons.domain, size: 18), label: const Text('New Block'), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12))))]));

  Widget _buildFloorRow(int index) {
    final kt = context.kt;
    final floor = _floors[index];
    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: kt.cardBackground, borderRadius: BorderRadius.circular(14), border: Border.all(color: kt.borderSubtle)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: kt.brandGreenLight, borderRadius: BorderRadius.circular(99)), child: Text('Block ${floor.block} · Floor ${floor.floor}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kt.brandGreen))), const Spacer(), if (_floors.length > 1) GestureDetector(onTap: () { setState(() { floor.countController.dispose(); floor.rentController.dispose(); _floors.removeAt(index); }); }, child: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant))]),
      const SizedBox(height: 12),
      Row(children: [Expanded(flex: 2, child: TextField(controller: floor.countController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Units', hintText: 'e.g. 4', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true))), const SizedBox(width: 10), Expanded(flex: 3, child: DropdownButtonFormField<String>(value: floor.type, decoration: InputDecoration(labelText: 'Type', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true), items: _unitTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13)))).toList(), onChanged: (v) => setState(() => floor.type = v)))]),
      const SizedBox(height: 10),
      TextField(controller: floor.rentController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Rent (KES)', hintText: 'Optional', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), isDense: true)),
    ]));
  }
}

class _FloorRow {
  final String block; final int floor; final TextEditingController countController; String? type; final TextEditingController rentController;
  _FloorRow({required this.block, required this.floor, required this.countController, this.type, required this.rentController});
}

// ═══════════════════════════════════════════════════════════════════════════
// SINGLE UNIT
// ═══════════════════════════════════════════════════════════════════════════

class SingleUnitScreen extends StatefulWidget {
  final String propertyId;
  const SingleUnitScreen({super.key, required this.propertyId});
  @override
  State<SingleUnitScreen> createState() => _SingleUnitScreenState();
}

class _SingleUnitScreenState extends State<SingleUnitScreen> {
  final _unitNumberController = TextEditingController();
  final _floorController = TextEditingController();
  final _rentController = TextEditingController();
  final _blockController = TextEditingController();
  String? _selectedType;
  bool _saving = false;

  final _unitTypes = ['1-Bedroom', '2-Bedroom', 'Studio', 'Shop', 'Office', 'Penthouse', 'Other'];

  Future<void> _save({required bool addAnother}) async {
    if (_unitNumberController.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit number is required'))); return; }
    setState(() => _saving = true);
    try {
      await UnitGenerator().addSingleUnit(propertyId: widget.propertyId, unitNumber: _unitNumberController.text.trim(), block: _blockController.text.trim().isEmpty ? null : _blockController.text.trim().toUpperCase(), floor: _floorController.text.trim().isEmpty ? null : int.tryParse(_floorController.text.trim()), unitType: _selectedType, defaultRent: _rentController.text.trim().isEmpty ? null : double.tryParse(_rentController.text.trim()));
      context.read<PropertyProvider>().invalidateCache(widget.propertyId);
      if (mounted) { if (addAnother) { _unitNumberController.clear(); _rentController.clear(); setState(() => _selectedType = null); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unit added! Add another.'))); } else { Navigator.pop(context); } }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'))); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  void dispose() { _unitNumberController.dispose(); _floorController.dispose(); _rentController.dispose(); _blockController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;
    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(title: const Text('Add Single Unit')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextField(controller: _blockController, decoration: InputDecoration(labelText: 'Block (optional)', hintText: 'e.g. A, B, C', prefixIcon: const Icon(Icons.domain, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kt.inputFill), textCapitalization: TextCapitalization.characters),
        const SizedBox(height: 16),
        TextField(controller: _unitNumberController, decoration: InputDecoration(labelText: 'Unit Number *', hintText: 'e.g. A1, B12, Shop-3', prefixIcon: const Icon(Icons.door_back_door, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kt.inputFill), textCapitalization: TextCapitalization.characters, autofocus: true),
        const SizedBox(height: 16),
        TextField(controller: _floorController, decoration: InputDecoration(labelText: 'Floor', hintText: 'e.g. 1, 2, 3', prefixIcon: const Icon(Icons.layers, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kt.inputFill), keyboardType: TextInputType.number),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _selectedType, decoration: InputDecoration(labelText: 'Unit Type', prefixIcon: const Icon(Icons.category_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kt.inputFill), items: _unitTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => _selectedType = v)),
        const SizedBox(height: 16),
        TextField(controller: _rentController, decoration: InputDecoration(labelText: 'Default Rent (KES)', hintText: 'Optional — can set per tenant later', prefixIcon: const Icon(Icons.payments_outlined, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: kt.inputFill), keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        Row(children: [Expanded(child: OutlinedButton(onPressed: _saving ? null : () => _save(addAnother: false), style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Save & Close'))), const SizedBox(width: 12), Expanded(child: FilledButton.icon(onPressed: _saving ? null : () => _save(addAnother: true), icon: const Icon(Icons.add, size: 18), label: const Text('Save & Add More'), style: FilledButton.styleFrom(backgroundColor: kt.brandGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14))))]),
      ])),
    );
  }
}