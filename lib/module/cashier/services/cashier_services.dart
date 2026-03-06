import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/constant/error_handling.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/cart.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:smart_cashier_app/providers/user_provider.dart';

class CashierServices {
  double _roundTo(double value, int fractionDigits) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  Future<bool> createSales({
    required BuildContext context,
    required List<CartItem> cartItems,
    required double totalPrice,
    double? totalPayout,
    required String paymentMethod,
    required String paymentStatus,
    required String customerName,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool isSuccess = false;
    try {
      final List<Map<String, dynamic>> items = cartItems.map((item) {
        final unitPriceSnapshot = item.unitPriceSnapshot;
        return {
          "id_product": item.product.id,
          "id_product_unit": item.selectedUnit?.id ?? 1,
          "quantity": _roundTo(item.qty, 3),
          "unit_price_snapshot": _roundTo(unitPriceSnapshot, 2),
          "cogs_snapshot": _roundTo(item.product.purchasedPrice, 2),
          "discount_percent": item.discountPercentForPayload == null
              ? null
              : _roundTo(item.discountPercentForPayload!, 1),
          "discount_amount": _roundTo(item.discountAmount, 2),
          "sub_total": _roundTo(item.total, 2),
        };
      }).toList();

      final Map<String, dynamic> bodyPost = {
        "id_user": userProvider.user.id, // atau sesuai field usermu
        "total_price": _roundTo(totalPrice, 2),
        "total_payout": _roundTo(totalPayout ?? totalPrice, 2),
        "payment_method": paymentMethod,
        "payment_status": paymentStatus,
        "customer_name": customerName,
        "items": items,
      };

      http.Response res = await http.post(
        Uri.parse('$baseUrl/api/sales'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.user.token,
        },
        body: jsonEncode(bodyPost),
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          isSuccess = true;
          showSnackBar(
            context,
            bgColor: Colors.green,
            "Sales has been Recorded. Thank You For Purchasing",
          );
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(
        context,
        bgColor: Colors.red,
        e.toString(),
      );
    }
    return isSuccess;
  }

  Future<bool> updateSales({
    required BuildContext context,
    required int id,
    required List<CartItem> cartItems,
    required double totalPrice,
    double? totalPayout,
    required String paymentMethod,
    required String paymentStatus,
    required String customerName,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    bool isSuccess = false;
    try {
      final List<Map<String, dynamic>> items = cartItems.map((item) {
        final unitPriceSnapshot = item.unitPriceSnapshot;
        return {
          "id_product": item.product.id,
          "id_product_unit": item.selectedUnit?.id ?? 1,
          "quantity": _roundTo(item.qty, 3),
          "unit_price_snapshot": _roundTo(unitPriceSnapshot, 2),
          "cogs_snapshot": _roundTo(item.product.purchasedPrice, 2),
          "discount_percent": item.discountPercentForPayload == null
              ? null
              : _roundTo(item.discountPercentForPayload!, 1),
          "discount_amount": _roundTo(item.discountAmount, 2),
          "sub_total": _roundTo(item.total, 2),
        };
      }).toList();

      final Map<String, dynamic> bodyPut = {
        "id_user": userProvider.id,
        "total_price": _roundTo(totalPrice, 2),
        "total_payout": _roundTo(totalPayout ?? totalPrice, 2),
        "payment_method": paymentMethod,
        "payment_status": paymentStatus,
        "customer_name": customerName,
        "items": items,
      };

      http.Response res = await http.put(
        Uri.parse('$baseUrl/api/sales/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
        body: jsonEncode(bodyPut),
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          isSuccess = true;
          showSnackBar(
            context,
            bgColor: Colors.green,
            "Sales updated successfully",
          );
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(
        context,
        bgColor: Colors.red,
        e.toString(),
      );
    }
    return isSuccess;
  }

  Future<List<Product?>> fetchAllProducts(
      {required BuildContext context}) async {
    List<Product> list_product = [];
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    try {
      http.Response res =
          await http.get(Uri.parse('$baseUrl/api/products'), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'x-auth-token': userProvider.token,
      });
      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final resDecode = jsonDecode(res.body);
          list_product = List<Product>.from(
            (resDecode as List).map(
              (item) => Product.fromMap(item as Map<String, dynamic>),
            ),
          );
        },
      );
      return list_product;
    } catch (e) {
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return list_product;
  }

  Future<Product?> fetchProductByBarcode({
    required BuildContext context,
    required String barcode,
  }) async {
    Product? product;
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    try {
      http.Response res =
          await http.get(Uri.parse('$baseUrl/api/product/$barcode'), headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'x-auth-token': userProvider.token,
      });
      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final resDecoded = json.decode(res.body);
          product = Product.fromMap(resDecoded);
        },
      );
      return product;
    } catch (e) {
      showSnackBar(
        context,
        bgColor: Colors.red,
        e.toString(),
      );
    }
    return null;
  }
}
