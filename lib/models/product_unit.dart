import 'dart:convert';

class ProductUnit {
  final int id;
  final int idProduct;
  final String nameUnit;
  final double price;
  final int conversion;

  ProductUnit(
      {required this.id,
      required this.idProduct,
      required this.nameUnit,
      required this.price,
      required this.conversion});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idProduct': idProduct,
      'nameUnit': nameUnit,
      'price': price,
      'conversion': conversion,
    };
  }

  factory ProductUnit.fromMap(Map<String, dynamic> map) {
    return ProductUnit(
      id: map['id'] ?? 0,
      idProduct: map['id_product'] ?? 0,
      nameUnit: map['name_unit'] ?? '',
      price: double.tryParse(map['price'].toString()) ?? 0.0,
      conversion: map['conversion'] ?? 1,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProductUnit.fromJson(String source) => ProductUnit.fromMap(json.decode(source));
}
