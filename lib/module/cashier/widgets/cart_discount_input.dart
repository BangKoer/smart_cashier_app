import 'package:flutter/material.dart';
import 'package:smart_cashier_app/models/cart.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;

enum DiscountInputMode { percent, amount }

class CartDiscountInput extends StatelessWidget {
  final CartItem cartItem;
  final DiscountInputMode mode;
  final VoidCallback onChanged;
  final Key? inputKey;

  const CartDiscountInput({
    super.key,
    required this.cartItem,
    required this.mode,
    required this.onChanged,
    this.inputKey,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDiscount = cartItem.discountPercent != null ||
        cartItem.discountAmountInput != null;

    final String text = switch (mode) {
      DiscountInputMode.percent => hasDiscount
          ? format.formatDouble(cartItem.discountPercentForPayload ?? 0)
          : '',
      DiscountInputMode.amount =>
        hasDiscount ? format.formatDouble(cartItem.discountAmount) : '',
    };

    return SizedBox(
      width: mode == DiscountInputMode.amount ? 90 : 70,
      child: TextField(
        key: inputKey,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        controller: TextEditingController(text: text),
        onSubmitted: (val) {
          final parsed = double.tryParse(val.trim());
          if (mode == DiscountInputMode.percent) {
            cartItem.applyDiscountPercent(parsed);
          } else {
            cartItem.applyDiscountAmount(parsed);
          }
          onChanged();
        },
      ),
    );
  }
}

