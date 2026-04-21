// import 'dart:ui';

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
// import 'package:smart_cashier_app/common/widgets/custom_sidebar_home.dart';
// import 'package:smart_cashier_app/constant/global_variables.dart';
// import 'package:smart_cashier_app/module/auth/screens/auth_screen.dart';
// import 'package:smart_cashier_app/module/auth/services/auth_services.dart';
// import 'package:smart_cashier_app/providers/user_provider.dart';
// import 'package:smart_cashier_app/router.dart';

// void main() {
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => UserProvider()),
//       ],
//       child: const MyApp(),
//     ),
//   );
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'SMART POS Cashier',
//       scrollBehavior: const MaterialScrollBehavior().copyWith(
//         dragDevices: {
//           PointerDeviceKind.mouse,
//           PointerDeviceKind.touch,
//           PointerDeviceKind.stylus,
//           PointerDeviceKind.unknown
//         },
//       ),
//       theme: ThemeData(
//         useMaterial3: true,
//         scaffoldBackgroundColor: GlobalVariables.backgroundColor,
//         colorScheme: const ColorScheme.light(
//           primary: GlobalVariables.secondaryColor,
//         ),
//         appBarTheme: const AppBarTheme(
//           elevation: 0,
//           backgroundColor: GlobalVariables.secondaryColor,
//           foregroundColor: GlobalVariables.backgroundColor,
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             backgroundColor: GlobalVariables.thirdColor,
//             foregroundColor: Colors.white,
//           ),
//         ),
//       ),
//       onGenerateRoute: (settings) => generateRoute(settings),
//       home: const _InitApp(),
//     );
//   }
// }

// class _InitApp extends StatelessWidget {
//   const _InitApp();

//   Future<void> _initializeApp(BuildContext context) async {
//     final authServices = AuthServices();
//     await authServices.getUserdata(context);
//     // await Future.delayed(const Duration(seconds: 2)); // optional delay
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: _initializeApp(context),
//       builder: (context, snapshot) {
//         // 1️⃣ Loading
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return const CustomLoading();
//         }

//         // 2️⃣ Error handling
//         if (snapshot.hasError) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             ScaffoldMessenger.of(context).showSnackBar(
//               SnackBar(
//                 content: Text('Error: ${snapshot.error}'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//           });
//           return const AuthScreen();
//         }

//         // 3️⃣ Success → cek token
//         final userProvider = Provider.of<UserProvider>(context);
//         final user = userProvider.user;

//         if (user.token.isEmpty) return const AuthScreen();

//         if (user.role == 'admin') {
//           return const CustomSidebarHome();
//         } else {
//           return const AuthScreen();
//         }
//       },
//     );
//   }
// }

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/common/widgets/custom_sidebar_home.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/auth/screens/auth_screen.dart';
import 'package:smart_cashier_app/module/auth/services/auth_services.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';
import 'package:smart_cashier_app/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backendOk = await LocalBackendRunner.instance.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MyApp(backendReady: backendOk),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool backendReady;
  const MyApp({super.key, required this.backendReady});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onDetach: () async {
        await LocalBackendRunner.instance.stop();
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SMART POS Cashier',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown
        },
      ),
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
      home: _InitApp(backendReady: widget.backendReady),
    );
  }
}

class _InitApp extends StatelessWidget {
  final bool backendReady;
  const _InitApp({required this.backendReady});

  Future<void> _initializeApp(BuildContext context) async {
    final authServices = AuthServices();
    await authServices.getUserdata(context);
  }

  @override
  Widget build(BuildContext context) {
    if (!backendReady) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Backend failed to start.\nPlease restart app or check server package.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return FutureBuilder(
      future: _initializeApp(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CustomLoading();
        }

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

        final userProvider = Provider.of<UserProvider>(context);
        final user = userProvider.user;

        if (user.token.isEmpty) return const AuthScreen();
        if (user.role == 'admin') return const CustomSidebarHome();

        return const AuthScreen();
      },
    );
  }
}

class LocalBackendRunner {
  LocalBackendRunner._();
  static final LocalBackendRunner instance = LocalBackendRunner._();

  Process? _process;
  bool _starting = false;

  Future<bool> start() async {
    if (!Platform.isWindows) return true;
    if (_process != null) return true;
    if (_starting) return false;

    _starting = true;
    try {
      final exeDir = Directory.current.path;

      // Packaged structure (recommended):
      // <app>/dist_backend/node.exe
      // <app>/dist_backend/server/index.js
      final packagedNode = _join(exeDir, ['dist_backend', 'node.exe']);
      final packagedServerEntry =
          _join(exeDir, ['dist_backend', 'server', 'index.js']);

      // Dev fallback:
      // <project>/server/index.js (uses system "node")
      final devServerEntry = _join(exeDir, ['server', 'index.js']);

      final hasPackaged = File(packagedNode).existsSync() &&
          File(packagedServerEntry).existsSync();

      final nodeCommand = hasPackaged ? packagedNode : 'node';
      final serverEntry = hasPackaged ? packagedServerEntry : devServerEntry;

      if (!File(serverEntry).existsSync()) {
        stderr.writeln('[Backend] server entry not found: $serverEntry');
        return false;
      }

      _process = await Process.start(
        nodeCommand,
        [serverEntry],
        mode: ProcessStartMode.normal,
      );

      _process!.stdout.transform(SystemEncoding().decoder).listen((line) {
        stdout.writeln('[Backend] $line');
      });
      _process!.stderr.transform(SystemEncoding().decoder).listen((line) {
        stderr.writeln('[Backend:ERR] $line');
      });

      final healthy = await _waitUntilHealthy();
      if (!healthy) {
        await stop();
        return false;
      }

      return true;
    } catch (e) {
      stderr.writeln('[Backend] failed to start: $e');
      await stop();
      return false;
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    final p = _process;
    _process = null;
    if (p == null) return;
    try {
      p.kill();
    } catch (_) {}
  }

  Future<bool> _waitUntilHealthy() async {
    final uri = Uri.parse('$baseUrl/api/health');
    for (int i = 0; i < 30; i++) {
      try {
        final res = await http.get(uri).timeout(const Duration(seconds: 1));
        if (res.statusCode == 200) return true;
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return false;
  }

  String _join(String root, List<String> segments) {
    return [root, ...segments].join(Platform.pathSeparator);
  }
}
