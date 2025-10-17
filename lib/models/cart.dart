import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';

class CartItem {
  final Product product;
  int qty;
  ProductUnit? selectedUnit;

  CartItem({
    required this.product,
    this.qty = 1,
    this.selectedUnit,
  });

  double get total {
    final priceUnit = selectedUnit!.price;
    final price = priceUnit;
    return price * qty;
  }
}