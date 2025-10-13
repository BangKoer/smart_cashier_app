import 'package:flutter/material.dart';

String baseUrl = 'http://192.168.220.140:3000';

class GlobalVariables {
  // For storing api base url

  // COLORS
  static const appBarGradient = LinearGradient(
    colors: [
      Color.fromARGB(255, 29, 201, 192),
      Color.fromARGB(255, 125, 221, 216),
    ],
    stops: [0.5, 1.0],
  );

  static const secondaryColor = Color.fromRGBO(0, 46, 50, 1);
  static const thirdColor = Color.fromRGBO(241, 85, 19, 1);
  static const backgroundColor = Colors.white;
  static const Color greyBackgroundCOlor = Color(0xffebecee);
  static var selectedNavBarColor = const Color(0x00133144);
  static const unselectedNavBarColor = Colors.black87;
}
