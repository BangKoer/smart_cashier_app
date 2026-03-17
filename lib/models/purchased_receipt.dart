import 'dart:convert';

import 'package:smart_cashier_app/models/purchased_receipt_file.dart';
import 'package:smart_cashier_app/models/purchased_receipt_item.dart';
import 'package:smart_cashier_app/models/supplier.dart';

class PurchasedReceipt {
  final int id;
  final String receiptNo;
  final int idSupplier;
  final String receiptDate;
  final double totalCost;
  final String? note;
  final Supplier? supplier;
  final List<PurchasedReceiptItem> items;
  final List<PurchasedReceiptFile> files;

  PurchasedReceipt({
    required this.id,
    required this.receiptNo,
    required this.idSupplier,
    required this.receiptDate,
    required this.totalCost,
    this.note,
    this.supplier,
    required this.items,
    required this.files,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receipt_no': receiptNo,
      'id_supplier': idSupplier,
      'receipt_date': receiptDate,
      'total_cost': totalCost,
      'note': note,
      'supplier': supplier?.toMap(),
      'items': items.map((x) => x.toMap()).toList(),
      'files': files.map((x) => x.toMap()).toList(),
    };
  }

  factory PurchasedReceipt.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final receiptMap =
        map['receipt'] is Map<String, dynamic> ? map['receipt'] as Map<String, dynamic> : map;
    final itemsRaw = map['items'];
    final filesRaw = map['files'];

    return PurchasedReceipt(
      id: receiptMap['id'] ?? 0,
      receiptNo: receiptMap['receipt_no'] ?? '',
      idSupplier: receiptMap['id_supplier'] ?? 0,
      receiptDate: receiptMap['receipt_date'] ?? receiptMap['date'] ?? '',
      totalCost: _toDouble(receiptMap['total_cost']),
      note: receiptMap['note'],
      supplier: receiptMap['supplier'] != null
          ? Supplier.fromMap(receiptMap['supplier'])
          : null,
      items: (itemsRaw as List<dynamic>?)
              ?.map((e) => PurchasedReceiptItem.fromMap(e))
              .toList() ??
          [],
      files: (filesRaw as List<dynamic>?)
              ?.map((e) => PurchasedReceiptFile.fromMap(e))
              .toList() ??
          [],
    );
  }

  String toJson() => json.encode(toMap());

  factory PurchasedReceipt.fromJson(String source) =>
      PurchasedReceipt.fromMap(json.decode(source));
}
