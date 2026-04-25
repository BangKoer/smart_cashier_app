import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:smart_cashier_app/models/sales.dart';
import 'package:smart_cashier_app/module/sales/services/sales_services.dart';

class SalesVM extends ChangeNotifier {
  final SalesServices salesServices;

  SalesVM(this.salesServices);

  bool isLoading = true;
  List<Sales> salesList = [];

  String searchQuery = '';
  String selectedSortFilter = 'date_desc';
  String selectedPaymentStatusFilter = 'all';

  DateTime _toDate(String input) => DateTime.tryParse(input) ?? DateTime(1970);

  String formatDate(String input) {
    final dt = _toDate(input);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String formatQty(double qty) {
    if (qty == qty.toInt()) {
      return qty.toInt().toString();
    }
    return qty.toString();
  }

  Future<void> fetchSales(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    salesList = await salesServices.fetchAllSales(context: context);
    isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSales(BuildContext context, int id) async {
    isLoading = true;
    notifyListeners();

    await salesServices.deleteSales(context: context, id: id);
    await fetchSales(context);
    
    isLoading = false;
    notifyListeners();
  }

  List<Sales> getFilteredSales() {
    final filtered = salesList.where((sales) {
      final matchPaymentStatus = selectedPaymentStatusFilter == 'all' ||
          sales.payment_status == selectedPaymentStatusFilter;
      if (!matchPaymentStatus) return false;

      if (searchQuery.isEmpty) return true;

      final search = searchQuery.toLowerCase();
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

    switch (selectedSortFilter) {
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

  void setFilterQuery(
      {String searchQueryValue = '',
      String selectedSortFilterValue = 'date_desc',
      String selectedPaymentStatusFilterValue = 'all'}) {
    searchQuery = searchQueryValue.trim();
    selectedSortFilter = selectedSortFilterValue;
    selectedPaymentStatusFilter = selectedPaymentStatusFilterValue;
    notifyListeners();
  }

  void resetTableFilters() {
    selectedSortFilter = 'date_desc';
    selectedPaymentStatusFilter = 'all';
    searchQuery = '';
    notifyListeners();
  }
}
