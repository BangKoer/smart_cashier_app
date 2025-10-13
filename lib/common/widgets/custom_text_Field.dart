import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController textEditingController;
  final String hintText;
  final int? maxLines;
  final Color? borderColor;
  final IconData? icontf;
  final bool? isPasswordField;
  final TextInputType? inputType;
  const CustomTextField({
    super.key,
    required this.textEditingController,
    required this.hintText,
    this.maxLines = 1,
    this.borderColor = GlobalVariables.backgroundColor,
    this.icontf = Icons.abc,
    this.isPasswordField = false,
    this.inputType,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TextFormField(
        controller: widget.textEditingController,
        obscureText: widget.isPasswordField! && !isVisible,
        keyboardType: widget.inputType,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.black38),
          prefixIcon: Icon(
            widget.icontf,
            color: Colors.black45,
          ),
          suffix: widget.isPasswordField!
              ? GestureDetector(
                  onTap: () {
                    setState(() {
                      isVisible = !isVisible;
                    });
                  },
                  child: isVisible
                      // ignore: dead_code
                      ? Icon(Icons.visibility)
                      : const Icon(Icons.visibility_off),
                )
              : null,
          filled: true,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: widget.borderColor!),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.borderColor!),
              borderRadius: BorderRadius.circular(10)),
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Enter Your ${widget.hintText}';
          } else {
            return null;
          }
        },
        maxLines: widget.maxLines,
      ),
    );
  }
}
