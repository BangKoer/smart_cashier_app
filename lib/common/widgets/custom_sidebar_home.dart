import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/common/widgets/custom_info_panel.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/auth/services/auth_services.dart';
import 'package:smart_cashier_app/module/cashier/screens/cashier_screen.dart';
import 'package:smart_cashier_app/module/products/services/products_services.dart';
import 'package:smart_cashier_app/module/report/screens/report_screen.dart';
import 'package:smart_cashier_app/module/report/services/report_services.dart';
import 'package:smart_cashier_app/module/report/viewmodel/report_view_model.dart';
import 'package:smart_cashier_app/module/sales/screens/sales_screen.dart';
import 'package:smart_cashier_app/module/products/screens/produtcs_screen.dart';
import 'package:smart_cashier_app/module/sales/services/sales_services.dart';
import 'package:smart_cashier_app/module/sales/viewmodel/sales_view_model.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';

class CustomSidebarHome extends StatefulWidget {
  static const String routeName = 'custom-home';
  const CustomSidebarHome({super.key});

  @override
  State<CustomSidebarHome> createState() => _CustomSidebarHomeState();
}

class _CustomSidebarHomeState extends State<CustomSidebarHome> {
  int _page = 0;
  late List<Widget> _pages;
  final AuthServices _authServices = AuthServices();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pages = [
      const CashierScreen(),
      const ProdutcsScreen(),
      ChangeNotifierProvider(
        create: (_) => SalesViewModel(SalesServices()),
        child: const Sales(),
      ),
      ChangeNotifierProvider(
        create: (_) => ReportViewModel(
          ReportServices(),
          ProductServices(),
        ),
        child: const ReportScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // final bool isWideScreen = MediaQuery.of(context).size.width >= 700;
    final userName = context.watch<UserProvider>().user.name;
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: GlobalVariables.secondaryColor,
        backgroundColor: GlobalVariables.backgroundColor,
        title: Image.asset(
          'assets/smarttext.png',
          scale: 13,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TopInfoPanel(userName: userName),
          )
        ],
        centerTitle: true,
        toolbarHeight: 100,
      ),
      drawer: drawerContent(context),
      body: Row(
        children: [
          // if (isWideScreen)
          //   SizedBox(
          //     width: 250,
          //     child: drawerContent,
          //   ),
          Expanded(
            child: Builder(
              builder: (_) {
                try {
                  return IndexedStack(
                    index: _page,
                    children: _pages,
                  );
                } catch (e, st) {
                  debugPrint("Error di IndexedStack: $e\n$st");
                  return const Center(
                    child: Text(
                      'Terjadi error saat menampilkan halaman 😢',
                      style: TextStyle(color: Colors.red),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void Logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure want to logout ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authServices.logoutUser(context);
    }
  }

  Widget drawerContent(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/smartlogo.png',
                  scale: 25,
                ),
                SizedBox(
                  height: 10,
                ),
                Image.asset(
                  'assets/smarttext.png',
                  scale: 20,
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.point_of_sale, "Cashier", 0),
          _buildDrawerItem(Icons.inventory, "Product", 1),
          _buildDrawerItem(Icons.file_copy, "Purchased Note", 2),
          _buildDrawerItem(Icons.analytics, "Sales Report", 3),
          const Divider(),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: Logout,
          )
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index) {
    final bool selected = _page == index;
    return ListTile(
      leading: Icon(icon,
          color: selected ? GlobalVariables.thirdColor : Colors.grey[800]),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? GlobalVariables.thirdColor : Colors.grey[800],
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: selected,
      onTap: () {
        print('Navigating to page $index');
        setState(() {
          if (index == 1) {
            // Force Product tab to recreate so initState fetches latest stock.
            _pages[1] = ProdutcsScreen(key: UniqueKey());
          }
          _page = index;
        });
        if (MediaQuery.of(context).size.width < 700) {
          Navigator.of(context).pop();
        } // Menutup drawer di mobile
      },
    );
  }
}
