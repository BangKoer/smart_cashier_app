import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/cart.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';
import 'package:smart_cashier_app/models/user.dart';
import 'package:smart_cashier_app/module/cashier/services/cashier_services.dart';
import 'package:collection/collection.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();
  final CashierServices cashierServices = CashierServices();
  final TextEditingController _customerNameController = TextEditingController();

  User? userProvider;

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.total);
  double exchange = 0.0;
  String paymentMethod = 'cash'; // default
  String paymentStatus = 'paid'; // default
  int get totalProduct => cartItems.fold(0, (sum, item) => sum + item.qty);
  List<CartItem> cartItems = [];

  String toRupiah(dynamic amount) {
    final rupiahFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return rupiahFormatter.format(amount);
  }

  createSales() async {
    await cashierServices.createSales(
      context: context,
      cartItems: cartItems,
      totalPrice: totalPrice,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      customerName: _customerNameController.text,
    );
    setState(() {
      cartItems.clear();
      _exchangeController.clear();
    });
  }

  getProductByBarcode(String barcode, {int qty = 1}) async {
    try {
      Product? productFetch = await cashierServices.fetchProductByBarcode(
          context: context, barcode: barcode);
      if (productFetch != null) {
        _addCartItem(productFetch, barcode, qty: qty);
      }
    } catch (e) {
      debugPrint('Error fetching product by barcode: $e');
    } finally {
      _barcodeController.clear();
      _qtyController.clear();
    }
  }

  void _addCartItem(Product product, String barcode, {int qty = 1}) {
    setState(
      () {
        final existingItem = cartItems.firstWhereOrNull(
          (item) => item.product.barcode == barcode,
        );

        if (existingItem != null) {
          existingItem.qty += qty;
        } else {
          cartItems.add(CartItem(
            product: product,
            qty: qty,
            selectedUnit: product.units.first,
          ));
        }
      },
    );
  }

  void _showConfirmsPayDialog() async {
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: GlobalVariables.backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              "Confirm Payment",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                if (isLoading) {
                  return SizedBox(
                    width: MediaQuery.of(context).size.width * 0.4,
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: const Center(
                      child: CustomLoading(), // widget loading kamu
                    ),
                  );
                }
                return Container(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Total Price: ${toRupiah(totalPrice)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Exchange: ${toRupiah(exchange)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 20),

                      // Customer name
                      TextField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: "Nama Customer (optional)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Payment method dropdown
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: const InputDecoration(
                          labelText: "Metode Pembayaran",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'qris', child: Text('QRIS')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            paymentMethod = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Payment status dropdown
                      DropdownButtonFormField<String>(
                        value: paymentStatus,
                        decoration: const InputDecoration(
                          labelText: "Status Pembayaran",
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'paid', child: Text('Paid')),
                          DropdownMenuItem(
                              value: 'pending', child: Text('Pending')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            paymentStatus = val!;
                          });
                        },
                      ),

                      const Spacer(),

                      // Confirm & Cancel Buttons
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
                              setState(() => isLoading = true);
                              await createSales();
                              setState(() => isLoading = false);
                              Navigator.pop(context); // tutup dialog dulu
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Konfirmasi"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ));
      },
    );
  }

  void _showProductsDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CustomLoading(),
    );

    try {
      List<Product?> products =
          await cashierServices.fetchAllProducts(context: context);
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: GlobalVariables.backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Select Product",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SizedBox(
                              width: constraints
                                  .maxWidth, // 💡 Biar tabel ikut selebar dialog
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(
                                    GlobalVariables.thirdColor),
                                columns: const [
                                  DataColumn(label: Text("Barcode")),
                                  DataColumn(label: Text("Nama Barang")),
                                ],
                                rows: List.generate(products.length, (index) {
                                  final product = products[index];
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        onTap: () {
                                          _addCartItem(
                                              product, product.barcode);
                                          Navigator.pop(context);
                                        },
                                        Text(product!.barcode),
                                      ),
                                      DataCell(
                                        onTap: () {
                                          _addCartItem(
                                              product, product.barcode);
                                          Navigator.pop(context);
                                        },
                                        Text(product.productName),
                                      ),
                                    ],
                                  );
                                }),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      showSnackBar(context, e.toString(), bgColor: Colors.red);
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _qtyController.dispose();
    _exchangeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    userProvider = Provider.of<UserProvider>(context).user;
    bool isWideScreen = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          adaptiveFab(
            isWideScreen: isWideScreen,
            onPressed: _showProductsDialog,
            icon: Icons.add_shopping_cart_rounded,
          ),
          const SizedBox(width: 10),
          adaptiveFab(
            isWideScreen: isWideScreen,
            onPressed: () {},
            icon: Icons.qr_code,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ BAGIAN HEADER (STAY)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  title: "Total Price\n",
                  amount: toRupiah(totalPrice),
                ),
                const SizedBox(height: 18),
                CustomTextWidget(
                  title: "Exchange\n",
                  amount: toRupiah(exchange),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.black26),

          // ✅ BAGIAN KONTEN YANG BISA DISCROLL
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 800;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: isWide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 2, child: _buildInputSection(context)),
                              const SizedBox(width: 24),
                              Expanded(
                                  flex: 3, child: _buildTableSection(context)),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputSection(context),
                              const SizedBox(height: 24),
                              _buildTableSection(context),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Input Item & Payment",
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _barcodeController,
                onSubmitted: (_) =>
                    getProductByBarcode(_barcodeController.text),
                decoration: const InputDecoration(
                  labelText: "Scan / Input Barcode",
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextField(
                controller: _qtyController,
                decoration: const InputDecoration(
                  labelText: "Qty",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => getProductByBarcode(_barcodeController.text,
                  qty: int.parse(_qtyController.text)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                foregroundColor: Colors.white,
              ),
              child: const Text("Add"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _exchangeController,
          onChanged: (value) {
            setState(() {
              exchange = -(totalPrice - double.parse(value));
            });
          },
          onSubmitted: (_) => getProductByBarcode(_barcodeController.text),
          decoration: const InputDecoration(
            labelText: "Pay Amount",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _showConfirmsPayDialog,
          icon: const Icon(Icons.payment),
          label: const Text("Pay"),
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Widget adaptiveFab({
    required bool isWideScreen,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return isWideScreen
        ? FloatingActionButton.large(onPressed: onPressed, child: Icon(icon))
        : FloatingActionButton(onPressed: onPressed, child: Icon(icon));
  }

  Widget _buildTableSection(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("No")),
                DataColumn(label: Text("Nama Barang")),
                DataColumn(label: Text("Qty")),
                DataColumn(label: Text("Satuan")),
                DataColumn(label: Text("Harga")),
                DataColumn(label: Text("Total")),
                DataColumn(label: Text("Delete Action")),
              ],
              rows: cartItems.isEmpty
                  ? [
                      const DataRow(cells: [
                        DataCell(Text('-')),
                        DataCell(Text('Belum ada data')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                        DataCell(Text('-')),
                      ]),
                    ]
                  : List.generate(
                      cartItems.length,
                      (index) {
                        final item = cartItems[index];
                        return DataRow(cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(item.product.productName)),
                          // Input qty
                          DataCell(
                            SizedBox(
                              width: 50,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                controller: TextEditingController(
                                  text: item.qty.toString(),
                                ),
                                onSubmitted: (val) {
                                  setState(() {
                                    item.qty = int.tryParse(val) ?? 0;
                                  });
                                },
                              ),
                            ),
                          ),
                          // 🧩 Dropdown satuan (ProductUnit)
                          DataCell(
                            DropdownButton<ProductUnit>(
                              value: item.selectedUnit,
                              items: item.product.units
                                  .map(
                                    (unit) => DropdownMenuItem(
                                      value: unit,
                                      child: Text(unit.nameUnit),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (unit) {
                                setState(() {
                                  item.selectedUnit = unit;
                                });
                              },
                            ),
                          ),
                          DataCell(
                              Text(toRupiah(item.selectedUnit?.price ?? 0))),
                          DataCell(Text(toRupiah(item.total))),
                          DataCell(
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    cartItems.removeAt(index);
                                  });
                                },
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                )),
                          ),
                        ]);
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextWidget extends StatelessWidget {
  final String title;
  final String amount;
  const CustomTextWidget({
    super.key,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: title,
        style: const TextStyle(
          fontSize: 22,
          color: GlobalVariables.secondaryColor,
          fontWeight: FontWeight.w900,
        ),
        children: [
          TextSpan(
            text: amount,
            style: const TextStyle(
              fontSize: 40,
              color: Colors.blue,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
