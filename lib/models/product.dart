import 'dart:convert';

import 'package:smart_cashier_app/models/category.dart';
import 'package:smart_cashier_app/models/product_unit.dart';

class Product {
  final int id;
  final String barcode;
  final String productName;
  final int stock;
  final double purchasedPrice;
  final int idCategory;
  final List<ProductUnit> units;
  final Category category;

  Product(
      {required this.id,
      required this.barcode,
      required this.productName,
      required this.stock,
      required this.purchasedPrice,
      required this.idCategory,
      required this.units,
      required this.category});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'barcode': barcode,
      'productName': productName,
      'stock': stock,
      'purchasedPrice': purchasedPrice,
      'idCategory': idCategory,
      'units': units.map((x) => x.toMap()).toList(),
      'category': category.toMap(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? 0,
      barcode: map['barcode'] ?? '',
      productName: map['product_name'] ?? '',
      stock: map['stock'] ?? 0,
      purchasedPrice: double.tryParse(map['purchased_price'].toString()) ?? 0.0,
      idCategory: map['id_category'] ?? 0,
      units: (map['units'] as List<dynamic>?)
              ?.map((u) => ProductUnit.fromMap(u))
              .toList() ??
          [],
      category: map['category'] != null
          ? Category.fromMap(map['category'])
          : Category.fromMap(map['name']),
    );
  }

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) =>
      Product.fromMap(json.decode(source));
}
