import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';
import 'package:smart_cashier_app/module/products/services/products_services.dart';

class ProdutcsScreen extends StatefulWidget {
  const ProdutcsScreen({super.key});

  @override
  State<ProdutcsScreen> createState() => _ProdutcsScreenState();
}

class _ProdutcsScreenState extends State<ProdutcsScreen> {
  final TextEditingController _searchProductController =
      TextEditingController();
  final ProductServices productServices = ProductServices();
  List<Product> searchProduct = [];

  getAllProduct() async {
    searchProduct = await productServices.fetchAllProducts(context: context);
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    getAllProduct();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenSizeWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenSizeWidth > 950;
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: isWideScreen ? 50.0 : 12.0, vertical: 10),
        child: Container(
          height: MediaQuery.of(context).size.height,
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
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: CustomTabelProductsScreen(
                    isWideScreen: isWideScreen,
                    searchProduct: searchProduct,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class CustomTabelProductsScreen extends StatefulWidget {
  const CustomTabelProductsScreen({
    super.key,
    required this.isWideScreen,
    required this.searchProduct,
  });

  final bool isWideScreen;
  final List<Product> searchProduct;

  @override
  State<CustomTabelProductsScreen> createState() =>
      _CustomTabelProductsScreenState();
}

class _CustomTabelProductsScreenState extends State<CustomTabelProductsScreen> {
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
            child: DataTable(
                dataRowMinHeight: 48,
                columns: const [
                  DataColumn(label: Text("No")),
                  DataColumn(label: Text("Barcode")),
                  DataColumn(
                      label: Text("Nama Barang",
                          overflow: TextOverflow.ellipsis, maxLines: 1)),
                  DataColumn(label: Text("Kategori")),
                  DataColumn(label: Text("Stock")),
                  DataColumn(label: Text("Satuan")),
                  DataColumn(label: Text("Harga Satuan")),
                  DataColumn(
                      label: Text("Harga Pembelian Dari Seller",
                          overflow: TextOverflow.ellipsis)),
                  DataColumn(label: Text("Action")),
                ],
                rows: widget.searchProduct.isEmpty
                    ? [
                        const DataRow(
                          cells: [
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                          ],
                        ),
                      ]
                    : List.generate(
                        widget.searchProduct.length,
                        (index) {
                          final item = widget.searchProduct[index];
                          return DataRow(
                            cells: [
                              DataCell(Text('${item.id}')),
                              DataCell(Text('${item.barcode}')),
                              DataCell(Text('${item.productName}')),
                              DataCell(Text('${item.category.name}')),
                              DataCell(Text('${item.stock}')),
                              DataCell(SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: [
                                    Text(item.units
                                        .map((unit) => unit.nameUnit)
                                        .join('\n')),
                                  ],
                                ),
                              )),
                              DataCell(SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  children: [
                                    Text(item.units
                                        .map((unit) => unit.price)
                                        .join('\n')),
                                  ],
                                ),
                              )),
                              DataCell(Text('${item.purchasedPrice}')),
                              DataCell(Row(
                                children: [
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.edit),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.yellow,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.delete_forever),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(5)),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                            ],
                          );
                        },
                      )),
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
