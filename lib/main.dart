import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/common/widgets/custom_sidebar_home.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/auth/screens/auth_screen.dart';
import 'package:smart_cashier_app/module/auth/services/auth_services.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';
import 'package:smart_cashier_app/router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMART POS Cashier',
      theme: ThemeData(
        useMaterial3: true,
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
            backgroundColor: GlobalVariables.thirdColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      onGenerateRoute: (settings) => generateRoute(settings),
      home: const _InitApp(),
    );
  }
}

class _InitApp extends StatelessWidget {
  const _InitApp();

  Future<void> _initializeApp(BuildContext context) async {
    final authServices = AuthServices();
    await authServices.getUserdata(context);
    // await Future.delayed(const Duration(seconds: 2)); // optional delay
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeApp(context),
      builder: (context, snapshot) {
        // 1️⃣ Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoading();
        }

        // 2️⃣ Error handling
        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${snapshot.error}'),
                backgroundColor: Colors.red,
              ),
            );
          });
          return const AuthScreen();
        }

        // 3️⃣ Success → cek token
        final userProvider = Provider.of<UserProvider>(context);
        final user = userProvider.user;

        if (user.token.isEmpty) return const AuthScreen();

        if (user.role == 'admin') {
          return const CustomSidebarHome();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
