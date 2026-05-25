class Payment {
  final String id;
  final String tenantId;
  final double amount;
  final DateTime paymentDate;
  final String? paymentMethod;
  final String? reference;
  final String? notes;
  final String? tenantName;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    this.paymentMethod,
    this.reference,
    this.notes,
    this.tenantName,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      tenantId: json['tenant_id'],
      amount: double.parse(json['amount'].toString()),
      paymentDate: DateTime.parse(json['payment_date']),
      paymentMethod: json['payment_method'],
      reference: json['reference'],
      notes: json['notes'],
      tenantName: json['tenants']?['name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
