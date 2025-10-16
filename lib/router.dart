import 'package:flutter/material.dart';
import 'package:smart_cashier_app/common/widgets/custom_sidebar_home.dart';
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
    case CustomSidebarHome.routeName:
      return MaterialPageRoute(
        builder: (_) => const CustomSidebarHome(),
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
