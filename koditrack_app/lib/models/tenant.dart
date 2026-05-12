class Tenant {
  final String id;
  final String propertyId;
  final String? unitId;
  final String name;
  final String phone;
  final String? email;
  final double baseRent;
  final double serviceCharge;
  final double openingBalance;
  final DateTime? leaseStart;
  final DateTime? leaseEnd;
  final bool whatsappEnabled;
  final String reminderPreference;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tenant({
    required this.id,
    required this.propertyId,
    this.unitId,
    required this.name,
    required this.phone,
    this.email,
    required this.baseRent,
    this.serviceCharge = 0,
    this.openingBalance = 0,
    this.leaseStart,
    this.leaseEnd,
    this.whatsappEnabled = false,
    this.reminderPreference = 'whatsapp',
    required this.createdAt,
    required this.updatedAt,
  });

  double get totalMonthlyBill => baseRent + serviceCharge;

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id'],
      propertyId: json['property_id'],
      unitId: json['unit_id'],
      name: json['name'],
      phone: json['phone'],
      email: json['email'],
      baseRent: double.parse(json['base_rent'].toString()),
      serviceCharge: double.parse((json['service_charge'] ?? 0).toString()),
      openingBalance: double.parse((json['opening_balance'] ?? 0).toString()),
      leaseStart: json['lease_start'] != null
          ? DateTime.parse(json['lease_start'])
          : null,
      leaseEnd: json['lease_end'] != null
          ? DateTime.parse(json['lease_end'])
          : null,
      whatsappEnabled: json['whatsapp_enabled'] ?? false,
      reminderPreference: json['reminder_preference'] ?? 'whatsapp',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
