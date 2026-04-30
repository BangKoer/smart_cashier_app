import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:smart_cashier_app/common/widgets/custom_loading.dart';
import 'package:smart_cashier_app/constant/global_variables.dart';
import 'package:smart_cashier_app/constant/utils.dart';
import 'package:smart_cashier_app/models/purchased_receipt.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';
import 'package:smart_cashier_app/models/supplier.dart';
import 'package:smart_cashier_app/module/report/screens/supplier_screen.dart';
import 'package:smart_cashier_app/module/report/services/report_services.dart';
import 'package:smart_cashier_app/module/products/services/products_services.dart';
import 'package:smart_cashier_app/module/report/viewmodel/report_view_model.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;

class ReportScreen extends StatefulWidget {
  static const String routeName = 'report-screen';
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportServices _reportServices = ReportServices();
  final ProductServices _productServices = ProductServices();

  // bool _isProductLoading = true;
  // String? _productError;
  // DateTime? _productFromDate;
  // DateTime? _productToDate;
  // String _productPaymentStatus = 'all';
  // // int _productLimit = 50;
  // int _productRowsPerPage = 10;
  // List<Map<String, dynamic>> _productSales = [];

  // bool _isReceiptLoading = true;
  // String? _receiptError;
  // List<PurchasedReceipt> _purchasedReceipts = [];

  // bool _isSupplierLoading = true;
  // String? _supplierError;
  // List<Supplier> _suppliers = [];

