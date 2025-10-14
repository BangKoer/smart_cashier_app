import 'package:flutter/material.dart';

void showSnackBar(BuildContext context, String text,
    {Color bgColor = Colors.green, Color txColor = Colors.white}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        text,
        style: TextStyle(color: txColor),
      ),
      backgroundColor: bgColor,
    ),
  );
}
