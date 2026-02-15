import 'package:flutter/material.dart';
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/module/products/services/products_services.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;

class ProdutcsScreen extends StatefulWidget {
  const ProdutcsScreen({super.key});

  @override
  State<ProdutcsScreen> createState() => _ProdutcsScreenState();
}

class _ProdutcsScreenState extends State<ProdutcsScreen> {
  final TextEditingController _searchProductController =
      TextEditingController();
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _purchasedPriceController =
      TextEditingController();
  final ProductServices productServices = ProductServices();
  List<Product> products = [];
  List<Product?> searchProducts = [];

  getAllProduct() async {
    products = await productServices.fetchAllProducts(context: context);
    setState(() {});
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: GlobalVariables.backgroundColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // tutup dialog dulu
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add"),
                ),
              ],
            ),
          ],
          content: Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: MediaQuery.of(context).size.height * 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Add Product",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 10,
                ),
                Form(
                  child: Column(
                    children: [
                      TextField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: "Barcode",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.line_style_rounded),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: _productNameController,
                        decoration: const InputDecoration(
                          labelText: "Name",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.abc_rounded),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Stock",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.add_shopping_cart_rounded),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: _purchasedPriceController,
                        decoration: const InputDecoration(
                          labelText: "Purchased Price",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.money),
                        ),
                      ),
                      Row()
                    ],
                  ),
                )
              ],
            ),
          )),
    );
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
              const SizedBox(
                height: 10,
              ),

              // Add Product Elevated Button
              CustomButtonProductScreen(isWideScreen, screenSizeWidth),

              const SizedBox(height: 10),

              // Textfield for search
              CustomTextfieldProductScreen(),

              const SizedBox(height: 10),

              // Tabel products
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: CustomTabelProductsScreen(
                    isWideScreen: isWideScreen,
                    searchProduct:
                        searchProducts.isEmpty ? products : searchProducts,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  ElevatedButton CustomButtonProductScreen(
      bool isWideScreen, double screenSizeWidth) {
    return ElevatedButton(
      onPressed: _showAddProductDialog,
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        fixedSize: Size(
            isWideScreen ? screenSizeWidth * 0.2 : screenSizeWidth * 0.5, 40),
        backgroundColor: Colors.green,
      ),
      child: const Row(
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

  TextField CustomTextfieldProductScreen() {
    return TextField(
      controller: _searchProductController,
      onChanged: (searchItem) {
        if (searchItem.isNotEmpty) {
          searchProducts = products
              .where((item) => item.productName
                  .toLowerCase()
                  .contains(searchItem.toLowerCase()))
              .toList();
          setState(() {});
        }
      },
      decoration: const InputDecoration(
        labelText: "Search Product",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
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
  final List<Product?> searchProduct;

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
                rows: List.generate(
                  widget.searchProduct.length,
                  (index) {
                    final item = widget.searchProduct[index];
                    return DataRow(
                      cells: [
                        DataCell(Text('${item!.id}')),
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
                                  .map((unit) => format.toRupiah(unit.price))
                                  .join('\n')),
                            ],
                          ),
                        )),
                        DataCell(Text(format.toRupiah(item.purchasedPrice))),
                        DataCell(Row(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.edit),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                shape: const RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
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
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)),
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
