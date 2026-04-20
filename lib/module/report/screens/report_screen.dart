import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
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

  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _paymentStatus = 'all';
  String _productSortBy = 'sales_desc';

  Map<String, dynamic> _kpi = {
    "total_transaction": 0,
    "total_sales": 0.0,
    "total_profit": 0.0,
    "avg_transaction_value": 0.0,
  };
  Map<String, dynamic> _series = {
    "group_by": "day",
    "points": <Map<String, dynamic>>[],
  };
  bool _isCategoryLoading = true;
  String? _categoryError;
  DateTime? _categoryFromDate;
  DateTime? _categoryToDate;
  String _categoryPaymentStatus = 'all';
  List<Map<String, dynamic>> _categorySales = [];

  bool _isProductLoading = true;
  String? _productError;
  DateTime? _productFromDate;
  DateTime? _productToDate;
  String _productPaymentStatus = 'all';
  // int _productLimit = 50;
  int _productRowsPerPage = 10;
  List<Map<String, dynamic>> _productSales = [];

  bool _isReceiptLoading = true;
  String? _receiptError;
  List<PurchasedReceipt> _purchasedReceipts = [];

  bool _isSupplierLoading = true;
  String? _supplierError;
  List<Supplier> _suppliers = [];

  bool _isProductsLoading = true;
  String? _productsError;
  List<Product> _products = [];

  Future<void> _loadKpiSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filtersPayment = _paymentStatus == 'all' ? null : _paymentStatus;
      final data = await _reportServices.fetchKpiSummary(
          context: context,
          dateFrom: _fromDate,
          dateTo: _toDate,
          paymentStatus: filtersPayment);
      final series = await _reportServices.fetchSalesSeries(
        context: context,
        dateFrom: _fromDate,
        dateTo: _toDate,
        paymentStatus: filtersPayment,
      );
      if (!mounted) return;
      setState(() {
        _kpi = data;
        _series = series;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadKpiSummary();
    _loadCategorySales();
    _loadProductSales();
    _loadPurchasedReceipts();
    _loadSuppliers();
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadKpiSummary,
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
            if (_isLoading)
              const SizedBox(
                height: 220,
                child: Center(
                  child: CustomLoading(),
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiSection(),
                  const SizedBox(height: 20),
                  _buildSalesSeriesSection(),
                  const SizedBox(height: 20),
                  _buildCategoryAndProductRow(),
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
    final DateTime? localFromDate = _fromDate;
    final DateTime? localToDate = _toDate;
    final fromDateText =
        localFromDate == null ? 'From Date' : _formatDate(localFromDate);
    final toDateText =
        localToDate == null ? 'To Date' : _formatDate(localToDate);

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
              label: Text(fromDateText),
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
              label: Text(toDateText),
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
                value: _paymentStatus,
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
                  setState(() {
                    _paymentStatus = value ?? 'all';
                  });
                },
              ),
            ),
            ElevatedButton.icon(
              onPressed: _applyFilters,
              icon: const Icon(Icons.filter_alt),
              label: const Text("Apply"),
            ),
            OutlinedButton.icon(
              onPressed: _resetFilters,
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked == null) return;
    setState(() {
      _fromDate = picked;
    });
  }

  Future<void> _pickToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (picked == null) return;
    setState(() {
      _toDate = picked;
    });
  }

  Future<void> _applyFilters() async {
    final DateTime? localFromDate = _fromDate;
    final DateTime? localToDate = _toDate;

    if (localFromDate != null &&
        localToDate != null &&
        localFromDate.isAfter(localToDate)) {
      if (!mounted) return;
      showSnackBar(
        context,
        "From Date cannot be after To Date",
        bgColor: Colors.red,
      );
      return;
    }
    await _loadKpiSummary();
  }

  Future<void> _resetFilters() async {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _paymentStatus = 'all';
    });
    await _loadKpiSummary();
  }

  Future<void> _loadCategorySales() async {
    setState(() {
      _isCategoryLoading = true;
      _categoryError = null;
    });
    try {
      final data = await _reportServices.fetchCategorySales(
        context: context,
        dateFrom: _categoryFromDate,
        dateTo: _categoryToDate,
        paymentStatus:
            _categoryPaymentStatus == 'all' ? null : _categoryPaymentStatus,
      );
      if (!mounted) return;
      setState(() {
        _categorySales = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isCategoryLoading = false;
      });
    }
  }

  Future<void> _loadProductSales() async {
    setState(() {
      _isProductLoading = true;
      _productError = null;
    });
    try {
      final data = await _reportServices.fetchProductSales(
        context: context,
        // dateFrom: _productFromDate,
        // dateTo: _productToDate,
        paymentStatus:
            _productPaymentStatus == 'all' ? null : _productPaymentStatus,
        // limit: _productLimit,
        sortBy: _productSortBy,
      );
      if (!mounted) return;
      setState(() {
        _productSales = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProductLoading = false;
      });
    }
  }

  Future<void> _loadPurchasedReceipts() async {
    setState(() {
      _isReceiptLoading = true;
      _receiptError = null;
    });
    try {
      final data = await _reportServices.fetchPurchasedReceipts(
        context: context,
      );
      if (!mounted) return;
      setState(() {
        _purchasedReceipts = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _receiptError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isReceiptLoading = false;
      });
    }
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _isSupplierLoading = true;
      _supplierError = null;
    });
    try {
      final data = await _reportServices.fetchSuppliers(context: context);
      if (!mounted) return;
      setState(() {
        _suppliers = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _supplierError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isSupplierLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isProductsLoading = true;
      _productsError = null;
    });
    try {
      final data = await _productServices.fetchAllProducts(context: context);
      if (!mounted) return;
      setState(() {
        _products = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _productsError = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isProductsLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Widget _buildKpiSection() {
    const spacing = 12.0;
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
                  value: (_kpi["total_transaction"] ?? 0).toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "Total Sales",
                  value: format.toRupiah(_kpi["total_sales"] ?? 0),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "Total Profit",
                  value: format.toRupiah(_kpi["total_profit"] ?? 0),
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: spacing),
              SizedBox(
                width: cardWidth,
                child: _buildKpiCard(
                  title: "ATV",
                  value: format.toRupiah(_kpi["avg_transaction_value"] ?? 0),
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
              value: (_kpi["total_transaction"] ?? 0).toString(),
              color: Colors.blue,
            ),
            _buildKpiCard(
              title: "Total Sales",
              value: format.toRupiah(_kpi["total_sales"] ?? 0),
              color: Colors.green,
            ),
            _buildKpiCard(
              title: "Total Profit",
              value: format.toRupiah(_kpi["total_profit"] ?? 0),
              color: Colors.orange,
            ),
            _buildKpiCard(
              title: "ATV",
              value: format.toRupiah(_kpi["avg_transaction_value"] ?? 0),
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
    final pointsRaw = (_series["points"] as List?) ?? const [];
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
              "Grouping: ${(_series["group_by"] ?? "day").toString()}",
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
    final fromText =
        _categoryFromDate == null ? 'From' : _formatDate(_categoryFromDate!);
    final toText =
        _categoryToDate == null ? 'To' : _formatDate(_categoryToDate!);

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
                    value: _categoryPaymentStatus,
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
                      setState(() {
                        _categoryPaymentStatus = val ?? 'all';
                      });
                    },
                  ),
                ),
                ElevatedButton(
                  onPressed: _applyCategoryFilters,
                  child: const Text("Apply"),
                ),
                OutlinedButton(
                  onPressed: _resetCategoryFilters,
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
    // final fromText =
    //     _productFromDate == null ? 'From' : _formatDate(_productFromDate!);
    // final toText = _productToDate == null ? 'To' : _formatDate(_productToDate!);

    // final dataSource = _ProductSalesDataSource(_productSales);

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
                // OutlinedButton(onPressed: _pickProductFromDate, child: Text(fromText)),
                // OutlinedButton(onPressed: _pickProductToDate, child: Text(toText)),
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField(
                    value: _productSortBy,
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
                      setState(() {
                        _productSortBy = value ?? 'sales_desc';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    value: _productPaymentStatus,
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
                      setState(() {
                        _productPaymentStatus = val ?? 'all';
                      });
                    },
                  ),
                ),
                // SizedBox(
                //   width: 120,
                //   child: DropdownButtonFormField<int>(
                //     value: _productLimit,
                //     decoration: const InputDecoration(
                //       labelText: "Limit",
                //       border: OutlineInputBorder(),
                //       isDense: true,
                //     ),
                //     items: const [
                //       DropdownMenuItem(value: 10, child: Text('10')),
                //       DropdownMenuItem(value: 20, child: Text('20')),
                //       DropdownMenuItem(value: 50, child: Text('50')),
                //       DropdownMenuItem(value: 100, child: Text('100')),
                //     ],
                //     onChanged: (val) {
                //       setState(() {
                //         _productLimit = val ?? 20;
                //       });
                //     },
                //   ),
                // ),
                ElevatedButton(
                  onPressed: _applyProductFilters,
                  child: const Text("Apply"),
                ),
                OutlinedButton(
                  onPressed: _resetProductFilters,
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
    if (_isCategoryLoading) {
      return const Center(child: CustomLoading());
    }
    if (_categoryError != null) {
      return Center(
        child: Text(_categoryError!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_categorySales.isEmpty) {
      return const Center(child: Text("No category data"));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _CategoryBarChartPainter(data: _categorySales),
        );
      },
    );
  }

  Widget _buildProductTableBody() {
    if (_isProductLoading) {
      return const Center(child: CustomLoading());
    }
    if (_productError != null) {
      return Center(
        child: Text(_productError!, style: const TextStyle(color: Colors.red)),
      );
    }
    if (_productSales.isEmpty) {
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
            _productRowsPerPage.clamp(1, maxRows == 0 ? 1 : maxRows);
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
            _productSales,
            nameColWidth: nameColWidth,
            salesColWidth: salesColWidth,
          ),
          rowsPerPage: effectiveRowsPerPage,
          availableRowsPerPage: availableRows,
          onRowsPerPageChanged: (value) {
            if (value == null) return;
            setState(() {
              _productRowsPerPage = value;
            });
          },
        );
      },
    );
  }

  Future<void> _pickCategoryFromDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _categoryFromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _categoryFromDate = picked;
    });
  }

  Future<void> _pickCategoryToDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _categoryToDate ?? _categoryFromDate ?? now,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _categoryToDate = picked;
    });
  }

  Future<void> _applyCategoryFilters() async {
    final from = _categoryFromDate;
    final to = _categoryToDate;
    if (from != null && to != null && from.isAfter(to)) {
      if (!mounted) return;
      showSnackBar(context, "From Date cannot be after To Date",
          bgColor: Colors.red);
      return;
    }
    await _loadCategorySales();
  }

  Future<void> _resetCategoryFilters() async {
    setState(() {
      _categoryFromDate = null;
      _categoryToDate = null;
      _categoryPaymentStatus = 'all';
    });
    await _loadCategorySales();
  }

  // Future<void> _pickProductFromDate() async {
  //   final now = DateTime.now();
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: _productFromDate ?? now,
  //     firstDate: DateTime(2020, 1, 1),
  //     lastDate: DateTime(now.year + 5, 12, 31),
  //   );
  //   if (picked == null) return;
  //   setState(() {
  //     _productFromDate = picked;
  //   });
  // }

  // Future<void> _pickProductToDate() async {
  //   final now = DateTime.now();
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: _productToDate ?? _productFromDate ?? now,
  //     firstDate: DateTime(2020, 1, 1),
  //     lastDate: DateTime(now.year + 5, 12, 31),
  //   );
  //   if (picked == null) return;
  //   setState(() {
  //     _productToDate = picked;
  //   });
  // }

  Future<void> _applyProductFilters() async {
    final from = _productFromDate;
    final to = _productToDate;
    if (from != null && to != null && from.isAfter(to)) {
      if (!mounted) return;
      showSnackBar(context, "From Date cannot be after To Date",
          bgColor: Colors.red);
      return;
    }
    await _loadProductSales();
  }

  Future<void> _resetProductFilters() async {
    setState(() {
      _productFromDate = null;
      _productToDate = null;
      _productPaymentStatus = 'all';
      // _productLimit = 50;
      _productSortBy = 'sales_desc';
    });
    await _loadProductSales();
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
                            builder: (context) => SupplierScreen(),
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
    if (_isReceiptLoading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CustomLoading()),
      );
    }
    if (_receiptError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(_receiptError!, style: const TextStyle(color: Colors.red)),
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
                    _purchasedReceipts.isEmpty ? 1 : _purchasedReceipts.length,
                    (index) {
                      if (_purchasedReceipts.isEmpty) {
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

                      final item = _purchasedReceipts[index];
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
                                  onPressed: () {
                                    _showPurchasedReceiptDialog(item.id);
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
                                  onPressed: () {
                                    _updateInvoice(item.id);
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

  Future<void> _updateInvoice(int receiptId) async {
    PurchasedReceipt? detail;
    bool isLoading = true;
    bool isSubmitting = false;
    String? error;

    final receiptNoCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? receiptDate;

    final qtyCtrls = <TextEditingController>[];
    final unitCtrls = <TextEditingController>[];

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> loadDetail() async {
            try {
              final data = await _reportServices.fetchPurchasedReceiptDetail(
                context: context,
                id: receiptId,
              );

              if (!mounted) return;

              detail = data;
              receiptNoCtrl.text = data?.receiptNo ?? '';
              noteCtrl.text = data?.note ?? '';
              receiptDate = DateTime.parse(data?.receiptDate ?? '');

              qtyCtrls.clear();
              unitCtrls.clear();

              for (final item in data?.items ?? []) {
                qtyCtrls.add(TextEditingController(text: item.qty.toString()));
                // debugPrint("unit cost : ${item.unitCost}");
                unitCtrls
                    .add(TextEditingController(text: item.unitCost.toString()));
              }

              setDialogState(() => isLoading = false);
            } catch (e) {
              setDialogState(() {
                error = e.toString();
                isLoading = false;
              });
            }
          }

          if (isLoading && detail == null && error == null) {
            loadDetail();
            // debugPrint("is control unit empty: ${unitCtrls.isEmpty.toString()}");
          }

          Future<void> submit() async {
            if (detail == null) return;

            final itemsPayload = <Map<String, dynamic>>[];
            for (var i = 0; i < detail!.items.length; i++) {
              final qty = double.tryParse(qtyCtrls[i].text.trim()) ?? 0;
              final unit = double.tryParse(unitCtrls[i].text.trim()) ?? 0;
              // debugPrint("unit value in itemspayload[] : ${unit}");

              if (qty <= 0 || unit < 0) {
                showSnackBar(context, "Qty/unit_cost invalid",
                    bgColor: Colors.red);
                return;
              }

              final item = detail!.items[i];
              itemsPayload.add({
                "id_product": item.idProduct,
                "id_product_unit": item.idProductUnit,
                "qty": qty,
                "unit_cost": unit,
              });
            }

            setDialogState(() => isSubmitting = true);

            final ok = await _reportServices.updatePurchasedReceipt(
              context: context,
              id: detail!.id,
              payload: {
                "id_supplier": detail!.idSupplier,
                "receipt_no": receiptNoCtrl.text.trim(),
                "receipt_date": receiptDate?.toIso8601String().substring(0, 10),
                "note": noteCtrl.text.trim(),
                "items": itemsPayload,
              },
            );

            setDialogState(() => isSubmitting = false);

            if (ok) {
              Navigator.pop(context);
              await _loadPurchasedReceipts();
              showSnackBar(context, "Receipt Updated", bgColor: Colors.green);
            }
          }

          return AlertDialog(
            insetPadding: const EdgeInsets.all(20),
            backgroundColor: GlobalVariables.backgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Update Receipt"),
            content: SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.height * 0.7,
              child: isLoading
                  ? const Center(child: CustomLoading())
                  : error != null
                      ? Center(
                          child: Text(error!,
                              style: const TextStyle(color: Colors.red)))
                      : detail == null
                          ? const Center(child: Text("No detail found"))
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
                                          initialDate: receiptDate ?? now,
                                          firstDate: DateTime(2020, 1, 1),
                                          lastDate:
                                              DateTime(now.year + 5, 12, 31));
                                      if (picked != null) {
                                        setDialogState(
                                            () => receiptDate = picked);
                                      }
                                    },
                                    icon: const Icon(Icons.date_range),
                                    label: Text(receiptDate == null
                                        ? "Pick Date"
                                        : DateFormat('yyyy-mm-dd')
                                            .format(receiptDate!)),
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
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: detail!.items.length,
                                    itemBuilder: (context, index) {
                                      final item = detail!.items[index];
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
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
                                                decoration:
                                                    const InputDecoration(
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
                                                decoration:
                                                    const InputDecoration(
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
                onPressed: isSubmitting ? null : submit,
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleUploadInvoice(int receiptId) async {
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
    final uploaded = await _reportServices.uploadPurchasedReceiptFile(
      context: context,
      receiptId: receiptId,
      filePath: filePath,
    );
    if (!mounted) return;
    if (uploaded == null) {
      showSnackBar(context, "Upload failed", bgColor: Colors.red);
      return;
    }
    showSnackBar(context, "Invoice uploaded", bgColor: Colors.green);
    await _loadPurchasedReceipts();
  }

  Future<void> _deleteInvoice(PurchasedReceipt receipt) async {
    final isConfirmed = await showDialog<bool>(
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

    if (isConfirmed != true) return;

    final ok = await _reportServices.deletePurchasedReceipt(
      context: context,
      id: receipt.id,
    );
    if (!mounted) return;
    if (ok) {
      await _loadPurchasedReceipts();
      showSnackBar(context, "Receipt deleted", bgColor: Colors.green);
    }
  }

  

  Future<void> _showAddInvoiceDialog() async {
    if (_isSupplierLoading || _isProductsLoading) {
      showSnackBar(context, "Loading data...", bgColor: Colors.black87);
      return;
    }
    if (_supplierError != null) {
      showSnackBar(context, _supplierError!, bgColor: Colors.red);
      return;
    }
    if (_productsError != null) {
      showSnackBar(context, _productsError!, bgColor: Colors.red);
      return;
    }

    final receiptNoCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    DateTime? receiptDate;
    Supplier? selectedSupplier;
    final items = <_ReceiptItemDraft>[];

    void addItem() {
      final draft = _ReceiptItemDraft();
      if (_products.isNotEmpty) {
        draft.productId = _products.first.id;
        if (_products.first.units.isNotEmpty) {
          draft.unitId = _products.first.units.first.id;
        }
      }
      items.add(draft);
    }

    addItem();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void removeItem(int index) {
            items[index].dispose();
            items.removeAt(index);
            setDialogState(() {});
          }

          Product? findProduct(int? id) {
            return _products
                .where((p) => p.id == id)
                .cast<Product?>()
                .firstOrNull;
          }

          List<ProductUnit> unitsForProduct(int? id) {
            final product = findProduct(id);
            return product?.units ?? [];
          }

          Future<void> submit() async {
            if (selectedSupplier == null) {
              showSnackBar(context, "Select supplier", bgColor: Colors.red);
              return;
            }
            if (receiptDate == null) {
              showSnackBar(context, "Select receipt date", bgColor: Colors.red);
              return;
            }
            if (items.isEmpty) {
              showSnackBar(context, "Add at least one item",
                  bgColor: Colors.red);
              return;
            }

            final payloadItems = <Map<String, dynamic>>[];
            for (final item in items) {
              final qty = double.tryParse(item.qtyCtrl.text.trim()) ?? 0;
              final unitCost =
                  double.tryParse(item.unitCostCtrl.text.trim()) ?? 0;
              if (item.productId == null ||
                  item.unitId == null ||
                  qty <= 0 ||
                  unitCost < 0) {
                showSnackBar(context, "Invalid item values",
                    bgColor: Colors.red);
                return;
              }
              payloadItems.add({
                "id_product": item.productId,
                "id_product_unit": item.unitId,
                "qty": qty,
                "unit_cost": unitCost,
              });
            }

            final result = await _reportServices.createPurchasedReceipt(
              context: context,
              payload: {
                "id_supplier": selectedSupplier!.id,
                "receipt_no": receiptNoCtrl.text.trim(),
                "receipt_date": DateFormat('yyyy-MM-dd').format(receiptDate!),
                "note": noteCtrl.text.trim(),
                "items": payloadItems,
              },
            );

            if (result == null) {
              showSnackBar(context, "Failed to create receipt",
                  bgColor: Colors.red);
              return;
            }

            if (!mounted) return;
            Navigator.pop(context);
            await _loadPurchasedReceipts();
            showSnackBar(context, "Receipt created", bgColor: Colors.green);
          }

          return AlertDialog(
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
                      value: selectedSupplier,
                      decoration: const InputDecoration(
                        labelText: "Supplier",
                        border: OutlineInputBorder(),
                      ),
                      items: _suppliers
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedSupplier = value;
                        });
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
                          initialDate: receiptDate ?? now,
                          firstDate: DateTime(2020, 1, 1),
                          lastDate: DateTime(now.year + 5, 12, 31),
                        );
                        if (picked != null) {
                          setDialogState(() => receiptDate = picked);
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        receiptDate == null
                            ? "Pick Date"
                            : DateFormat('yyyy-MM-dd').format(receiptDate!),
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
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final units = unitsForProduct(item.productId);
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
                                      items: _products
                                          .map(
                                            (p) => DropdownMenuItem(
                                              value: p.id,
                                              child: Text(p.productName),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        setDialogState(() {
                                          item.productId = value;
                                          final nextUnits =
                                              unitsForProduct(value);
                                          item.unitId = nextUnits.isNotEmpty
                                              ? nextUnits.first.id
                                              : null;
                                        });
                                      },
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
                                      onChanged: (value) {
                                        setDialogState(() {
                                          item.unitId = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    onPressed: () => removeItem(index),
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
                        onPressed: () {
                          setDialogState(() {
                            addItem();
                          });
                        },
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
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: submit,
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );

    for (final item in items) {
      item.dispose();
    }
  }

  Future<void> _showPurchasedReceiptDialog(int receiptId) async {
    bool isLoading = true;
    String? error;
    PurchasedReceipt? detail;

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> load() async {
            try {
              final data = await _reportServices.fetchPurchasedReceiptDetail(
                context: context,
                id: receiptId,
              );
              if (!mounted) return;
              setDialogState(() {
                detail = data;
                isLoading = false;
              });
            } catch (e) {
              if (!mounted) return;
              setDialogState(() {
                error = e.toString();
                isLoading = false;
              });
            }
          }

          if (isLoading && detail == null && error == null) {
            load();
          }

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
              child: isLoading
                  ? const Center(child: CustomLoading())
                  : error != null
                      ? Center(
                          child: Text(
                            error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        )
                      : detail == null
                          ? const Center(child: Text("No detail found"))
                          : _buildReceiptDetailBody(detail!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          );
        },
      ),
    );
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

class _ReceiptItemDraft {
  int? productId;
  int? unitId;
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController unitCostCtrl = TextEditingController();

  void dispose() {
    qtyCtrl.dispose();
    unitCostCtrl.dispose();
  }
}
