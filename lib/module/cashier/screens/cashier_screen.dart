import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/cart.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';
import 'package:smart_cashier_app/models/sales.dart' as sales_model;
import 'package:smart_cashier_app/models/user.dart';
import 'package:smart_cashier_app/module/cashier/services/cash_drawer_service.dart';
import 'package:smart_cashier_app/module/cashier/services/cashier_services.dart';
import 'package:collection/collection.dart';
import 'package:smart_cashier_app/providers/user_provider.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;

class CashierScreen extends StatefulWidget {
  final sales_model.Sales? editingSale;

  const CashierScreen({super.key, this.editingSale});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _exchangeController = TextEditingController();
  final CashierServices cashierServices = CashierServices();
  final CashDrawerService cashDrawerService = CashDrawerService();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _searchProductsController =
      TextEditingController();

  User? userProvider;

  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.total);
  double exchange = 0.0;
  String paymentMethod = 'cash'; // default
  String paymentStatus = 'paid'; // default
  double get totalProduct => cartItems.fold(0, (sum, item) => sum + item.qty);
  List<CartItem> cartItems = [];
  List<Product> searchItems = [];
  bool isInitializingEdit = false;

  bool get isEditMode => widget.editingSale != null;

  double _getTotalPayout() {
    return double.tryParse(_exchangeController.text.trim()) ?? 0.0;
  }

  Future<bool> createSales() async {
    final isSuccess = await cashierServices.createSales(
      context: context,
      cartItems: cartItems,
      totalPrice: totalPrice,
      totalPayout: _getTotalPayout(),
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      customerName: _customerNameController.text,
    );
    // await ReceiptPrinterService.printReceipt(
    //   cartItems: cartItems,
    //   totalPrice: totalPrice,
    //   paymentMethod: paymentMethod,
    //   customerName: _customerNameController.text,
    // );

    if (isSuccess && mounted) {
      setState(() {
        cartItems.clear();
        _exchangeController.clear();
        exchange = 0.0;
      });
    }
    return isSuccess;
  }

  Future<bool> updateSales() async {
    if (!isEditMode) return false;

    final isSuccess = await cashierServices.updateSales(
      context: context,
      id: widget.editingSale!.id,
      cartItems: cartItems,
      totalPrice: totalPrice,
      totalPayout: _getTotalPayout(),
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      customerName: _customerNameController.text,
    );

    if (isSuccess && mounted) {
      setState(() {
        cartItems.clear();
        _exchangeController.clear();
        exchange = 0.0;
      });
    }

    return isSuccess;
  }

  Future<void> initializeEditSale() async {
    if (!isEditMode) return;

    setState(() {
      isInitializingEdit = true;
    });

    final sale = widget.editingSale!;
    final productsRaw = await cashierServices.fetchAllProducts(context: context);
    final products = productsRaw.whereType<Product>().toList();
    final mappedCartItems = <CartItem>[];

    for (final item in sale.salesItems) {
      final product = products.firstWhereOrNull((p) => p.id == item.id_product);
      if (product == null) continue;

      final selectedUnit = product.units.firstWhereOrNull(
            (unit) => unit.id == item.id_product_unit,
          ) ??
          product.units.firstOrNull;
      if (selectedUnit == null) continue;

      mappedCartItems.add(
        CartItem(
          product: product,
          qty: item.quantity <= 0 ? 1 : item.quantity,
          selectedUnit: selectedUnit,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      cartItems = mappedCartItems;
      paymentMethod = sale.payment_method;
      paymentStatus = sale.payment_status;
      _customerNameController.text = sale.customer_name ?? '';
      _exchangeController.text = sale.total_payout.toString();
      exchange = sale.total_payout - sale.total_price;
      isInitializingEdit = false;
    });
  }

  getProductByBarcode(String barcode, {double qty = 1}) async {
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

  void _addCartItem(Product product, String barcode, {double qty = 1}) {
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

  Future<void> _tryOpenCashDrawerAfterPayment() async {
    final bool shouldOpenDrawer =
        paymentStatus == 'paid' && paymentMethod == 'cash';
    if (!shouldOpenDrawer) return;

    final result = await cashDrawerService.openDrawer();
    if (!result.isSuccess && mounted) {
      showSnackBar(
        context,
        "Payment saved, but failed to open cash drawer: ${result.message}",
        bgColor: Colors.orange,
      );
    }
  }

  void _showConfirmsPayDialog() async {
    bool isLoading = false;

    if (_exchangeController.text.isEmpty) {
      showSnackBar(context, "No Payment Amount!", bgColor: Colors.red);
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: GlobalVariables.backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Text(
              isEditMode ? "Confirm Update" : "Confirm Payment",
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
                        "Total Price: ${format.toRupiah(totalPrice)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Exchange: ${format.toRupiah(exchange)}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 20),

                      // Customer name
                      TextField(
                        controller: _customerNameController,
                        decoration: const InputDecoration(
                          labelText: "Customer Name (optional)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Payment method dropdown
                      DropdownButtonFormField<String>(
                        value: paymentMethod,
                        decoration: const InputDecoration(
                          labelText: "Payment Method",
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
                          labelText: "Payment Status",
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
                            child: const Text("Cancel"),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() => isLoading = true);
                              final isSuccess = isEditMode
                                  ? await updateSales()
                                  : await createSales();
                              if (!mounted) return;
                              if (isSuccess) {
                                await _tryOpenCashDrawerAfterPayment();
                              }
                              setState(() => isLoading = false);
                              Navigator.pop(context);
                              if (isSuccess && isEditMode && mounted) {
                                Navigator.pop(this.context, true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5)),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(isEditMode ? "Confirm Update" : "Confirm"),
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
      List<Product?> searchItems = await List.from(products);
      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: GlobalVariables.backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: 
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Select Product",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      TextField(
                        controller: _searchProductsController,
                        onChanged: (search) {
                          setStateDialog(() {
                            if (search.isEmpty) {
                              searchItems = List.from(products);
                            } else {
                              searchItems = products
                                  .where((item) => item!.productName
                                      .toLowerCase()
                                      .contains(search.toLowerCase()))
                                  .toList();
                            }
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: "Search Product",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
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
                                  child: 
                                  DataTable(
                                    headingRowColor: WidgetStateProperty.all(
                                        GlobalVariables.thirdColor),
                                    columns: const [
                                      DataColumn(label: Text("Barcode")),
                                      DataColumn(label: Text("Nama Barang")),
                                    ],
                                    rows: List.generate(searchItems.length,
                                        (index) {
                                      final product = searchItems[index];
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
                  );
                },
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
  void initState() {
    super.initState();
    if (isEditMode) {
      initializeEditSale();
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
    if (isInitializingEdit) {
      return const Scaffold(
        body: Center(child: CustomLoading()),
      );
    }

    userProvider = Provider.of<UserProvider>(context).user;
    bool isWideScreen = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: isEditMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text("Edit Sale"),
            )
          : null,
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          adaptiveFab(
            isWideScreen: isWideScreen,
            onPressed: _showProductsDialog,
            icon: Icons.add_shopping_cart_rounded,
            heroTag: 'cashier_add_product_fab',
          ),
          const SizedBox(width: 10),
          adaptiveFab(
            isWideScreen: isWideScreen,
            onPressed: () {},
            icon: Icons.qr_code,
            heroTag: 'cashier_qr_fab',
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _buildInputSection(context),
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
                  amount: format.toRupiah(totalPrice),
                ),
                const SizedBox(height: 18),
                CustomTextWidget(
                  title: "Exchange\n",
                  amount: format.toRupiah(exchange),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.black26),

          // ✅ BAGIAN KONTEN YANG BISA DISCROLL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildTableSection(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;
    return Material(
      elevation: 12,
      color: GlobalVariables.backgroundColor,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isWide ? 16 : 12,
          vertical: 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Input Item & Payment",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            if (isWide)
              Row(
                children: [
                  Expanded(
                    flex: 4,
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
                  SizedBox(
                    width: 110,
                    child: TextField(
                      controller: _qtyController,
                      onSubmitted: (_) {
                        final qty =
                            double.tryParse(_qtyController.text.trim()) ?? 1;
                        getProductByBarcode(_barcodeController.text, qty: qty);
                      },
                      decoration: const InputDecoration(
                        labelText: "Qty",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final qty =
                          double.tryParse(_qtyController.text.trim()) ?? 1;
                      getProductByBarcode(_barcodeController.text, qty: qty);
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text("Add"),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _exchangeController,
                      onChanged: (value) {
                        setState(() {
                          final payout = double.tryParse(value.trim()) ?? 0.0;
                          exchange = payout - totalPrice;
                        });
                      },
                      onSubmitted: (_) => _showConfirmsPayDialog(),
                      decoration: const InputDecoration(
                        labelText: "Pay Amount",
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showConfirmsPayDialog,
                    icon: const Icon(Icons.payment),
                    label: Text(isEditMode ? "Update Sale" : "Pay"),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  TextField(
                    controller: _barcodeController,
                    onSubmitted: (_) =>
                        getProductByBarcode(_barcodeController.text),
                    decoration: const InputDecoration(
                      labelText: "Scan / Input Barcode",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _qtyController,
                          onSubmitted: (_) {
                            final qty =
                                double.tryParse(_qtyController.text.trim()) ??
                                    1;
                            getProductByBarcode(_barcodeController.text,
                                qty: qty);
                          },
                          decoration: const InputDecoration(
                            labelText: "Qty",
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          final qty =
                              double.tryParse(_qtyController.text.trim()) ?? 1;
                          getProductByBarcode(_barcodeController.text,
                              qty: qty);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text("Add"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _exchangeController,
                    onChanged: (value) {
                      setState(() {
                        final payout = double.tryParse(value.trim()) ?? 0.0;
                        exchange = payout - totalPrice;
                      });
                    },
                    onSubmitted: (_) => _showConfirmsPayDialog(),
                    decoration: const InputDecoration(
                      labelText: "Pay Amount",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showConfirmsPayDialog,
                      icon: const Icon(Icons.payment),
                      label: Text(isEditMode ? "Update Sale" : "Pay"),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 46),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget adaptiveFab({
    required bool isWideScreen,
    required VoidCallback onPressed,
    required IconData icon,
    required String heroTag,
  }) {
    return FloatingActionButton(
      heroTag: heroTag,
      onPressed: onPressed,
      child: Icon(icon),
    );
  }

  Widget _buildTableSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child:
              Text("Cart Items", style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraint) {
            return Card(
              elevation: 3,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minWidth: constraint.maxWidth),
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
                                            text: format.formatDouble(item.qty),
                                          ),
                                          onSubmitted: (val) {
                                            setState(() {
                                              item.qty = double.tryParse(val) ?? 0;
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
                                    DataCell(Text(format.toRupiah(
                                        item.selectedUnit?.price ?? 0))),
                                    DataCell(
                                        Text(format.toRupiah(item.total))),
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
              ),
            );
          }
        ),
      ],
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

