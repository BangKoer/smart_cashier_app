import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:smart_cashier_app/constant/utils.dart';

void httpErrorhandle({
  required http.Response response,
  required BuildContext context,
  required VoidCallback onSuccess,
}) {
  switch (response.statusCode) {
    case 200:
      onSuccess();
      break;
    case 201:
      onSuccess();
      break;
    case 400:
      showSnackBar(
        context,
        jsonDecode(response.body)['msg'],
        bgColor: Colors.red,
      );
      break;
    case 500:
      showSnackBar(
        context,
        jsonDecode(response.body)['error'],
        bgColor: Colors.red,
      );
      break;
    default:
      showSnackBar(
        context,
        jsonDecode(response.body).toString(),
        bgColor: Colors.red,
      );
  }
}
