import 'package:flutter/material.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/module/cashier/screens/cashier_screen.dart';
import 'package:smart_cashier_app/models/sales.dart' as sales_model;
import 'package:smart_cashier_app/module/sales/services/sales_services.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;

class Sales extends StatefulWidget {
  static const String routeName = 'note-screen';
  const Sales({super.key});

  @override
  State<Sales> createState() => _SalesState();
}

class _SalesState extends State<Sales> {
  final TextEditingController _searchNoteController = TextEditingController();
  final SalesServices salesServices = SalesServices();
  List<sales_model.Sales> salesList = [];
  bool isLoading = true;
  String _searchQuery = '';
  String _selectedSortFilter = 'date_desc';
  String _selectedPaymentStatusFilter = 'all';

  Future<void> _fetchSales() async {
    setState(() => isLoading = true);
    salesList = await salesServices.fetchAllSales(context: context);
    if (!mounted) return;
    setState(() => isLoading = false);
  }

  List<sales_model.Sales> _getFilteredSales() {
    final filtered = salesList.where((sales) {
      final matchPaymentStatus = _selectedPaymentStatusFilter == 'all' ||
          sales.payment_status == _selectedPaymentStatusFilter;
      if (!matchPaymentStatus) return false;

      if (_searchQuery.isEmpty) return true;

      final search = _searchQuery.toLowerCase();
      final byId = sales.id.toString().contains(search);
      final byCustomer =
          (sales.customer_name ?? '').toLowerCase().contains(search);
      final byPayment = sales.payment_method.toLowerCase().contains(search) ||
          sales.payment_status.toLowerCase().contains(search);
      final byItem = sales.salesItems.any((item) {
        final product = (item.product_name ?? '').toLowerCase();
        final unit = (item.product_unit ?? '').toLowerCase();
        return product.contains(search) || unit.contains(search);
      });

      return byId || byCustomer || byPayment || byItem;
    }).toList();

    switch (_selectedSortFilter) {
      case 'date_asc':
        filtered.sort(
            (a, b) => _toDate(a.created_at).compareTo(_toDate(b.created_at)));
        break;
      case 'total_asc':
        filtered.sort((a, b) => a.total_price.compareTo(b.total_price));
        break;
      case 'total_desc':
        filtered.sort((a, b) => b.total_price.compareTo(a.total_price));
        break;
      default:
        filtered.sort(
            (a, b) => _toDate(b.created_at).compareTo(_toDate(a.created_at)));
    }

    return filtered;
  }

  DateTime _toDate(String input) => DateTime.tryParse(input) ?? DateTime(1970);

  String _formatDate(String input) {
    final dt = _toDate(input);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  void _resetTableFilters() {
    setState(() {
      _selectedSortFilter = 'date_desc';
      _selectedPaymentStatusFilter = 'all';
      _searchQuery = '';
      _searchNoteController.clear();
    });
  }

  String _formatQty(double qty) {
    if (qty == qty.toInt()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }

  Future<void> _confirmDeleteSales(sales_model.Sales sales) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Sales"),
        content: Text(
          "Delete sales note #${sales.id}? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    final isDeleted = await salesServices.deleteSales(
      context: context,
      id: sales.id,
    );
    if (isDeleted && mounted) {
      _fetchSales();
    }
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
              Text('Date: ${_formatDate(sales.created_at)}'),
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
                        DataColumn(label: Text("Unit")),
                        DataColumn(label: Text("Qty")),
                        DataColumn(label: Text("Unit Price")),
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
                              ],
                            );
                          }

                          final item = sales.salesItems[index];
                          return DataRow(
                            cells: [
                              DataCell(Text(item.product_name ??
                                  'Product #${item.id_product}')),
                              DataCell(Text(item.product_unit ??
                                  'Unit #${item.id_product_unit}')),
                              DataCell(Text(_formatQty(item.quantity))),
                              DataCell(
                                  Text(format.toRupiah(item.unit_price ?? 0))),
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
    _fetchSales();
  }

  @override
  void dispose() {
    _searchNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenSizeWidth = MediaQuery.of(context).size.width;
    bool isWideScreen = screenSizeWidth > 950;
    final filteredSales = _getFilteredSales();

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
              _CustomTextfieldSalesScreen(),
              const SizedBox(height: 10),

              // Filter
              _buildProductFilters(),
              const SizedBox(height: 10),

              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _fetchSales,
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
  TextField _CustomTextfieldSalesScreen() {
    return TextField(
      controller: _searchNoteController,
      onChanged: (searchItem) {
        _searchQuery = searchItem.trim();
        setState(() {});
      },
      decoration: const InputDecoration(
        labelText: "Search Note",
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
    );
  }

  Widget _buildProductFilters() {
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
              value: _selectedSortFilter,
              decoration: const InputDecoration(
                labelText: "Sort By",
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(value: 'date_desc', child: Text("Date Newest")),
                DropdownMenuItem(value: 'date_asc', child: Text("Date Oldest")),
                DropdownMenuItem(
                    value: 'total_desc', child: Text("Total High-Low")),
                DropdownMenuItem(
                    value: 'total_asc', child: Text("Total Low-High")),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSortFilter = value ?? 'date_desc';
                });
              },
            ),
          ),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<String>(
              value: _selectedPaymentStatusFilter,
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
                  _selectedPaymentStatusFilter = value ?? 'all';
                });
              },
            ),
          ),
          OutlinedButton.icon(
            onPressed: _resetTableFilters,
            icon: const Icon(Icons.restart_alt),
            label: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesTable(List<sales_model.Sales> list) {
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
                  DataColumn(label: Text("No")),
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
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(_formatDate(sales.created_at))),
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
                                _fetchSales();
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
