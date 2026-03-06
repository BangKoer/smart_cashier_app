import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/constant/error_handling.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';

class ReportServices {
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
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
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
                (decoded["total_transaction"] as num?)?.toInt() ?? 0,
            "total_sales": (decoded["total_sales"] as num?)?.toDouble() ?? 0.0,
            "total_profit":
                (decoded["total_profit"] as num?)?.toDouble() ?? 0.0,
            "avg_transaction_value":
                (decoded["avg_transaction_value"] as num?)?.toDouble() ?? 0.0,
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

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
