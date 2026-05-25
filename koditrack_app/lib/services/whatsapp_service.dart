import 'package:url_launcher/url_launcher.dart';

class WhatsAppService {
  /// Build a WhatsApp URL from phone number and message
  static String _buildUrl(String phone, String message) {
    // Remove any non-digit characters (spaces, +, dashes)
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final encoded = Uri.encodeComponent(message);
    return 'https://wa.me/$cleanPhone?text=$encoded';
  }

  /// Launch WhatsApp with the given phone and message
  static Future<bool> sendMessage(String phone, String message) async {
    final url = _buildUrl(phone, message);
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  // ============================================
  // MESSAGE TEMPLATES
  // ============================================

  /// Payment reminder for upcoming/current rent
  static String reminderMessage({
    required String name,
    required String unitNumber,
    required String propertyName,
    required int dueDay,
    required double totalDue,
    String? paymentInstructions,
  }) {
    final dueText = _dayText(dueDay);
    final payText = paymentInstructions != null && paymentInstructions.isNotEmpty
        ? ' Pay via: $paymentInstructions.'
        : ' Please pay via M-Pesa to the landlord.';
    return 'Hi $name, rent for Unit $unitNumber ($propertyName) is due on the $dueText. '
        'Total amount due is KES ${totalDue.toStringAsFixed(0)}.$payText Thank you!';
  }

  /// Overdue nudge for late payment
  static String overdueMessage({
    required String name,
    required String unitNumber,
    required int daysOverdue,
    required double balance,
    String? paymentInstructions,
  }) {
    final payText = paymentInstructions != null && paymentInstructions.isNotEmpty
        ? ' Pay via: $paymentInstructions.'
        : ' Pay via M-Pesa.';
    return 'Urgent: $name, your rent for Unit $unitNumber is overdue by $daysOverdue days. '
        'Please settle the balance of KES ${balance.toStringAsFixed(0)} '
        'to avoid further action.$payText';
  }

  /// Receipt after payment is recorded
  static String receiptMessage({
    required String name,
    required double amountPaid,
    required double newBalance,
    String? reference,
  }) {
    final refText = reference != null ? 'Reference: $reference. ' : '';
    final statusText = newBalance <= 0
        ? 'You are fully paid up. Thank you!'
        : 'Remaining balance: KES ${newBalance.toStringAsFixed(0)}.';

    return 'Thank you $name! We have received your payment of KES ${amountPaid.toStringAsFixed(0)}. '
        '$refText'
        '$statusText';
  }

  static String _dayText(int day) {
    if (day == 1) return '1st';
    if (day == 2) return '2nd';
    if (day == 3) return '3rd';
    return '${day}th';
  }
}