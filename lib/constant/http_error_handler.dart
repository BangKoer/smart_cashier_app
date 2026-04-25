import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void httpErrorHandler ({
  required http.Response response,
  required VoidCallback onSuccess,
}) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    onSuccess();
  } else {
    final resDecode = jsonDecode(response.body);
    throw Exception(
      resDecode['msg'] ?? resDecode['error'] ?? resDecode.toString()
    );
  }

}