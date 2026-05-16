class Property {
  final String id;
  final String userId;
  final String name;
  final String? type;
  final String? address;
  final int rentDueDay;
  final DateTime createdAt;
  final DateTime updatedAt;

  Property({
    required this.id,
    required this.userId,
    required this.name,
    this.type,
    this.address,
    this.rentDueDay = 5,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      type: json['type'],
      address: json['address'],
      rentDueDay: json['rent_due_day'] ?? 5,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'address': address,
      'rent_due_day': rentDueDay,
    };
  }
}
