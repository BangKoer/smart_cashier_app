import 'dart:convert';

import 'package:smart_cashier_app/models/saleItems.dart';

class Sales {
  final int id;
  final int id_user;
  final String created_at;
  final String? customer_name;
  final String payment_method;
  final String payment_status;
  final double total_price;
  final double total_payout;
  final List<Saleitems> salesItems;

  Sales(
      {required this.id,
      required this.id_user,
      required this.created_at,
      required this.customer_name,
      required this.payment_method,
      required this.payment_status,
      required this.salesItems,
      required this.total_price,
      required this.total_payout});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_user': id_user,
      'created_at': created_at,
      'customer_name': customer_name,
      'payment_method': payment_method,
      'payment_status': payment_status,
      'total_price': total_price,
      'total_payout': total_payout,
      'items': salesItems.map((x) => x.toMap()).toList(),
    };
  }

  factory Sales.fromMap(Map<String, dynamic> map) {
    final dynamic rawItems = map['items'] ?? map['salesItems'] ?? [];
    return Sales(
      id: map['id']?.toInt() ?? 0,
      id_user: map['id_user']?.toInt() ?? 0,
      created_at: map['created_at']?.toString() ?? '',
      customer_name: map['customer_name']?.toString(),
      payment_method: map['payment_method'] ?? '',
      payment_status: map['payment_status'] ?? '',
      total_price: double.tryParse((map['total_price'] ?? 0).toString()) ?? 0.0,
      total_payout:
          double.tryParse((map['total_payout'] ?? map['total_price'] ?? 0).toString()) ??
              0.0,
      salesItems: rawItems is List
          ? rawItems.map((x) => Saleitems.fromMap(x)).toList()
          : <Saleitems>[],
    );
  }

  String toJson() => json.encode(toMap());

  factory Sales.fromJson(String source) => Sales.fromMap(json.decode(source));
}
