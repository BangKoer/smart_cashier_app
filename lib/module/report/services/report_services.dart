import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/constant/error_handling.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';

class ReportServices {
  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  Future<Map<String, dynamic>> fetchKpiSummary({
    required BuildContext context,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? paymentStatus, // paid | pending | null (all)
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;

    final queryParameters = <String, String>{};
    if (dateFrom != null) {
      queryParameters['date_from'] = _formatDate(dateFrom);
    }
    if (dateTo != null) {
      queryParameters['date_to'] = _formatDate(dateTo);
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParameters['payment_status'] = paymentStatus.toLowerCase();
    }

    final uri = Uri.parse('$baseUrl/api/sales/kpi-summary').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    Map<String, dynamic> result = {
      "total_transaction": 0,
      "total_sales": 0.0,
      "total_profit": 0.0,
      "avg_transaction_value": 0.0,
      "filters": {
        "date_from": null,
        "date_to": null,
        "payment_status": "all",
      },
    };

    try {
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final decoded = jsonDecode(res.body) as Map<String, dynamic>;
          result = {
            "total_transaction":
                _toInt(decoded["total_transaction"]),
            "total_sales": _toDouble(decoded["total_sales"]),
            "total_profit":
                _toDouble(decoded["total_profit"]),
            "avg_transaction_value":
                _toDouble(decoded["avg_transaction_value"]),
            "filters": decoded["filters"] ?? result["filters"],
          };
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }

    return result;
  }

  Future<Map<String, dynamic>> fetchSalesSeries({
    required BuildContext context,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? paymentStatus, // paid | pending | null (all)
    String? groupBy, // day | week | month | null (auto)
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;

    final queryParameters = <String, String>{};
    if (dateFrom != null) {
      queryParameters['date_from'] = _formatDate(dateFrom);
    }
    if (dateTo != null) {
      queryParameters['date_to'] = _formatDate(dateTo);
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParameters['payment_status'] = paymentStatus.toLowerCase();
    }
    if (groupBy != null && groupBy.isNotEmpty) {
      queryParameters['group_by'] = groupBy.toLowerCase();
    }

    final uri = Uri.parse('$baseUrl/api/sales/chart-series').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    Map<String, dynamic> result = {
      "group_by": "day",
      "points": <Map<String, dynamic>>[],
      "filters": {
        "date_from": null,
        "date_to": null,
        "payment_status": "all",
      },
    };

    try {
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final decoded = jsonDecode(res.body) as Map<String, dynamic>;
          final pointsRaw = (decoded["points"] as List?) ?? const [];
          final points = pointsRaw
              .whereType<Map<String, dynamic>>()
              .map((item) => {
                    "label": item["label"]?.toString() ?? "",
                    "total_sales": _toDouble(item["total_sales"]),
                    "total_profit": _toDouble(item["total_profit"]),
                    "total_transaction": _toInt(item["total_transaction"]),
                  })
              .toList();

          result = {
            "group_by": decoded["group_by"]?.toString() ?? "day",
            "points": points,
            "filters": decoded["filters"] ?? result["filters"],
          };
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> fetchCategorySales({
    required BuildContext context,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? paymentStatus,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    final queryParameters = <String, String>{};

    if (dateFrom != null) {
      queryParameters['date_from'] = _formatDate(dateFrom);
    }
    if (dateTo != null) {
      queryParameters['date_to'] = _formatDate(dateTo);
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParameters['payment_status'] = paymentStatus.toLowerCase();
    }

    final uri = Uri.parse('$baseUrl/api/sales/category-sales').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    List<Map<String, dynamic>> result = [];

    try {
      final res = await http.get(uri, headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'x-auth-token': userProvider.token,
      });

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final decoded = jsonDecode(res.body) as List;
          result = decoded
              .whereType<Map<String, dynamic>>()
              .map((item) => {
                    "category_id": item["category_id"],
                    "category_name": item["category_name"],
                    "total_sales": _toDouble(item["total_sales"]),
                  })
              .toList();
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> fetchProductSales({
    required BuildContext context,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? paymentStatus,
    String? sortBy,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false).user;
    final queryParameters = <String, String>{};

    // if (dateFrom != null) {
    //   queryParameters['date_from'] = _formatDate(dateFrom);
    // }
    // if (dateTo != null) {
    //   queryParameters['date_to'] = _formatDate(dateTo);
    // }
    if (sortBy != null && sortBy.isNotEmpty) {
      queryParameters['sort_by'] = sortBy.toLowerCase();
    }
    if (paymentStatus != null && paymentStatus.isNotEmpty) {
      queryParameters['payment_status'] = paymentStatus.toLowerCase();
    }

    final uri = Uri.parse('$baseUrl/api/sales/product-sales').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    List<Map<String, dynamic>> result = [];

    try {
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.token,
        },
      );

      httpErrorhandle(
        response: res,
        context: context,
        onSuccess: () {
          final decoded = jsonDecode(res.body) as List;
          result = decoded
              .whereType<Map<String, dynamic>>()
              .map((item) => {
                    "product_id": item["product_id"],
                    "product_name": item["product_name"],
                    "total_sales":_toDouble(item["total_sales"]),
                  })
              .toList();
        },
      );
    } catch (e) {
      debugPrint(e.toString());
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }

    return result;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
