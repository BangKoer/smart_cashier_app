import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/models/cart.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';
import 'package:smart_cashier_app/module/cashier/services/cashier_services.dart';
import 'package:collection/collection.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final CashierServices cashierServices = CashierServices();
  double get totalPrice => cartItems.fold(0, (sum, item) => sum + item.total);
  int get totalProduct => cartItems.fold(0, (sum, item) => sum + item.qty);
  List<CartItem> cartItems = [];

  String toRupiah(dynamic amount) {
    final rupiahFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return rupiahFormatter.format(amount);
  }

  getProductByBarcode(String barcode) async {
    final existingItem = cartItems.firstWhereOrNull(
      (item) => item.product.barcode == barcode,
    );

    if (existingItem != null) {
      setState(() {
        existingItem.qty += 1;
        _barcodeController.clear();
        _qtyController.clear();
      });
      return;
    }

    Product? productFetch = await cashierServices.fetchProductByBarcode(
        context: context, barcode: barcode);
    if (productFetch != null) {
      setState(() {
        cartItems.add(
          CartItem(
            qty: _qtyController.text.isNotEmpty
                ? int.parse(_qtyController.text)
                : 1,
            product: productFetch,
            selectedUnit: productFetch.units.isNotEmpty
                ? productFetch.units.first
                : null,
          ),
        );
      });

      _barcodeController.clear();
      _qtyController.clear();
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ BAGIAN HEADER (STAY)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomTextWidget(
                  title: "Total Price\n",
                  amount: toRupiah(totalPrice),
                ),
                const SizedBox(height: 8),
                CustomTextWidget(
                  title: "Total Product\n",
                  amount: "$totalProduct products",
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
        Text("Input Barang", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _barcodeController,
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
              onPressed: () => getProductByBarcode(_barcodeController.text),
              child: const Text("Tambah"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(),
        Text("Total: Rp100.000",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.payment),
          label: const Text("Bayar"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      ],
    );
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
                                    border: InputBorder.none),
                                controller: TextEditingController(
                                  text: item.qty.toString(),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    item.qty = int.tryParse(val) ?? 1;
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
