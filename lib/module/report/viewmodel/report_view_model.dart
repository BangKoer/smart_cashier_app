import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';
import 'package:smart_cashier_app/models/purchased_receipt.dart';
import 'package:smart_cashier_app/models/supplier.dart';
import 'package:smart_cashier_app/models/receiptItemDraft.dart';
import 'package:smart_cashier_app/module/products/services/products_services.dart';
import 'package:smart_cashier_app/module/report/services/report_services.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportServices reportServices;
  final ProductServices productServices;

  ReportViewModel(
    this.reportServices,
    this.productServices,
  );

  bool isLoading = true;
  String? errorMessage;
  String paymentStatus = 'all';
  DateTime? fromDate;
  DateTime? toDate;
  Map<String, dynamic> kpi = {
    "total_transaction": 0,
    "total_sales": 0.0,
    "total_profit": 0.0,
    "avg_transaction_value": 0.0,
  };
  Map<String, dynamic> series = {
    "group_by": "day",
    "points": <Map<String, dynamic>>[],
  };

  bool isCategoryLoading = true;
  String? categoryError;
  DateTime? categoryFromDate;
  DateTime? categoryToDate;
  String categoryPaymentStatus = 'all';
  List<Map<String, dynamic>> categorySales = [];

  bool isProductLoading = true;
  String? productError;
  DateTime? productFromDate;
  DateTime? productToDate;
  String productPaymentStatus = 'all';
  String productSortBy = 'sales_desc';
  int productRowsPerPage = 10;
  List<Map<String, dynamic>> productSales = [];

  bool isReceiptLoading = true;
  String? receiptError;
  List<PurchasedReceipt> purchasedReceipts = [];
  PurchasedReceipt? detail;
  String? detailError;
  bool isDetailLoading = true;
  bool isFilesUploading = true;
  bool isSubmittingReceipt = false;
  DateTime? editingReceiptDate;

  bool isSupplierLoading = true;
  String? supplierError;
  List<Supplier> suppliers = [];

  bool isProductsLoading = true;
  String? productsError;
  List<Product> products = [];
  DateTime? receiptDate;
  Supplier? selectedSupplier;
  final items = <ReceiptItemDraft>[];
  List<ProductUnit> units = [];
  DateTime? addInvoiceDate;

  void getUnitsFromItems(int id) {
    units = unitsForProduct(id);
    notifyListeners();
  }

  void setAddInvoiceDate(DateTime date) {
    addInvoiceDate = date;
    receiptDate = date;
    notifyListeners();
  }

  void setSelectedSupplier(Supplier sup) {
    selectedSupplier = sup;
    notifyListeners();
  }

  void setReceiptDate(DateTime date) {
    receiptDate = date;
    addInvoiceDate = date;
    notifyListeners();
  }

  void setEditingReceiptDate(DateTime? date) {
    editingReceiptDate = date;
    notifyListeners();
  }

  void initEditingReceiptDateFromDetail() {
    if (detail == null) return;
    editingReceiptDate = DateTime.tryParse(detail!.receiptDate);
    notifyListeners();
  }

  void clearEditingReceiptState() {
    editingReceiptDate = null;
    notifyListeners();
  }

  void setProductRowPerPage(int row) {
    productRowsPerPage = row;
    notifyListeners();
  }

  void setProductSortBy({String sort = "sales_desc"}) {
    productSortBy = sort;
    notifyListeners();
  }

  void setProductPaymentStatus({String status = "all"}) {
    productPaymentStatus = status;
    notifyListeners();
  }

  void setCategoryPaymentStatus({String status = "all"}) {
    categoryPaymentStatus = status;
    notifyListeners();
  }

  void setCategoryFromDate(DateTime date) {
    categoryFromDate = date;
    notifyListeners();
  }

  void setCategoryToDate(DateTime date) {
    categoryToDate = date;
    notifyListeners();
  }

  void setPaymentStatus({String status = "all"}) {
    paymentStatus = status;
    notifyListeners();
  }

  void setFromDate(DateTime date) {
    fromDate = date;
    notifyListeners();
  }

  void setToDate(DateTime date) {
    toDate = date;
    notifyListeners();
  }

  String formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Future<void> resetFilters(BuildContext context) async {
    fromDate = null;
    toDate = null;
    paymentStatus = 'all';
    notifyListeners();
    await loadKpiSummary(context);
  }

  Future<void> resetCategoryFilters(BuildContext context) async {
    categoryFromDate = null;
    categoryToDate = null;
    categoryPaymentStatus = 'all';
    notifyListeners();
    await loadCategorySales(context);
  }

  Future<void> resetProductFilters(BuildContext context) async {
    productFromDate = null;
    productToDate = null;
    productPaymentStatus = 'all';
    // productLimit = 50;
    productSortBy = 'sales_desc';
    notifyListeners();
    await loadProductSales(context);
  }

  bool applyFilters() {
    if (fromDate != null && toDate != null && fromDate!.isAfter(toDate!)) {
      return false;
    }
    return true;
  }

  bool applyCategoryFilters() {
    if (categoryFromDate != null &&
        categoryToDate != null &&
        categoryFromDate!.isAfter(categoryToDate!)) {
      return false;
    }
    return true;
  }

  bool applyProductFilters() {
    if (productFromDate != null &&
        productToDate != null &&
        productFromDate!.isAfter(productToDate!)) {
      return false;
    }
    return true;
  }

  Future<void> loadKpiSummary(BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final filtersPayment = paymentStatus == 'all' ? null : paymentStatus;
      final data = await reportServices.fetchKpiSummary(
          context: context,
          dateFrom: fromDate,
          dateTo: toDate,
          paymentStatus: filtersPayment);
      var seriesResult = await reportServices.fetchSalesSeries(
        context: context,
        dateFrom: fromDate,
        dateTo: toDate,
        paymentStatus: filtersPayment,
      );
      kpi = data;
      series = seriesResult;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
    }
  }

  Future<void> loadCategorySales(BuildContext context) async {
    isCategoryLoading = true;
    categoryError = null;
    notifyListeners();

    try {
      final data = await reportServices.fetchCategorySales(
        context: context,
        dateFrom: categoryFromDate,
        dateTo: categoryToDate,
        paymentStatus:
            categoryPaymentStatus == 'all' ? null : categoryPaymentStatus,
      );
      categorySales = data;
      notifyListeners();
    } catch (e) {
      categoryError = e.toString();
      notifyListeners();
    } finally {
      isCategoryLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadProductSales(BuildContext context) async {
    isProductLoading = true;
    productError = null;
    notifyListeners();

    try {
      final data = await reportServices.fetchProductSales(
        context: context,
        paymentStatus:
            productPaymentStatus == 'all' ? null : productPaymentStatus,
        sortBy: productSortBy,
      );

      productSales = data;
      notifyListeners();
    } catch (e) {
      productError = e.toString();
      notifyListeners();
    } finally {
      isProductLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPurchasedReceipts(BuildContext context) async {
    isReceiptLoading = true;
    receiptError = null;
    try {
      final data = await reportServices.fetchPurchasedReceipts(
        context: context,
      );
      purchasedReceipts = data;
      notifyListeners();
    } catch (e) {
      receiptError = e.toString();
      notifyListeners();
    } finally {
      isReceiptLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetailPurchasedReceipt(
      BuildContext context, int receiptId) async {
    try {
      final data = await reportServices.fetchPurchasedReceiptDetail(
        context: context,
        id: receiptId,
      );
      detail = data;
      editingReceiptDate =
          detail == null ? null : DateTime.tryParse(detail!.receiptDate);
      isDetailLoading = false;
      notifyListeners();
    } catch (e) {
      detailError = e.toString();
      isDetailLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitReceipt(
      BuildContext context,
      String receiptNo,
      String receiptNote,
      // DateTime receiptDate,
      List<String> qtyList,
      List<String> unitList) async {
    if (detail == null) return false;

    final itemsPayload = <Map<String, dynamic>>[];
    for (var i = 0; i < detail!.items.length; i++) {
      final qty = double.tryParse(qtyList[i].trim()) ?? 0;
      final unit = double.tryParse(unitList[i].trim()) ?? 0;
      // debugPrint("unit value in itemspayload[] : ${unit}");

      if (qty <= 0 || unit < 0) {
        debugPrint("Qty/unit_cost invalid");
        debugPrint("${qty.toString()},${unit.toString()}");
        return false;
      }

      final item = detail!.items[i];
      itemsPayload.add({
        "id_product": item.idProduct,
        "id_product_unit": item.idProductUnit,
        "qty": qty,
        "unit_cost": unit,
      });
    }

    isSubmittingReceipt = true;
    notifyListeners();

    if (editingReceiptDate == null) {
      debugPrint("Receipt date is required");
      return false;
    }

    final ok = await reportServices.updatePurchasedReceipt(
      context: context,
      id: detail!.id,
      payload: {
        "id_supplier": detail!.idSupplier,
        "receipt_no": receiptNo.trim(),
        "receipt_date": editingReceiptDate?.toIso8601String().substring(0, 10),
        "note": receiptNote.trim(),
        "items": itemsPayload,
      },
    );

    isSubmittingReceipt = false;
    notifyListeners();

    if (ok) {
      await loadPurchasedReceipts(context);
      return true;
    }
    return false;
  }

  Future<void> uploadFiles(
      BuildContext context, int receiptId, String filePath) async {
    try {
      final uploaded = await reportServices.uploadPurchasedReceiptFile(
        context: context,
        receiptId: receiptId,
        filePath: filePath,
      );
      if (uploaded != null) {
        isFilesUploading = false;
        notifyListeners();
      } else {
        debugPrint('no files uploaded');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<bool> deleteReceipt(BuildContext context, int id) async {
    final result =
        await reportServices.deletePurchasedReceipt(context: context, id: id);
    if (result) {
      return true;
    }
    return false;
  }

  Future<void> loadSuppliers(BuildContext context) async {
    isSupplierLoading = true;
    supplierError = null;
    notifyListeners();
    try {
      final data = await reportServices.fetchSuppliers(context: context);
      suppliers = data;
      notifyListeners();
    } catch (e) {
      supplierError = e.toString();
      notifyListeners();
    } finally {
      isSupplierLoading = false;
      notifyListeners();
    }
  }

  // =========================
  // Supplier CRUD
  // =========================
  Future<bool> saveSupplier({
    required BuildContext context,
    Supplier? supplier,
    required String supplierName,
    required String phone,
    required String company,
    required String address,
  }) async {
    final name = supplierName.trim();
    if (name.isEmpty) return false;

    final isEdit = supplier != null;
    final ok = isEdit
        ? await reportServices.updateSupplier(
            context: context,
            id: supplier.id,
            supplierName: name,
            phone: phone.trim(),
            company: company.trim(),
            address: address.trim(),
          )
        : await reportServices.createSupplier(
            context: context,
            supplierName: name,
            phone: phone.trim(),
            company: company.trim(),
            address: address.trim(),
          );

    if (ok) {
      await loadSuppliers(context);
    }
    return ok;
  }

  Future<bool> removeSupplier({
    required BuildContext context,
    required int id,
  }) async {
    final ok = await reportServices.deleteSupplier(
      context: context,
      id: id,
    );
    if (ok) {
      await loadSuppliers(context);
    }
    return ok;
  }

  Future<void> loadProducts(BuildContext context) async {
    isProductsLoading = true;
    productsError = null;
    notifyListeners();

    try {
      final data = await productServices.fetchAllProducts(context: context);
      products = data;
      notifyListeners();
    } catch (e) {
      productsError = e.toString();
      notifyListeners();
    } finally {
      isProductsLoading = false;
      notifyListeners();
    }
  }

  void addItem() {
    final draft = ReceiptItemDraft();
    if (products.isNotEmpty) {
      draft.productId = products.first.id;
      if (products.first.units.isNotEmpty) {
        draft.unitId = products.first.units.first.id;
      }
    }
    items.add(draft);
    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= items.length) return;
    final removed = items[index];
    items.removeAt(index);
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed.dispose();
    });
  }

  Product? findProduct(int? id) {
    return products.where((p) => p.id == id).cast<Product?>().firstOrNull;
  }

  List<ProductUnit> unitsForProduct(int? id) {
    final product = findProduct(id);
    return product?.units ?? [];
  }

  void setProductForItem(int index, int? productId) {
    if (index < 0 || index >= items.length) return;
    final item = items[index];
    item.productId = productId;
    final nextUnits = unitsForProduct(productId);
    item.unitId = nextUnits.isNotEmpty ? nextUnits.first.id : null;
    notifyListeners();
  }

  void setUnitForItem(int index, int? unitId) {
    if (index < 0 || index >= items.length) return;
    items[index].unitId = unitId;
    notifyListeners();
  }

  void prepareAddInvoiceDraft() {
    clearAddInvoiceDraft();
    addItem();
  }

  void clearAddInvoiceDraft() {
    final oldItems = List<ReceiptItemDraft>.from(items);
    items.clear();
    selectedSupplier = null;
    receiptDate = null;
    addInvoiceDate = null;
    notifyListeners();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final item in oldItems) {
        item.dispose();
      }
    });
  }

  Future<bool> submitProduct(
      BuildContext context, String receiptNo, String note) async {
    if (selectedSupplier == null) {
      debugPrint("Select supplier");
      return false;
    }
    if (receiptDate == null) {
      debugPrint("Select receipt date");
      return false;
    }
    if (items.isEmpty) {
      debugPrint("Add at least one item");
      return false;
    }

    final payloadItems = <Map<String, dynamic>>[];
    for (final item in items) {
      final qty = double.tryParse(item.qtyCtrl.text.trim()) ?? 0;
      final unitCost = double.tryParse(item.unitCostCtrl.text.trim()) ?? 0;
      if (item.productId == null ||
          item.unitId == null ||
          qty <= 0 ||
          unitCost < 0) {
        debugPrint("Invalid item values");
        return false;
      }
      payloadItems.add({
        "id_product": item.productId,
        "id_product_unit": item.unitId,
        "qty": qty,
        "unit_cost": unitCost,
      });
    }

    final result = await reportServices.createPurchasedReceipt(
      context: context,
      payload: {
        "id_supplier": selectedSupplier!.id,
        "receipt_no": receiptNo.trim(),
        "receipt_date": DateFormat('yyyy-MM-dd').format(receiptDate!),
        "note": note.trim(),
        "items": payloadItems,
      },
    );

    if (result == null) {
      debugPrint("Failed to create receipt");
      return false;
    }
    await loadPurchasedReceipts(context);
    debugPrint("Receipt created");
    return true;
  }
}
