import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/cashier/screens/cashier_screen.dart';
import 'package:smart_cashier_app/module/sales/screens/sales_screen.dart';
import 'package:smart_cashier_app/module/products/screens/produtcs_screen.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';

class CustomSidebarHome extends StatefulWidget {
  static const String routeName = 'custom-home';
  const CustomSidebarHome({super.key});

  @override
  State<CustomSidebarHome> createState() => _CustomSidebarHomeState();
}

class _CustomSidebarHomeState extends State<CustomSidebarHome> {
  int _page = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _pages = const [
      CashierScreen(),
      ProdutcsScreen(),
      Sales(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >= 700;

    Widget drawerContent = Drawer(
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
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        foregroundColor: GlobalVariables.secondaryColor,
        backgroundColor: GlobalVariables.backgroundColor,
        title: Image.asset(
          'assets/smarttext.png',
          scale: 13,
        ),
        centerTitle: true,
        toolbarHeight: 100,
      ),
      drawer: isWideScreen ? null : drawerContent,
      body: Row(
        children: [
          if (isWideScreen)
            SizedBox(
              width: 250,
              child: drawerContent,
            ),
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
          _page = index;
        });
        if (MediaQuery.of(context).size.width < 700) {
          Navigator.of(context).pop();
        } // Menutup drawer di mobile
      },
    );
  }
}
