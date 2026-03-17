import 'dart:convert';

class Supplier {
  final int id;
  final String name;
  final String? company;
  final String? phone;
  final String? address;

  Supplier({
    required this.id,
    required this.name,
    this.company,
    this.phone,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'company': company,
      'phone': phone,
      'address': address,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] ?? 0,
      name: map['supplier_name'] ?? map['name'] ?? '',
      company: map['company'],
      phone: map['phone'],
      address: map['address'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Supplier.fromJson(String source) =>
      Supplier.fromMap(json.decode(source));
}
