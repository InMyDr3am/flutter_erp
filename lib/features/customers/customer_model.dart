class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.notes,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? notes;

  factory Customer.fromMap(Map<String, dynamic> map) => Customer(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        address: map['address'] as String?,
        notes: map['notes'] as String?,
      );
}
