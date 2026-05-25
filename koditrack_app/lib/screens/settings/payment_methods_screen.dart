import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment_method.dart';
import '../../providers/payment_method_provider.dart';
import '../../theme/koditrack_theme.dart';
import '../../utils/mpesa_format.dart';
import 'add_payment_method_screen.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentMethodProvider>().fetchMethods();
    });
  }

  @override
  Widget build(BuildContext context) {
    final kt = context.kt;

    return Scaffold(
      backgroundColor: kt.pageBackground,
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPaymentMethodScreen()),
          );
          if (mounted) context.read<PaymentMethodProvider>().fetchMethods();
        },
        backgroundColor: kt.brandGreen,
        icon: const Icon(Icons.add),
        label: const Text('Add Method'),
      ),
      body: Consumer<PaymentMethodProvider>(
        builder: (context, provider, _) {
          if (provider.loading && provider.methods.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.methods.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payments_outlined,
                        size: 64, color: kt.brandGreen.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('No payment methods yet',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      'Add how tenants should pay rent — Send Money, Paybill, or Till.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: provider.methods.length,
            itemBuilder: (context, index) {
              final method = provider.methods[index];
              return _MethodCard(method: method);
            },
          );
        },
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final PaymentMethod method;

  const _MethodCard({required this.method});

  IconData get _icon {
    switch (method.type) {
      case 'send_money':
        return Icons.phone_android;
      case 'paybill':
        return Icons.receipt_long;
      case 'till':
        return Icons.storefront;
      default:
        return Icons.payments;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PaymentMethodProvider>();
    final kt = context.kt;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: kt.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: kt.brandGreenLight,
          child: Icon(_icon, color: kt.brandGreen, size: 22),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(method.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            if (method.isDefault)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: kt.brandGreenLight,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Default',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: kt.brandGreen)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(MpesaFormat.typeLabel(method.type),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            Text(method.subtitle,
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'default') {
              await provider.setDefault(method.id);
            } else if (value == 'delete') {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove payment method?'),
                  content: const Text(
                      'Properties using this method will need a new one assigned.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Remove',
                            style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) await provider.deleteMethod(method.id);
            }
          },
          itemBuilder: (_) => [
            if (!method.isDefault)
              const PopupMenuItem(value: 'default', child: Text('Set as default')),
            const PopupMenuItem(
                value: 'delete', child: Text('Remove', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }
}
