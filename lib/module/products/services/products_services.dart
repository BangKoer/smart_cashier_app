// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/constant/error_handling.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/category.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:http/http.dart' as http;
import 'package:smart_cashier_app/providers/user_provider.dart';

class ProductServices {
  Future<List<Category>> fetchAllCategories({required BuildContext context}) async {
    List<Category> listCategories = [];
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    try {
      http.Response res = await http.get(
        Uri.parse('$baseUrl/api/categories'),
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
          listCategories = List<Category>.from(
            resDecode.map((item) => Category.fromMap(item)),
          );
        },
      );
      debugPrint("Success Fetch Product!");
      return listCategories;
    } catch (e) {
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return listCategories;
  }

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

  Future<bool> addProduct({
    required BuildContext context,
    required String barcode,
    required String productName,
    required int stock,
    required double purchasedPrice,
    required int idCategory,
    required List<Map<String, dynamic>> units,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    bool isSuccess = false;

    try {
      final List<Map<String, dynamic>> unitsPayload = units.map((unit) {
        return {
          "name_unit": unit["name_unit"] ?? unit["nameUnit"] ?? "",
          "price": unit["price"],
          "conversion": unit["conversion"] ?? 1,
        };
      }).toList();

      final Map<String, dynamic> bodyPost = {
        "barcode": barcode,
        "product_name": productName,
        "stock": stock,
        "purchased_price": purchasedPrice,
        "id_category": idCategory,
        "units": unitsPayload,
      };

      http.Response res = await http.post(
        Uri.parse('$baseUrl/api/products'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
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
            "Product created successfully",
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

  Future<bool> updateProduct({
    required BuildContext context,
    required int id,
    required String barcode,
    required String productName,
    required int stock,
    required double purchasedPrice,
    required int idCategory,
    required List<Map<String, dynamic>> units,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    bool isSuccess = false;

    try {
      final List<Map<String, dynamic>> unitsPayload = units.map((unit) {
        return {
          "name_unit": unit["name_unit"] ?? unit["nameUnit"] ?? "",
          "price": unit["price"],
          "conversion": unit["conversion"] ?? 1,
        };
      }).toList();

      final Map<String, dynamic> bodyPut = {
        "barcode": barcode,
        "product_name": productName,
        "stock": stock,
        "purchased_price": purchasedPrice,
        "id_category": idCategory,
        "units": unitsPayload,
      };

      http.Response res = await http.put(
        Uri.parse('$baseUrl/api/products/$id'),
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
            "Product updated successfully",
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

  Future<bool> deleteProduct({
    required BuildContext context,
    required int id,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    bool isSuccess = false;

    try {
      http.Response res = await http.delete(
        Uri.parse('$baseUrl/api/product/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          isSuccess = true;
          showSnackBar(
            context,
            "Product deleted successfully",
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

class CategoryServices {
  Future<List<Category>> fetchAllCategories({
    required BuildContext context,
  }) async {
    List<Category> listCategories = [];
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    try {
      final http.Response res = await http.get(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final dynamic resDecode = jsonDecode(res.body);
          listCategories = List<Category>.from(
            (resDecode as List).map((item) => Category.fromMap(item)),
          );
        },
      );
      return listCategories;
    } catch (e) {
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return listCategories;
  }

  Future<Category?> fetchCategoryById({
    required BuildContext context,
    required int id,
  }) async {
    Category? category;
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    try {
      final http.Response res = await http.get(
        Uri.parse('$baseUrl/api/categories/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final Map<String, dynamic> resDecode = jsonDecode(res.body);
          category = Category.fromMap(resDecode);
        },
      );
      return category;
    } catch (e) {
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return null;
  }

  Future<bool> addCategory({
    required BuildContext context,
    required String name,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    bool isSuccess = false;
    try {
      final http.Response res = await http.post(
        Uri.parse('$baseUrl/api/categories'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
        body: jsonEncode({
          "name": name.trim(),
        }),
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          isSuccess = true;
          showSnackBar(
            context,
            "Category created successfully",
            bgColor: Colors.green,
          );
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return isSuccess;
  }

  Future<bool> updateCategory({
    required BuildContext context,
    required int id,
    required String name,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    bool isSuccess = false;
    try {
      final http.Response res = await http.put(
        Uri.parse('$baseUrl/api/categories/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
        body: jsonEncode({
          "name": name.trim(),
        }),
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          isSuccess = true;
          showSnackBar(
            context,
            "Category updated successfully",
            bgColor: Colors.green,
          );
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return isSuccess;
  }

  Future<bool> deleteCategory({
    required BuildContext context,
    required int id,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    bool isSuccess = false;
    try {
      final http.Response res = await http.delete(
        Uri.parse('$baseUrl/api/categories/$id'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          isSuccess = true;
          showSnackBar(
            context,
            "Category deleted successfully",
            bgColor: Colors.green,
          );
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
    return isSuccess;
  }
}
