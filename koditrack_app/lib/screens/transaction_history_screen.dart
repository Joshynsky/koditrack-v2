import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/tenant.dart';
import '../models/payment.dart';
import '../providers/property_provider.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final Tenant? tenant;

  const TransactionHistoryScreen({super.key, this.tenant});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.tenant != null) {
        context.read<PropertyProvider>().fetchPayments(widget.tenant!.id);
      } else {
        context.read<PropertyProvider>().fetchAllPayments();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            appBar: AppBar(
        title: Text(widget.tenant != null 
            ? '${widget.tenant!.name} - Payments' 
            : 'All Payments'),
      ),
      body: Consumer<PropertyProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.selectedTenantPayments.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final payments = provider.selectedTenantPayments;

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No payments yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          // Calculate running balance
          double runningBalance = widget.tenant?.openingBalance ?? 0;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length + 1, // +1 for header
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildHeader();
              }

              final payment = payments[index - 1];
              runningBalance -= payment.amount;

              return _PaymentTile(
                payment: payment,
                balanceAfter: runningBalance,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    if (widget.tenant == null) return const SizedBox.shrink();
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _HeaderItem(
              label: 'Monthly Bill',
              value: 'KES ${widget.tenant!.totalMonthlyBill.toStringAsFixed(0)}',
            ),
            _HeaderItem(
              label: 'Balance',
              value: 'KES ${widget.tenant!.openingBalance.toStringAsFixed(0)}',
              color: widget.tenant!.openingBalance > 0 ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _HeaderItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  final double balanceAfter;

  const _PaymentTile({required this.payment, required this.balanceAfter});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          child: const Icon(Icons.arrow_downward, color: Colors.green),
        ),
        title: Text(
          'KES ${payment.amount.toStringAsFixed(0)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_formatDate(payment.paymentDate)),
            if (payment.paymentMethod != null)
              Text(
                payment.paymentMethod!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (payment.reference != null)
              Text(
                'Ref: ${payment.reference}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
          ],
        ),
        trailing: Text(
          'KES ${balanceAfter.toStringAsFixed(0)}',
          style: TextStyle(
            color: balanceAfter <= 0 ? Colors.green : Colors.red,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
