import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/cashier/screens/cashier_screen.dart';
import 'package:smart_cashier_app/models/sales.dart' as sales_model;
import 'package:smart_cashier_app/module/sales/services/sales_services.dart';
import 'package:smart_cashier_app/module/sales/viewmodel/sales_view_model.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;
import 'package:provider/provider.dart';

class Sales extends StatefulWidget {
  static const String routeName = 'note-screen';
  const Sales({super.key});

  @override
  State<Sales> createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  final TextEditingController _searchNoteController = TextEditingController();
  // final SalesServices salesServices = SalesServices();

  Future<void> _confirmDeleteSales(sales_model.Sales sales) async {
    final vm = context.read<SalesVM>();
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Sales"),
        content: Text(
          "Delete sales note ${sales.customer_name}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              vm.deleteSales(context, sales.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showSalesDetailDialog(sales_model.Sales sales) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: GlobalVariables.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: SizedBox(
          // width: MediaQuery.of(context).size.width * 0.7,
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Sales Detail",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text('No. Nota: ${sales.id}'),
              Text(
                  'Date: ${context.read<SalesVM>().formatDate(sales.created_at)}'),
              Text(
                  'Customer: ${sales.customer_name?.isNotEmpty == true ? sales.customer_name : '-'}'),
              Text(
                  'Payment: ${sales.payment_method} (${sales.payment_status})'),
              Text('Total: ${format.toRupiah(sales.total_price)}'),
              const SizedBox(height: 12),
              const Divider(
                height: 2,
                color: Colors.transparent,
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      dataRowMinHeight: 48,
                      dataRowMaxHeight: double.infinity,
                      border: TableBorder(
                        borderRadius: BorderRadius.circular(3),
                        horizontalInside: BorderSide(color: Colors.black),
                        bottom: BorderSide(color: Colors.black),
                        left: BorderSide(color: Colors.black),
                        right: BorderSide(color: Colors.black),
                        top: BorderSide(color: Colors.black),
                      ),
                      columns: const [
                        DataColumn(label: Text("Product")),
                        DataColumn(label: Text("Qty")),
                        DataColumn(label: Text("Unit")),
                        DataColumn(label: Text("Price Unit")),
                        DataColumn(label: Text("Discount %")),
                        DataColumn(label: Text("Discount Amount")),
                        DataColumn(label: Text("Sub Total")),
                      ],
                      rows: List.generate(
                        sales.salesItems.isEmpty ? 1 : sales.salesItems.length,
                        (index) {
                          if (sales.salesItems.isEmpty) {
                            return const DataRow(
                              cells: [
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('No sale items')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                              ],
                            );
                          }

                          final item = sales.salesItems[index];
                          return DataRow(
                            cells: [
                              DataCell(Text(item.product_name ??
                                  'Product #${item.id_product}')),
                              DataCell(Text(context
                                  .read<SalesVM>()
                                  .formatQty(item.quantity))),
                              DataCell(Text(item.product_unit ??
                                  'Unit #${item.id_product_unit}')),
                              DataCell(Text(
                                  format.toRupiah(item.unit_price_snapshot))),
                              DataCell(Text(
                                  "${context.read<SalesVM>().formatQty(item.discount_percent)} %")),
                              DataCell(
                                  Text(format.toRupiah(item.discount_amount))),
                              DataCell(Text(format.toRupiah(item.sub_total))),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () {
        context.read<SalesVM>().fetchSales(context);
      },
    );
    // _fetchSales();
  }

  @override
  void dispose() {
    _searchNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<SalesVM>();
    double screenSizeWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenSizeWidth > 950;
    final filteredSales = vm.getFilteredSales();

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
                "List of Purchased Note",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: GlobalVariables.thirdColor,
                ),
              ),
              const SizedBox(
                height: 10,
              ),

              // Search Purchased Note
              _CustomTextfieldSalesScreen(context),
              const SizedBox(height: 10),

              // Filter
              _buildProductFilters(),
              const SizedBox(height: 10),

              Expanded(
                child: vm.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () => vm.fetchSales(context),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _buildSalesTable(filteredSales),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: non_constant_identifier_names
  TextField _CustomTextfieldSalesScreen(BuildContext context) {
    return TextField(
      controller: _searchNoteController,
      onChanged: (searchItem) =>
          context.read<SalesVM>().setFilterQuery(searchQueryValue: searchItem),
      decoration: const InputDecoration(
        labelText: "Search Note",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  Widget _buildProductFilters() {
    final vm = context.watch<SalesVM>();
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 250,
            child: DropdownButtonFormField<String>(
              value: vm.selectedSortFilter,
              decoration: const InputDecoration(
                labelText: "Sort By",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                    value: 'date_desc', child: Text("Date Newest")),
                DropdownMenuItem(value: 'date_asc', child: Text("Date Oldest")),
                DropdownMenuItem(
                    value: 'total_desc', child: Text("Total High-Low")),
                DropdownMenuItem(
                    value: 'total_asc', child: Text("Total Low-High")),
              ],
              onChanged: (value) {
                setState(() {
                  vm.selectedSortFilter = value ?? 'date_desc';
                });
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: vm.selectedPaymentStatusFilter,
              decoration: const InputDecoration(
                labelText: "Payment Status",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text("All Status")),
                DropdownMenuItem(value: 'paid', child: Text("Paid")),
                DropdownMenuItem(value: 'pending', child: Text("Pending")),
              ],
              onChanged: (value) {
                setState(() {
                  vm.selectedPaymentStatusFilter = value ?? 'all';
                });
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              context.read<SalesVM>().resetTableFilters();
              _searchNoteController.clear();
            },
            icon: const Icon(Icons.restart_alt),
            label: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTable(List<sales_model.Sales> list) {
    final vm = context.watch<SalesVM>();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                dataRowMinHeight: 48,
                dataRowMaxHeight: double.infinity,
                columns: const [
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Customer")),
                  DataColumn(label: Text("Payment")),
                  DataColumn(label: Text("Total")),
                  DataColumn(label: Text("Action")),
                ],
                rows: List.generate(
                  list.isEmpty ? 1 : list.length,
                  (index) {
                    if (list.isEmpty) {
                      return const DataRow(
                        cells: [
                          DataCell(Text('-')),
                          DataCell(Text('No sales found')),
                          DataCell(Text('-')),
                          DataCell(Text('-')),
                          DataCell(Text('-')),
                        ],
                      );
                    }

                    final sales = list[index];
                    return DataRow(
                      cells: [
                        DataCell(Text(vm.formatDate(sales.created_at))),
                        DataCell(Text((sales.customer_name == null ||
                                sales.customer_name!.isEmpty)
                            ? '-'
                            : sales.customer_name!)),
                        DataCell(
                          Badge(
                            backgroundColor: sales.payment_status == 'paid'
                                ? Colors.green
                                : Colors.red,
                            label: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(1.0, 1.0, 1.0, 3.5),
                              child: Text(
                                  '${sales.payment_method} (${sales.payment_status})'),
                            ),
                          ),
                        ),
                        DataCell(Text(format.toRupiah(sales.total_price))),
                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => _showSalesDetailDialog(sales),
                                icon: const Icon(Icons.visibility),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              IconButton(
                                onPressed: () async {
                                  final isUpdated = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => CashierScreen(
                                        editingSale: sales,
                                      ),
                                    ),
                                  );
                                  if (isUpdated == true && mounted) {
                                    context.read<SalesVM>().fetchSales(context);
                                    // _fetchSales();
                                  }
                                },
                                icon: const Icon(Icons.edit),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.yellow,
                                  foregroundColor: Colors.black,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 5),
                              IconButton(
                                onPressed: () => _confirmDeleteSales(sales),
                                icon: const Icon(Icons.delete_forever),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
