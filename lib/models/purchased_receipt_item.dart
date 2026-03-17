import 'dart:convert';

class PurchasedReceiptItem {
  final int id;
  final int idPurchasedReceipt;
  final int idProduct;
  final int idProductUnit;
  final double qty;
  final double unitCost;
  final double subTotal;
  final String? productName;

  PurchasedReceiptItem({
    required this.id,
    required this.idPurchasedReceipt,
    required this.idProduct,
    required this.idProductUnit,
    required this.qty,
    required this.unitCost,
    required this.subTotal,
    this.productName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_purchased_receipt': idPurchasedReceipt,
      'id_product': idProduct,
      'id_product_unit': idProductUnit,
      'qty': qty,
      'unit_cost': unitCost,
      'sub_total': subTotal,
      'product_name': productName,
    };
  }

  factory PurchasedReceiptItem.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return PurchasedReceiptItem(
      id: map['id'] ?? 0,
      idPurchasedReceipt: map['id_purchased_receipt'] ?? 0,
      idProduct: map['id_product'] ?? 0,
      idProductUnit: map['id_product_unit'] ?? 0,
      qty: _toDouble(map['qty']),
      unitCost: _toDouble(map['unit_cost']),
      subTotal: _toDouble(map['sub_total']),
      productName: map['product_name'] ??
          (map['product'] is Map
              ? (map['product'] as Map)['product_name']?.toString()
              : null),
    );
  }

  String toJson() => json.encode(toMap());

  factory PurchasedReceiptItem.fromJson(String source) =>
      PurchasedReceiptItem.fromMap(json.decode(source));
}
