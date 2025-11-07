// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/constant/error_handling.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:smart_cashier_app/providers/user_provider.dart';

class ProductServices {
  Future<List<Product>> fetchAllProducts(
      {required BuildContext context}) async {
    List<Product> listProduct = [];
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    try {
      http.Response res = await http.get(
        Uri.parse('$baseUrl/api/products'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );
      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () async {
          final resDecode = jsonDecode(res.body);
          listProduct = List<Product>.from(
            resDecode.map((item) => Product.fromMap(item)),
          );
        },
      );
      debugPrint("Success Fetch Product!");
      return listProduct;
    } catch (e) {
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return listProduct;
  }
}
