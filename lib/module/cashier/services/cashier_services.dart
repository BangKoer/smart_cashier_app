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
  Future<void> createSales({
    required BuildContext context,
    required List<CartItem> cartItems,
    required double totalPrice,
    required String paymentMethod,
    required String paymentStatus,
    required String customerName,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      // Ubah item dalam CartItem jadi bentuk yang bisa di POST Ke Backend
      final List<Map<String, dynamic>> items = cartItems.map(
        (item) {
          return {
            "id_product": item.product.id,
            "id_product_unit": item.selectedUnit?.id ?? 1,
            "quantity": item.qty,
            "sub_total": item.total,
          };
        },
      ).toList();

      final Map<String, dynamic> bodyPost = {
        "id_user": userProvider.user.id, // atau sesuai field usermu
        "total_price": totalPrice,
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
