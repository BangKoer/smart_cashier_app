import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController textEditingController;
  final String hintText;
  final int? maxLines;
  final Color? borderColor;
  const CustomTextField(
      {super.key,
      required this.textEditingController,
      required this.hintText,
      this.maxLines = 1,
      this.borderColor = GlobalVariables.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TextFormField(
        controller: textEditingController,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black38),
          border: const OutlineInputBorder(),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor!),
          ),
          
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Enter Your $hintText';
          } else {
            return null;
          }
        },
        maxLines: maxLines,
      ),
    );
  }
}
