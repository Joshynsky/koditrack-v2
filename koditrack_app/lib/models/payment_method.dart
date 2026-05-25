import '../utils/mpesa_format.dart';

class PaymentMethod {
  final String id;
  final String userId;
  final String type; // send_money | paybill | till
  final String displayName;
  final String? phoneNumber;
  final String? businessNumber;
  final String? accountNumber;
  final String? tillNumber;
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.type,
    required this.displayName,
    this.phoneNumber,
    this.businessNumber,
    this.accountNumber,
    this.tillNumber,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: json['type'] as String,
      displayName: json['display_name'] as String,
      phoneNumber: json['phone_number'] as String?,
      businessNumber: json['business_number'] as String?,
      accountNumber: json['account_number'] as String?,
      tillNumber: json['till_number'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'type': type,
      'display_name': displayName,
      'phone_number': phoneNumber,
      'business_number': businessNumber,
      'account_number': accountNumber,
      'till_number': tillNumber,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }

  String get subtitle {
    switch (type) {
      case 'send_money':
        return phoneNumber != null
            ? MpesaFormat.displayPhone(phoneNumber!)
            : '';
      case 'paybill':
        final acct = accountNumber != null && accountNumber!.isNotEmpty
            ? ' · Acc ${accountNumber!}'
            : '';
        return 'Paybill ${businessNumber ?? ''}$acct';
      case 'till':
        return 'Till ${tillNumber ?? ''}';
      default:
        return '';
    }
  }

  /// Instructions for tenants (WhatsApp / reminders).
  String get paymentInstructions {
    switch (type) {
      case 'send_money':
        return 'Send Money to ${phoneNumber != null ? MpesaFormat.displayPhone(phoneNumber!) : displayName}';
      case 'paybill':
        final acct = accountNumber != null && accountNumber!.isNotEmpty
            ? ', Account: $accountNumber'
            : '';
        return 'M-Pesa Paybill ${businessNumber ?? ''}$acct';
      case 'till':
        return 'M-Pesa Till ${tillNumber ?? ''} (Buy Goods)';
      default:
        return displayName;
    }
  }
}
