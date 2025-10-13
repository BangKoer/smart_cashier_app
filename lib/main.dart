import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/auth/screens/auth_screen.dart';
import 'package:smart_cashier_app/module/auth/services/auth_services.dart';
import 'package:smart_cashier_app/module/home/screens/home_screen.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';
import 'package:smart_cashier_app/router.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserProvider(),
        )
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoading = true;
  final AuthServices authServices = AuthServices();

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> getData() async {
    await authServices.getUserdata(context);

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });
  }

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
          )),
        ),
        onGenerateRoute: (settings) => generateRoute(settings),
        home: _isLoading
            ? CustomLoading()
            : Provider.of<UserProvider>(context).user.token.isNotEmpty
                ? Provider.of<UserProvider>(context).user.role == 'admin'
                    ? const HomeScreen()
                    : const AuthScreen()
                : const AuthScreen());
  }
}
