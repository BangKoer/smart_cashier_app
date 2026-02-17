import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/constant/error_handling.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/sales.dart';
import 'package:http/http.dart' as http;
import 'package:smart_cashier_app/providers/user_provider.dart';

class SalesServices {
  Future<List<Sales>> fetchAllSales({required BuildContext context}) async {
    List<Sales> listSales = [];
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    try {
      http.Response res = await http.get(
        Uri.parse('$baseUrl/api/sales'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );
      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final resDecode = jsonDecode(res.body);
          listSales = List<Sales>.from(
            (resDecode as List).map(
              (item) => Sales.fromMap(item as Map<String, dynamic>),
            ),
          );
        },
      );
      return listSales;
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return listSales;
  }

  Future<Sales?> fetchSalesById({
    required BuildContext context,
    required int id,
  }) async {
    Sales? sales;
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    try {
      http.Response res = await http.get(
        Uri.parse('$baseUrl/api/sales/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );
      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final resDecode = jsonDecode(res.body);
          sales = Sales.fromMap(resDecode);
        },
      );
      return sales;
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return null;
  }

  Future<bool> updateSales({
    required BuildContext context,
    required int id,
    required int idUser,
    required double totalPrice,
    required String paymentMethod,
    required String paymentStatus,
    required String customerName,
    required List<Map<String, dynamic>> items,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    bool isSuccess = false;
    try {
      final List<Map<String, dynamic>> itemsPayload = items.map((item) {
        return {
          "id_product": item["id_product"],
          "id_product_unit": item["id_product_unit"],
          "quantity": item["quantity"],
          "sub_total": item["sub_total"],
        };
      }).toList();

      final Map<String, dynamic> bodyPut = {
        "id_user": idUser,
        "total_price": totalPrice,
        "payment_method": paymentMethod,
        "payment_status": paymentStatus,
        "customer_name": customerName,
        "items": itemsPayload,
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
            "Sales updated successfully",
            bgColor: Colors.green,
          );
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return isSuccess;
  }
}