  // bool _isProductsLoading = true;
  // String? _productsError;
  // List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () {
        context.read<ReportViewModel>().loadKpiSummary(context);
        context.read<ReportViewModel>().loadCategorySales(context);
        context.read<ReportViewModel>().loadProductSales(context);
        context.read<ReportViewModel>().loadPurchasedReceipts(context);
        context.read<ReportViewModel>().loadSuppliers(context);
        context.read<ReportViewModel>().loadProducts(context);
      },
    );

    // _loadCategorySales();
    // _loadProductSales();
    // _loadPurchasedReceipts();
    // _loadSuppliers();
    // _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ReportViewModel>();
    final vmW = context.watch<ReportViewModel>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await vm.loadKpiSummary(context);
          await vm.loadCategorySales(context);
          await vm.loadProductSales(context);
          await vm.loadPurchasedReceipts(context);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          children: [
            const Text(
              "Sales Report",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: GlobalVariables.thirdColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildFilterSection(),
            const SizedBox(height: 16),
            if (vmW.isLoading)
              const SizedBox(
                height: 220,
                child: Center(
                  child: CustomLoading(),
                ),
              )
            else if (vmW.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  vmW.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiSection(), // ✅
                  const SizedBox(height: 20),
                  _buildSalesSeriesSection(), // ✅
                  const SizedBox(height: 20),
                  _buildCategoryAndProductRow(), // ✅
                  const SizedBox(height: 20),
                  _buildPurchasedReceiptsSection(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    var vm = context.read<ReportViewModel>();
    var vmW = context.watch<ReportViewModel>();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickFromDate,
              icon: const Icon(Icons.date_range),
              label: Text(vmW.fromDate == null
                  ? 'From Date'
                  : vm.formatDate(vmW.fromDate!)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
            OutlinedButton.icon(
              onPressed: _pickToDate,
              icon: const Icon(Icons.event),
              label: Text(
                  vmW.toDate == null ? 'To Date' : vm.formatDate(vmW.toDate!)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: vm.paymentStatus,
                decoration: const InputDecoration(
                  labelText: "Payment Status",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All')),
                  DropdownMenuItem(value: 'paid', child: Text('Paid')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                ],
                onChanged: (value) {
                  vm.setPaymentStatus(status: value!);
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                if (!vm.applyFilters()) {
                  showSnackBar(
                    context,
                    "From Date cannot be after To Date",
                    bgColor: Colors.red,
                  );
                } else {
                  await vm.loadKpiSummary(context);
                }
              },
              icon: const Icon(Icons.filter_alt),
              label: const Text("Apply"),
            ),
            OutlinedButton.icon(
              onPressed: () => vm.resetFilters(context),
              icon: const Icon(Icons.restart_alt),
              label: const Text("Reset"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromDate() async {
    final now = DateTime.now();
    final vm = context.read<ReportViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.fromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked == null) return;

    vm.setFromDate(picked);
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final vm = context.read<ReportViewModel>();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.toDate ?? vm.fromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked == null) return;
    vm.setToDate(picked);
  }

  // Future<void> _loadSuppliers() async {
  //   setState(() {
  //     _isSupplierLoading = true;
  //     _supplierError = null;
  //   });
  //   try {
  //     final data = await _reportServices.fetchSuppliers(context: context);
  //     if (!mounted) return;
  //     setState(() {
  //       _suppliers = data;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _supplierError = e.toString();
  //     });
  //   } finally {
  //     if (!mounted) return;
  //     setState(() {
  //       _isSupplierLoading = false;
  //     });
  //   }
  // }

  // Future<void> _loadProducts() async {
  //   setState(() {
  //     _isProductsLoading = true;
  //     _productsError = null;
  //   });
  //   try {
  //     final data = await _productServices.fetchAllProducts(context: context);
  //     if (!mounted) return;
  //     setState(() {
  //       _products = data;
  //     });
  //   } catch (e) {
  //     if (!mounted) return;
  //     setState(() {
  //       _productsError = e.toString();
  //     });
  //   } finally {
  //     if (!mounted) return;
  //     setState(() {
  //       _isProductsLoading = false;
  //     });
  //   }
  // }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Widget _buildKpiSection() {
    const spacing = 12.0;
    final vm = context.watch<ReportViewModel>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        if (isWide) {
          final cardWidth = (constraints.maxWidth - (spacing * 3)) / 4;
          return Row(
            children: [
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "Total Transaction",
                  value: (vm.kpi["total_transaction"] ?? 0).toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "Total Sales",
                  value: format.toRupiah(vm.kpi["total_sales"] ?? 0),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "Total Profit",
                  value: format.toRupiah(vm.kpi["total_profit"] ?? 0),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "ATV",
                  value: format.toRupiah(vm.kpi["avg_transaction_value"] ?? 0),
                  color: Colors.purple,
                ),
              ),
            ],
          );
        }

        return Wrap(
          spacing: spacing,
          // runSpacing: spacing,
          children: [
            _buildKpiCard(
              title: "Total Transaction",
              value: (vm.kpi["total_transaction"] ?? 0).toString(),
              color: Colors.blue,
            ),
            _buildKpiCard(
              title: "Total Sales",
              value: format.toRupiah(vm.kpi["total_sales"] ?? 0),
              color: Colors.green,
            ),
            _buildKpiCard(
              title: "Total Profit",
              value: format.toRupiah(vm.kpi["total_profit"] ?? 0),
              color: Colors.orange,
            ),
            _buildKpiCard(
              title: "ATV",
              value: format.toRupiah(vm.kpi["avg_transaction_value"] ?? 0),
              color: Colors.purple,
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return SizedBox(
      width: 250,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesSeriesSection() {
    var vmW = context.watch<ReportViewModel>();
    final pointsRaw = (vmW.series["points"] as List?) ?? const [];
    final points =
        pointsRaw.whereType<Map<String, dynamic>>().toList(growable: false);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sales Performance Over Time",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              "Grouping: ${(vmW.series["group_by"] ?? "day").toString()}",
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 14),
            if (points.isEmpty)
              const SizedBox(
                height: 220,
                child: Center(child: Text("No chart data for current filter")),
              )
            else
              SizedBox(
                height: 280,
                child: CustomPaint(
                  painter: _SalesLineChartPainter(points: points),
                  child: Container(),
                ),
              ),
            if (points.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                "Range: ${points.first["label"]} - ${points.last["label"]}",
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryAndProductRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;
        if (isWide) {
          return SizedBox(
            height: 560,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildCategorySalesCard(isTight: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildProductSalesCard(isTight: true)),
              ],
            ),
          );
        }
        return Column(
          children: [
            SizedBox(
              height: 520,
              child: _buildCategorySalesCard(isTight: true),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 520,
              child: _buildProductSalesCard(isTight: true),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategorySalesCard({required bool isTight}) {
    final vmW = context.watch<ReportViewModel>();
    final vm = context.read<ReportViewModel>();
    final fromText = vmW.categoryFromDate == null
        ? 'From'
        : _formatDate(vmW.categoryFromDate!);
    final toText = vmW.categoryFromDate == null
        ? 'To'
        : _formatDate(vmW.categoryFromDate!);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text(
              "Sales per Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OutlinedButton.icon(
                    icon: const Icon(Icons.date_range),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: _pickCategoryFromDate,
                    label: Text(fromText)),
                OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    onPressed: _pickCategoryToDate,
                    label: Text(toText)),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: vmW.categoryPaymentStatus,
                    decoration: const InputDecoration(
                      labelText: "Payment",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                    ],
                    onChanged: (val) {
                      vm.setCategoryPaymentStatus(status: val!);
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!vm.applyCategoryFilters()) {
                      showSnackBar(
                        context,
                        "From Date cannot be after To Date",
                        bgColor: Colors.red,
                      );
                    } else {
                      await vm.loadCategorySales(context);
                    }
                  },
                  child: const Text("Apply"),
                ),
                OutlinedButton(
                  onPressed: () => vm.resetCategoryFilters(context),
                  child: const Text("Reset"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isTight)
              Expanded(child: _buildCategoryChartBody())
            else
              SizedBox(
                height: 240,
                child: _buildCategoryChartBody(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSalesCard({required bool isTight}) {
    final vm = context.read<ReportViewModel>();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          children: [
            const Text(
              "Product Sales",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField(
                    value: vm.productSortBy,
                    decoration: const InputDecoration(
                      labelText: "Sort By",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'name_asc', child: Text("Name A-Z")),
                      DropdownMenuItem(
                          value: 'name_desc', child: Text("Name Z-A")),
                      DropdownMenuItem(
                          value: 'sales_desc', child: Text("Sales High-Low")),
                      DropdownMenuItem(
                          value: 'sales_asc', child: Text("Sales Low-High")),
                    ],
                    onChanged: (value) {
                      vm.setProductSortBy(sort: value!);
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: vm.productPaymentStatus,
                    decoration: const InputDecoration(
                      labelText: "Payment",
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'paid', child: Text('Paid')),
                      DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                    ],
                    onChanged: (val) =>
                        vm.setProductPaymentStatus(status: val!),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!vm.applyProductFilters()) {
                      showSnackBar(context, "From Date cannot be after To Date",
                          bgColor: Colors.red);
                      return;
                    } else {
                      await vm.loadProductSales(context);
                    }
                  },
                  child: const Text("Apply"),
                ),
                OutlinedButton(
                  onPressed: () => vm.resetProductFilters(context),
                  child: const Text("Reset"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isTight)
              Expanded(child: _buildProductTableBody())
            else
              SizedBox(
                height: 320,
                child: _buildProductTableBody(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChartBody() {
    final vmW = context.watch<ReportViewModel>();
    if (vmW.isCategoryLoading) {
      return const Center(child: CustomLoading());
    }
    if (vmW.categoryError != null) {
      return Center(
        child:
            Text(vmW.categoryError!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (vmW.categorySales.isEmpty) {
      return const Center(child: Text("No category data"));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CategoryBarChartPainter(data: vmW.categorySales),
        );
      },
    );
  }

  Widget _buildProductTableBody() {
    var vmW = context.watch<ReportViewModel>();
    var vm = context.read<ReportViewModel>();
    if (vmW.isProductLoading) {
      return const Center(child: CustomLoading());
    }
    if (vmW.productError != null) {
      return Center(
        child:
            Text(vmW.productError!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (vmW.productSales.isEmpty) {
      return const Center(child: Text("No product data"));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final nameColWidth =
            (constraints.maxWidth * 0.65).clamp(200, 600).toDouble();
        final salesColWidth =
            (constraints.maxWidth * 0.25).clamp(120, 220).toDouble();

        // Ensure the table fits within the available height to avoid overflow.
        const headingHeight = 40.0;
        const dataRowHeight = 40.0;
        const footerHeight = 56.0;
        final availableHeight =
            (constraints.maxHeight - headingHeight - footerHeight)
                .clamp(0, double.infinity);
        final maxRows =
            availableHeight > 0 ? (availableHeight / dataRowHeight).floor() : 1;
        final effectiveRowsPerPage =
            vmW.productRowsPerPage.clamp(1, maxRows == 0 ? 1 : maxRows);
        final availableRows = <int>{
          5,
          10,
          20,
          effectiveRowsPerPage,
        }.toList()
          ..sort();

        return PaginatedDataTable(
          showFirstLastButtons: true,
          showCheckboxColumn: false,
          columnSpacing: 16,
          horizontalMargin: 12,
          headingRowHeight: headingHeight,
          dataRowHeight: dataRowHeight,
          columns: [
            DataColumn(
              label: SizedBox(
                width: nameColWidth,
                child: const Text("Product Name"),
              ),
            ),
            DataColumn(
              numeric: true,
              label: SizedBox(
                width: salesColWidth,
                child: const Text("Total Sales"),
              ),
            ),
          ],
          source: _ProductSalesDataSource(
            vmW.productSales,
            nameColWidth: nameColWidth,
            salesColWidth: salesColWidth,
          ),
          rowsPerPage: effectiveRowsPerPage,
          availableRowsPerPage: availableRows,
          onRowsPerPageChanged: (value) {
            value != null ? vm.setProductRowPerPage(value) : null;
          },
        );
      },
    );
  }

  Future<void> _pickCategoryFromDate() async {
    final vm = context.read<ReportViewModel>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.categoryFromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null) return;
    vm.setCategoryFromDate(picked);
  }

  Future<void> _pickCategoryToDate() async {
    final vm = context.read<ReportViewModel>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.categoryToDate ?? vm.categoryFromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null) return;
    vm.setCategoryToDate(picked);
  }

  Widget _buildPurchasedReceiptsSection() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Invoice / Receipt Supplier",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: _showAddInvoiceDialog,
                    icon: const Icon(Icons.add),
                    label: const Text("Add Invoice"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_)=>ReportViewModel(ReportServices(), ProductServices()),
                              child: SupplierScreen(),
                            ),
                          ));
                    },
                    icon: const Icon(Icons.person),
                    label: const Text("Supplier"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlobalVariables.thirdColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildPurchasedReceiptsTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchasedReceiptsTable() {
    final vm = context.read<ReportViewModel>();
    final vmW = context.watch<ReportViewModel>();
    if (vmW.isReceiptLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CustomLoading()),
      );
    }
    if (vmW.receiptError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child:
            Text(vmW.receiptError!, style: const TextStyle(color: Colors.red)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraint) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: Colors.black),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraint.maxWidth),
                child: DataTable(
                  dataRowMinHeight: 48,
                  columns: const [
                    DataColumn(label: Text("No")),
                    DataColumn(label: Text("Receipt No")),
                    DataColumn(label: Text("Supplier")),
                    DataColumn(label: Text("Date")),
                    DataColumn(label: Text("Total Cost")),
                    DataColumn(label: Text("Note")),
                    DataColumn(label: Text("Action")),
                  ],
                  rows: List.generate(
                    vmW.purchasedReceipts.isEmpty
                        ? 1
                        : vmW.purchasedReceipts.length,
                    (index) {
                      if (vmW.purchasedReceipts.isEmpty) {
                        return const DataRow(
                          cells: [
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('No receipts found')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                            DataCell(Text('-')),
                          ],
                        );
                      }

                      final item = vmW.purchasedReceipts[index];
                      final supplierName =
                          item.supplier?.name.isNotEmpty == true
                              ? item.supplier!.name
                              : "-";
                      String dateText = item.receiptDate;
                      try {
                        dateText = DateFormat('dd-MMM-yyyy')
                            .format(DateTime.parse(item.receiptDate));
                      } catch (_) {}

                      return DataRow(
                        cells: [
                          DataCell(Text('${index + 1}')),
                          DataCell(Text(item.receiptNo.isNotEmpty
                              ? item.receiptNo
                              : "-")),
                          DataCell(Text(supplierName)),
                          DataCell(Text(dateText)),
                          DataCell(
                            Text(format.toRupiah(item.totalCost)),
                          ),
                          DataCell(Text(item.note?.toString() ?? "-")),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    await vm.loadDetailPurchasedReceipt(
                                        context, item.id);
                                    _showPurchasedReceiptDialog();
                                  },
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
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () {
                                    _handleUploadInvoice(item.id);
                                  },
                                  icon: const Icon(Icons.upload_file),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () async {
                                    await vm.loadDetailPurchasedReceipt(
                                        context, item.id);
                                    _updateInvoice();
                                  },
                                  icon: const Icon(Icons.edit),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.yellow,
                                    foregroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(5)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  onPressed: () {
                                    _deleteInvoice(item);
                                  },
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
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateInvoice() async {
    final vm = context.read<ReportViewModel>();
    vm.initEditingReceiptDateFromDetail();
    final receipt = vm.detail;
    final receiptNoCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    // DateTime? receiptDate;

    final qtyCtrls = <TextEditingController>[];
    final unitCtrls = <TextEditingController>[];

    if (!mounted) return;
    receiptNoCtrl.text = receipt!.receiptNo;
    noteCtrl.text = receipt.note ?? '';
    // receiptDate = DateTime.parse(vm.detail!.receiptDate);

    for (final item in receipt.items) {
      qtyCtrls.add(TextEditingController(text: item.qty.toString()));
      unitCtrls.add(TextEditingController(text: item.unitCost.toString()));
    }

    await showDialog<bool>(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: vm,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.all(20),
              backgroundColor: GlobalVariables.backgroundColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              title: const Text("Update Receipt"),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.7,
                child: vm.isDetailLoading
                    ? const Center(child: CustomLoading())
                    : vm.detailError != null
                        ? Center(
                            child: Text(vm.detailError!,
                                style: const TextStyle(color: Colors.red)))
                        : SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: receiptNoCtrl,
                                  decoration: const InputDecoration(
                                    labelText: "Receipt No",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    final picked = await showDatePicker(
                                        context: context,
                                        initialDate:
                                            vm.editingReceiptDate ?? now,
                                        firstDate: DateTime(2020, 1, 1),
                                        lastDate:
                                            DateTime(now.year + 5, 12, 31));
                                    if (picked != null) {
                                      vm.setEditingReceiptDate(picked);
                                    }
                                  },
                                  icon: const Icon(Icons.date_range),
                                  label: Consumer<ReportViewModel>(
                                    builder: (_, vmDate, __) => Text(
                                      vmDate.editingReceiptDate == null
                                          ? "Pick Date"
                                          : DateFormat('yyyy-MM-dd').format(
                                              vmDate.editingReceiptDate!,
                                            ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                TextField(
                                  controller: noteCtrl,
                                  maxLines: 2,
                                  decoration: const InputDecoration(
                                    labelText: "Note",
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Items",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: receipt.items.length,
                                  itemBuilder: (context, index) {
                                    final item = receipt.items[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Text(item.productName ??
                                                "Product ${item.idProduct}"),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: qtyCtrls[index],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: "Qty",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 8,
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: TextField(
                                              controller: unitCtrls[index],
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: "Unit Cost",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                          ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    final qtyList = qtyCtrls.map((e) => e.text).toList();
                    final unitList = unitCtrls.map((e) => e.text).toList();
                    final result = await vm.submitReceipt(
                      context,
                      receiptNoCtrl.text.trim(),
                      noteCtrl.text.trim(),
                      // receiptDate!,
                      qtyList,
                      unitList,
                    );
                    if (result == true) {
                      showSnackBar(
                        context,
                        "Successfully Edited Receipt Data",
                        bgColor: Colors.green,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 250));
    for (final controller in qtyCtrls) {
      controller.dispose();
    }
    for (final controller in unitCtrls) {
      controller.dispose();
    }
    receiptNoCtrl.dispose();
    noteCtrl.dispose();
    vm.clearEditingReceiptState();
  }

  Future<void> _handleUploadInvoice(int receiptId) async {
    final vm = context.read<ReportViewModel>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.single.path;
    if (filePath == null || filePath.isEmpty) {
      if (!mounted) return;
      showSnackBar(context, "Invalid file path", bgColor: Colors.red);
      return;
    }

    if (!mounted) return;
    showSnackBar(context, "Uploading invoice...", bgColor: Colors.black87);
    await vm.uploadFiles(context, receiptId, filePath);
    if (!mounted) return;
    showSnackBar(context, "Invoice uploaded", bgColor: Colors.green);
  }

  Future<void> _deleteInvoice(PurchasedReceipt receipt) async {
    final vm = context.read<ReportViewModel>();
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: GlobalVariables.backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          "Delete Invoice",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete receipt "${receipt.receiptNo.isNotEmpty ? receipt.receiptNo : receipt.id}" permanently?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final ok = await vm.deleteReceipt(
                context,
                receipt.id,
              );
              if (ok) {
                // await _loadPurchasedReceipts();
                await vm.loadPurchasedReceipts(context);
                showSnackBar(context, "Receipt deleted", bgColor: Colors.green);
              }
              Navigator.pop(context, true);
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

  Future<void> _showAddInvoiceDialog() async {
    final vm = context.read<ReportViewModel>();
    if (vm.isSupplierLoading || vm.isProductsLoading) {
      showSnackBar(context, "Loading data...", bgColor: Colors.black87);
      return;
    }
    if (vm.supplierError != null) {
      showSnackBar(context, vm.supplierError!, bgColor: Colors.red);
      return;
    }
    if (vm.productsError != null) {
      showSnackBar(context, vm.productsError!, bgColor: Colors.red);
      return;
    }

    var receiptNoCtrl = TextEditingController();
    var noteCtrl = TextEditingController();
    vm.prepareAddInvoiceDraft();

    await showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider.value(
        value: vm,
        child: Consumer<ReportViewModel>(
          builder: (context, vmW, _) => AlertDialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: GlobalVariables.backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: const Text("Add Invoice"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.7,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<Supplier>(
                      value: vmW.selectedSupplier,
                      decoration: const InputDecoration(
                        labelText: "Supplier",
                        border: OutlineInputBorder(),
                      ),
                      items: vmW.suppliers
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          vm.setSelectedSupplier(value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: receiptNoCtrl,
                      decoration: const InputDecoration(
                        labelText: "Receipt No",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: vmW.addInvoiceDate ?? now,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime(now.year + 5, 12, 31),
                        );
                        if (picked != null) {
                          vm.setReceiptDate(picked);
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        vmW.addInvoiceDate == null
                            ? "Pick Date"
                            : DateFormat('yyyy-MM-dd')
                                .format(vmW.addInvoiceDate!),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: "Note",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Items",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: vmW.items.length,
                      itemBuilder: (context, index) {
                        final item = vmW.items[index];
                        final units = vmW.unitsForProduct(item.productId);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: DropdownButtonFormField<int>(
                                      value: item.productId,
                                      decoration: const InputDecoration(
                                        labelText: "Product",
                                        border: OutlineInputBorder(),
                                      ),
                                      items: vmW.products
                                          .map(
                                            (p) => DropdownMenuItem(
                                              value: p.id,
                                              child: Text(p.productName),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) =>
                                          vm.setProductForItem(index, value),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: DropdownButtonFormField<int>(
                                      value: item.unitId,
                                      decoration: const InputDecoration(
                                        labelText: "Unit",
                                        border: OutlineInputBorder(),
                                      ),
                                      items: units
                                          .map(
                                            (u) => DropdownMenuItem(
                                              value: u.id,
                                              child: Text(u.nameUnit),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) =>
                                          vm.setUnitForItem(index, value),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => vm.removeItem(index),
                                    icon: const Icon(Icons.remove_circle),
                                    color: Colors.red,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: item.qtyCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: "Qty",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: item.unitCostCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: "Unit Cost",
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: vm.addItem,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Item"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context, false);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final ok = await vm.submitProduct(
                    context,
                    receiptNoCtrl.text,
                    noteCtrl.text,
                  );
                  if (!mounted) return;
                  if (ok) {
                    showSnackBar(
                      context,
                      "Receipt created",
                      bgColor: Colors.green,
                    );
                    Navigator.pop(context, true);
                  } else {
                    showSnackBar(
                      context,
                      "Failed to create receipt. Check supplier/date/items.",
                      bgColor: Colors.red,
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 350));
    vm.clearAddInvoiceDraft();
    receiptNoCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<void> _showPurchasedReceiptDialog() async {
    final vm = context.read<ReportViewModel>();
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: GlobalVariables.backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text(
              "Invoice / Receipt Supplier",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.7,
              child: vm.isDetailLoading
                  ? const Center(child: CustomLoading())
                  : vm.detailError != null
                      ? Center(
                          child: Text(
                            vm.detailError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : vm.detail == null
                          ? const Center(child: Text("No detail found"))
                          : _buildReceiptDetailBody(vm.detail!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          );
        });
  }

  Widget _buildReceiptDetailBody(PurchasedReceipt receipt) {
    final supplierName = receipt.supplier?.name.isNotEmpty == true
        ? receipt.supplier!.name
        : "-";
    String dateText = receipt.receiptDate;
    try {
      dateText = DateFormat('dd-MMM-yyyy').format(
        DateTime.parse(receipt.receiptDate),
      );
    } catch (_) {}

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _detailChip("Receipt No", receipt.receiptNo),
                  _detailChip("Supplier", supplierName),
                  _detailChip("Date", dateText),
                  _detailChip("Total", format.toRupiah(receipt.totalCost)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Note: ${receipt.note ?? "-"}",
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 16),
              const Text(
                "Items",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: receipt.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = receipt.items[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      item.productName?.isNotEmpty == true
                          ? item.productName!
                          : "Product ID: ${item.idProduct}",
                    ),
                    subtitle:
                        Text("Qty: ${item.qty}  |  Unit: ${item.unitCost}"),
                    trailing: Text(format.toRupiah(item.subTotal)),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Text(
                "Files",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (receipt.files.isEmpty)
                const Text("No files uploaded")
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = (constraints.maxWidth * 0.45)
                        .clamp(160, 320)
                        .toDouble();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: receipt.files.map((f) {
                        final imageUrl = '$baseUrl${f.filePath}';
                        return InkWell(
                          onTap: () =>
                              _showInvoiceImageDialog(imageUrl, f.fileName),
                          child: Container(
                            width: itemWidth,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(8),
                                  ),
                                  child: Image.network(
                                    imageUrl,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stack) =>
                                        Container(
                                      height: 140,
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Text("Image not available"),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    f.fileName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showInvoiceImageDialog(String imageUrl, String title) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => const SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      "Image not available",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Text(
                title,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade200,
      ),
      child: Text(
        "$label: $value",
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

class _SalesLineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> points;

  _SalesLineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    const chartLeft = 52.0;
    const chartRightPadding = 16.0;
    const chartTop = 28.0;
    const chartBottomPadding = 36.0;

    final chartRight = size.width - chartRightPadding;
    final chartBottom = size.height - chartBottomPadding;
    final chartWidth = chartRight - chartLeft;
    final chartHeight = chartBottom - chartTop;

    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    final gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;

    final lineColor = GlobalVariables.thirdColor;
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    // Legend
    canvas.drawLine(const Offset(14, 10), const Offset(36, 10), linePaint);
    _drawText(
      canvas,
      "total_sales",
      const Offset(42, 2),
      const TextStyle(
        color: Colors.black87,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );

    final salesValues = points
        .map((e) => (e["total_sales"] as num?)?.toDouble() ?? 0.0)
        .toList(growable: false);
    double minValue = salesValues.reduce((a, b) => a < b ? a : b);
    double maxValue = salesValues.reduce((a, b) => a > b ? a : b);
    minValue = 0;
    if (minValue == maxValue) {
      maxValue = maxValue + 1;
    }

    // Grid
    const yGridCount = 5;
    final xGridCount =
        points.length <= 1 ? 1 : (points.length - 1).clamp(1, 20);
    for (int i = 0; i <= xGridCount; i++) {
      final x = chartLeft + (i / xGridCount) * chartWidth;
      canvas.drawLine(Offset(x, chartTop), Offset(x, chartBottom), gridPaint);
    }

    for (int i = 0; i <= yGridCount; i++) {
      final ratio = i / yGridCount;
      final y = chartBottom - (ratio * chartHeight);
      canvas.drawLine(Offset(chartLeft, y), Offset(chartRight, y), gridPaint);

      final axisValue = minValue + ((maxValue - minValue) * ratio);
      _drawText(
        canvas,
        _formatCompact(axisValue),
        Offset(4, y - 7),
        const TextStyle(color: Colors.black54, fontSize: 10),
      );
    }

    canvas.drawLine(Offset(chartLeft, chartBottom),
        Offset(chartRight, chartBottom), axisPaint);
    canvas.drawLine(
        Offset(chartLeft, chartTop), Offset(chartLeft, chartBottom), axisPaint);

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final x = chartLeft +
          (points.length == 1
              ? chartWidth / 2
              : (i / (points.length - 1)) * chartWidth);
      final value = (points[i]["total_sales"] as num?)?.toDouble() ?? 0.0;
      final y = chartBottom -
          ((value - minValue) / (maxValue - minValue)) * chartHeight;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    for (int i = 0; i < points.length; i++) {
      final x = chartLeft +
          (points.length == 1
              ? chartWidth / 2
              : (i / (points.length - 1)) * chartWidth);
      final value = (points[i]["total_sales"] as num?)?.toDouble() ?? 0.0;
      final y = chartBottom -
          ((value - minValue) / (maxValue - minValue)) * chartHeight;
      canvas.drawCircle(Offset(x, y), 2.2, dotPaint);
    }

    final maxLabels = 8;
    final step =
        points.length <= maxLabels ? 1 : (points.length / maxLabels).ceil();
    for (int i = 0; i < points.length; i += step) {
      final x = chartLeft +
          (points.length == 1
              ? chartWidth / 2
              : (i / (points.length - 1)) * chartWidth);
      final rawLabel = points[i]["label"]?.toString() ?? "";
      final shortLabel = _gridDateLabel(rawLabel);
      _drawText(
        canvas,
        shortLabel,
        Offset(x - 16, chartBottom + 6),
        const TextStyle(color: Colors.black54, fontSize: 10),
      );
    }
  }

  String _gridDateLabel(String raw) {
    try {
      DateTime parsed;
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(raw)) {
        // Month group format from backend: YYYY-MM
        parsed = DateTime.parse('$raw-01');
      } else {
        // Day/week formats from backend: YYYY-MM-DD
        parsed = DateTime.parse(raw);
      }
      return DateFormat('dd-MMM-yyyy').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  String _formatCompact(double value) {
    if (value >= 1000000000)
      return '${(value / 1000000000).toStringAsFixed(1)}B';
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _SalesLineChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _CategoryBarChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  _CategoryBarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 44.0;
    const rightPadding = 12.0;
    const topPadding = 24.0;
    const bottomPadding = 30.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final values = data
        .map((e) => (e["total_sales"] as num?)?.toDouble() ?? 0.0)
        .toList(growable: false);
    double maxValue =
        values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) maxValue = 1;

    final gridPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;

    // Legend
    final legendPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawRect(const Rect.fromLTWH(10, 6, 18, 10), legendPaint);
    _drawText(
      canvas,
      "sales",
      const Offset(34, 2),
      const TextStyle(fontSize: 12, color: Colors.black87),
    );

    // Y grid + labels
    const yGridCount = 5;
    for (int i = 0; i <= yGridCount; i++) {
      final ratio = i / yGridCount;
      final y = topPadding + (1 - ratio) * chartHeight;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(leftPadding + chartWidth, y),
        gridPaint,
      );

      final axisValue = maxValue * ratio;
      _drawText(
        canvas,
        _formatCompact(axisValue),
        Offset(4, y - 7),
        const TextStyle(fontSize: 10, color: Colors.black54),
      );
    }

    // Axes
    canvas.drawLine(
      Offset(leftPadding, topPadding),
      Offset(leftPadding, topPadding + chartHeight),
      axisPaint,
    );
    canvas.drawLine(
      Offset(leftPadding, topPadding + chartHeight),
      Offset(leftPadding + chartWidth, topPadding + chartHeight),
      axisPaint,
    );

    final barWidth = chartWidth / (data.length * 1.4);
    final barPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final value = (data[i]["total_sales"] as num?)?.toDouble() ?? 0.0;
      final barHeight = (value / maxValue) * chartHeight;
      final x = leftPadding + i * (barWidth * 1.4);
      final y = topPadding + (chartHeight - barHeight);
      canvas.drawRect(Rect.fromLTWH(x, y, barWidth, barHeight), barPaint);

      final label = data[i]["category_name"]?.toString() ?? "";
      _drawText(
        canvas,
        label,
        Offset(x, topPadding + chartHeight + 6),
        const TextStyle(fontSize: 10, color: Colors.black87),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryBarChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: ui.TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: 80);
    painter.paint(canvas, offset);
  }
}

class _ProductSalesDataSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final double nameColWidth;
  final double salesColWidth;
  _ProductSalesDataSource(
    this.data, {
    required this.nameColWidth,
    required this.salesColWidth,
  });

  @override
  DataRow? getRow(int index) {
    if (index < 0 || index >= data.length) return null;
    final row = data[index];
    return DataRow.byIndex(
      index: index,
      cells: [
        DataCell(
          SizedBox(
            width: nameColWidth,
            child: Text(
              row["product_name"]?.toString() ?? "-",
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(
          SizedBox(
            width: salesColWidth,
            child: Text(
              format.toRupiah(row["total_sales"] ?? 0),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => data.length;

  @override
  int get selectedRowCount => 0;
}
