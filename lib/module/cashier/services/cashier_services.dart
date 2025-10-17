import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/constant/error_handling.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:smart_cashier_app/providers/user_provider.dart';

class CashierServices {
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
      httpErrorhandle(response: res, context: context, onSuccess: () {
        final resDecoded = json.decode(res.body); 
        product =  Product.fromMap(resDecoded);
      },);
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
