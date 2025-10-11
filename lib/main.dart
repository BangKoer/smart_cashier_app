import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/auth/screens/auth_screen.dart';
import 'package:smart_cashier_app/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'S\'MART POS Cashier',
      theme: ThemeData(
        scaffoldBackgroundColor: GlobalVariables.backgroundColor,
        colorScheme: const ColorScheme.light(
          primary: GlobalVariables.secondaryColor,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: GlobalVariables.secondaryColor,
          foregroundColor: GlobalVariables.backgroundColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: GlobalVariables.secondaryColor,
            foregroundColor: Colors.white,
          )
        ),
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home: AuthScreen(),
    );
  }
}