class Unit {
  final String id;
  final String propertyId;
  final String unitNumber;
  final int? floor;
  final String? unitType;
  final double? defaultRent;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Unit({
    required this.id,
    required this.propertyId,
    required this.unitNumber,
    this.floor,
    this.unitType,
    this.defaultRent,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    return Unit(
      id: json['id'],
      propertyId: json['property_id'],
      unitNumber: json['unit_number'],
      floor: json['floor'],
      unitType: json['unit_type'],
      defaultRent: json['default_rent'] != null
          ? double.parse(json['default_rent'].toString())
          : null,
      status: json['status'] ?? 'vacant',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
