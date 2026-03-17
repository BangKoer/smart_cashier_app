import 'dart:convert';

class PurchasedReceiptFile {
  final int id;
  final int idPurchasedReceipt;
  final String filePath;
  final String fileName;
  final String? uploadedAt;

  PurchasedReceiptFile({
    required this.id,
    required this.idPurchasedReceipt,
    required this.filePath,
    required this.fileName,
    this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_purchased_receipt': idPurchasedReceipt,
      'file_path': filePath,
      'file_name': fileName,
      'uploaded_at': uploadedAt,
    };
  }

  factory PurchasedReceiptFile.fromMap(Map<String, dynamic> map) {
    int _toInt(dynamic v) {
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return PurchasedReceiptFile(
      id: _toInt(map['id']),
      idPurchasedReceipt: _toInt(map['id_purchased_receipt']),
      filePath: map['file_path'] ?? '',
      fileName: map['file_name'] ?? map['original_name'] ?? '',
      uploadedAt: map['uploaded_at']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory PurchasedReceiptFile.fromJson(String source) =>
      PurchasedReceiptFile.fromMap(json.decode(source));
}
