import 'dart:convert';

class Saleitems {
  final int id;
  final int id_sales;
  final int id_product;
  final int id_product_unit;
  final double quantity;
  final double sub_total;
  final String? product_name;
  final String? product_unit;
  final double? unit_price;

  Saleitems({
    required this.id,
    required this.id_sales,
    required this.id_product,
    required this.id_product_unit,
    required this.quantity,
    required this.sub_total,
    this.product_name,
    this.product_unit,
    this.unit_price,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_sales': id_sales,
      'id_product': id_product,
      'id_product_unit': id_product_unit,
      'quantity': quantity,
      'sub_total': sub_total,
      // Optional display fields, useful for UI payloads.
      'product_name': product_name,
      'product_unit': product_unit,
      'unit_price': unit_price,
    };
  }

  factory Saleitems.fromMap(Map<String, dynamic> map) {
    final dynamic productMap = map['product'];
    final dynamic unitMap = map['unit'];

    return Saleitems(
      id: map['id']?.toInt() ?? 0,
      id_sales: map['id_sales']?.toInt() ?? 0,
      id_product: map['id_product']?.toInt() ?? 0,
      id_product_unit: map['id_product_unit']?.toInt() ?? 0,
      quantity: double.tryParse(
            (map['quantity'] ?? map['qty'] ?? 0).toString(),
          ) ??
          0.0,
      sub_total: double.tryParse(
            (map['sub_total'] ?? 0).toString(),
          ) ??
          0.0,
      product_name: map['product_name']?.toString() ??
          (productMap is Map ? productMap['product_name']?.toString() : null),
      product_unit: map['product_unit']?.toString() ??
          (unitMap is Map ? unitMap['name_unit']?.toString() : null),
      unit_price: double.tryParse(
        (map['unit_price'] ??
                (unitMap is Map ? unitMap['price'] : null) ??
                0)
            .toString(),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory Saleitems.fromJson(String source) =>
      Saleitems.fromMap(json.decode(source));
}
