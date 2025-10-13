import 'package:flutter/material.dart';
import 'package:smart_cashier_app/module/auth/screens/auth_screen.dart';
import 'package:smart_cashier_app/module/home/screens/home_screen.dart';

Route<dynamic> generateRoute(RouteSettings routeSettings) {
  switch (routeSettings.name) {
    case AuthScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const AuthScreen(),
      );
    case HomeScreen.routeName:
      return MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      );
    default:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(
            child: Text('Screen Doesnt Exitst!!'),
          ),
        ),
      );
  }
}
