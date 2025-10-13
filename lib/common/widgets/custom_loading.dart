import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';

class CustomLoading extends StatelessWidget {
  const CustomLoading({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: LoadingAnimationWidget.inkDrop(
          color: GlobalVariables.thirdColor,
          size: 50,
        ),
      ),
    );  
  }
}
