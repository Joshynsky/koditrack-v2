import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tenant.dart';
import '../providers/property_provider.dart';
import '../services/whatsapp_service.dart';

class RecordPaymentScreen extends StatefulWidget {
  final Tenant tenant;
  final VoidCallback? onPaymentRecorded;

  const RecordPaymentScreen({
    super.key,
    required this.tenant,
    this.onPaymentRecorded,
  });

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  String? _paymentMethod;
  DateTime _paymentDate = DateTime.now();
  bool _saving = false;

  final _paymentMethods = ['M-Pesa', 'Cash', 'Bank Transfer', 'Other'];

  Future<void> _save() async {
    if (_amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Amount is required')));
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount')));
      return;
    }

    setState(() => _saving = true);

    try {
      await context.read<PropertyProvider>().recordPayment(
        tenantId: widget.tenant.id,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: _paymentMethod,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      );

      widget.onPaymentRecorded?.call();

      if (mounted) {
        _showReceiptDialog(amount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to record payment: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _showReceiptDialog(double amountPaid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment Saved'),
        content: const Text('Send a receipt to the tenant via WhatsApp?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // close dialog
              Navigator.pop(context); // close screen
            },
            child: const Text('No, thanks'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.pop(ctx); // close dialog
              
              final message = WhatsAppService.receiptMessage(
                name: widget.tenant.name,
                amountPaid: amountPaid,
                newBalance: widget.tenant.openingBalance - amountPaid,
                reference: _referenceController.text.trim().isEmpty
                    ? null
                    : _referenceController.text.trim(),
              );

              final success = await WhatsAppService.sendMessage(
                widget.tenant.phone,
                message,
              );

              if (mounted) {
                Navigator.pop(context); // close screen
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open WhatsApp')),
                  );
                }
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Receipt'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.tenant.openingBalance;
    final monthlyBill = widget.tenant.totalMonthlyBill;
    final totalDue = balance > 0 ? monthlyBill + balance : monthlyBill;

    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tenant summary card
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      widget.tenant.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          label: 'Monthly',
                          value: 'KES ${monthlyBill.toStringAsFixed(0)}',
                        ),
                        _SummaryItem(
                          label: 'Arrears',
                          value:
                              'KES ${balance > 0 ? balance.toStringAsFixed(0) : '0'}',
                          color: balance > 0 ? Colors.red : Colors.green,
                        ),
                        _SummaryItem(
                          label: 'Total Due',
                          value: 'KES ${totalDue.toStringAsFixed(0)}',
                          bold: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Amount
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Paid (KES) *',
                hintText: 'e.g. 15000',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              autofocus: true,
            ),
            const SizedBox(height: 16),

            // Payment date
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_paymentDate.day}/${_paymentDate.month}/${_paymentDate.year}',
                    ),
                    const Icon(Icons.calendar_today, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment method
            DropdownButtonFormField<String>(
              initialValue: _paymentMethod,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Select method'),
              items: _paymentMethods
                  .map(
                    (method) =>
                        DropdownMenuItem(value: method, child: Text(method)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _paymentMethod = value),
            ),
            const SizedBox(height: 16),

            // Reference
            TextField(
              controller: _referenceController,
              decoration: const InputDecoration(
                labelText: 'Reference / M-Pesa Code',
                hintText: 'e.g. QWE123456',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
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
                    : const Text('Record Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const _SummaryItem({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.w500,
            color: color,
            fontSize: 14,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
