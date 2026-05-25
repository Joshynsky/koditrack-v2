/// Kenyan M-Pesa phone and display formatting.
class MpesaFormat {
  /// Normalize to 2547XXXXXXXX for storage/display.
  static String? normalizePhone(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    var phone = raw.replaceAll(RegExp(r'\D'), '');
    if (phone.startsWith('0')) {
      phone = '254${phone.substring(1)}';
    } else if (phone.startsWith('7') || phone.startsWith('1')) {
      phone = '254$phone';
    }
    if (!phone.startsWith('254') || phone.length != 12) return null;
    return phone;
  }

  /// Display as 07XX XXX XXX for local UX.
  static String displayPhone(String phone254) {
    if (phone254.startsWith('254') && phone254.length == 12) {
      return '0${phone254.substring(3)}';
    }
    return phone254;
  }

  static String typeLabel(String type) {
    switch (type) {
      case 'send_money':
        return 'Send Money';
      case 'paybill':
        return 'Paybill';
      case 'till':
        return 'Till Number';
      default:
        return type;
    }
  }
}
