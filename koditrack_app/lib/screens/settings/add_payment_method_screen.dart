import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/payment_method_provider.dart';
import '../../utils/mpesa_format.dart';

class AddPaymentMethodScreen extends StatefulWidget {
  final bool isOnboarding;
  final VoidCallback? onSaved;

  const AddPaymentMethodScreen({
    super.key,
    this.isOnboarding = false,
    this.onSaved,
  });

  @override
  State<AddPaymentMethodScreen> createState() => _AddPaymentMethodScreenState();
}

class _AddPaymentMethodScreenState extends State<AddPaymentMethodScreen> {
  static const _green = Color(0xFF2E6F40);

  String _type = 'send_money';
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _paybillController = TextEditingController();
  final _accountController = TextEditingController();
  final _tillController = TextEditingController();
  bool _setDefault = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _paybillController.dispose();
    _accountController.dispose();
    _tillController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone254 = _type == 'send_money'
        ? MpesaFormat.normalizePhone(_phoneController.text)
        : null;

    final error = PaymentMethodProvider.validate(
      type: _type,
      displayName: _nameController.text,
      phoneRaw: _phoneController.text,
      businessNumber: _paybillController.text,
      tillNumber: _tillController.text,
    );

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<PaymentMethodProvider>().addMethod(
            type: _type,
            displayName: _nameController.text.trim(),
            phoneNumber: phone254,
            businessNumber:
                _type == 'paybill' ? _paybillController.text.trim() : null,
            accountNumber: _type == 'paybill' && _accountController.text.isNotEmpty
                ? _accountController.text.trim()
                : null,
            tillNumber: _type == 'till' ? _tillController.text.trim() : null,
            setAsDefault: _setDefault,
          );

      if (mounted) {
        widget.onSaved?.call();
        if (!widget.isOnboarding) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        title: const Text('Add Payment Method'),
        backgroundColor: const Color(0xFFF7F4EF),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: !widget.isOnboarding,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How will tenants pay rent?',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'send_money',
                  label: Text('Send Money', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.phone_android, size: 16),
                ),
                ButtonSegment(
                  value: 'paybill',
                  label: Text('Paybill', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.receipt_long, size: 16),
                ),
                ButtonSegment(
                  value: 'till',
                  label: Text('Till', style: TextStyle(fontSize: 11)),
                  icon: Icon(Icons.storefront, size: 16),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Label *',
                hintText: 'e.g. My M-Pesa, Building Paybill',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            if (_type == 'send_money') ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'M-Pesa Phone Number *',
                  hintText: '07XX XXX XXX',
                  prefixIcon: const Icon(Icons.phone, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
            if (_type == 'paybill') ...[
              TextField(
                controller: _paybillController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Paybill Number *',
                  hintText: 'e.g. 522522',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: 'Account Number (optional)',
                  hintText: 'e.g. unit number or tenant name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
            if (_type == 'till') ...[
              TextField(
                controller: _tillController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Till Number *',
                  hintText: 'Buy Goods till number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Set as default'),
              subtitle: const Text('Used when adding new properties'),
              value: _setDefault,
              activeThumbColor: _green,
              onChanged: (v) => setState(() => _setDefault = v),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save Payment Method',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
