import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';

class CartItem {
  final Product product;
  double qty;
  ProductUnit? selectedUnit;
  double? discountPercent;
  double? discountAmountInput;

  CartItem({
    required this.product,
    this.qty = 1,
    this.selectedUnit,
    this.discountPercent,
    this.discountAmountInput,
  });

  double _roundTo(double value, int fractionDigits) {
    return double.parse(value.toStringAsFixed(fractionDigits));
  }

  double get unitPriceSnapshot => _roundTo(selectedUnit?.price ?? 0, 2);

  double get totalBeforeDiscount => _roundTo(unitPriceSnapshot * qty, 2);

  void applyDiscountPercent(double? value) {
    if (value == null) {
      discountPercent = null;
      discountAmountInput = null;
      return;
    }
    final validPercent = value.clamp(0, 100).toDouble();
    discountPercent = _roundTo(validPercent, 1);
    discountAmountInput = null;
  }

  void applyDiscountAmount(double? value) {
    if (value == null) {
      discountAmountInput = null;
      discountPercent = null;
      return;
    }
    final maxDiscount = totalBeforeDiscount;
    final validAmount = value.clamp(0, maxDiscount).toDouble();
    discountAmountInput = _roundTo(validAmount, 2);
    discountPercent = null;
  }

  double get discountAmount {
    if (discountAmountInput != null) {
      final maxDiscount = totalBeforeDiscount;
      return _roundTo(
        discountAmountInput!.clamp(0, maxDiscount).toDouble(),
        2,
      );
    }
    final percent = discountPercent ?? 0;
    final validPercent = percent.clamp(0, 100).toDouble();
    return _roundTo(totalBeforeDiscount * validPercent / 100, 2);
  }

  double? get discountPercentForPayload {
    if (discountAmountInput != null) {
      if (totalBeforeDiscount <= 0) return 0;
      return _roundTo((discountAmount / totalBeforeDiscount) * 100, 1);
    }
    return discountPercent == null ? null : _roundTo(discountPercent!, 1);
  }

  double get total {
    final subtotal = totalBeforeDiscount - discountAmount;
    return _roundTo(subtotal < 0 ? 0 : subtotal, 2);
  }
}
