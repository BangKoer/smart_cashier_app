import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';

class ProdutcsScreen extends StatefulWidget {
  const ProdutcsScreen({super.key});

  @override
  State<ProdutcsScreen> createState() => _ProdutcsScreenState();
}

class _ProdutcsScreenState extends State<ProdutcsScreen> {
  final TextEditingController _searchProductController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    double screenSizeWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenSizeWidth > 800;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 50.0 : 12.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            const Text(
              "List of Products",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: GlobalVariables.thirdColor,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            // Add Product Elevated Button
            CustomButtonProductsScreen(
                isWideScreen: isWideScreen, screenSizeWidth: screenSizeWidth),
            const SizedBox(height: 10),

            // Textfield for search
            CustomTextFieldProductsScreen(
                searchProductController: _searchProductController),

            const SizedBox(height: 10),

            // Tabel products
            CustomTabelProductsScreen(isWideScreen: isWideScreen)
          ],
        ),
      ),
    );
  }
}

class CustomTabelProductsScreen extends StatelessWidget {
  const CustomTabelProductsScreen({
    super.key,
    required this.isWideScreen,
  });

  final bool isWideScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black),
      ),
      child: LayoutBuilder(builder: (context, constraint) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: isWideScreen ? constraint.maxWidth : null,
              child: DataTable(columns: const [
                DataColumn(label: Text("No")),
                DataColumn(label: Text("Nama Barang")),
                DataColumn(label: Text("Qty")),
                DataColumn(label: Text("Satuan")),
                DataColumn(label: Text("Harga")),
                DataColumn(label: Text("Total")),
                DataColumn(label: Text("Action")),
              ], rows: [
                const DataRow(cells: [
                  DataCell(Text('-')),
                  DataCell(Text('Belum ada data')),
                  DataCell(Text('-')),
                  DataCell(Text('-')),
                  DataCell(Text('-')),
                  DataCell(Text('-')),
                  DataCell(Text('-')),
                ]),
              ]),
            ),
          ),
        );
      }),
    );
  }
}

class CustomTextFieldProductsScreen extends StatelessWidget {
  const CustomTextFieldProductsScreen({
    super.key,
    required TextEditingController searchProductController,
  }) : _searchProductController = searchProductController;

  final TextEditingController _searchProductController;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchProductController,
      onChanged: (value) {},
      decoration: const InputDecoration(
        labelText: "Search Product",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}

class CustomButtonProductsScreen extends StatelessWidget {
  const CustomButtonProductsScreen({
    super.key,
    required this.isWideScreen,
    required this.screenSizeWidth,
  });

  final bool isWideScreen;
  final double screenSizeWidth;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        fixedSize: Size(
            isWideScreen ? screenSizeWidth * 0.2 : screenSizeWidth * 0.5, 40),
        backgroundColor: Colors.green,
      ),
      child: Row(
        children: [
          Icon(Icons.add),
          SizedBox(
            width: 5,
          ),
          Text("Add Product")
        ],
      ),
    );
  }
}
