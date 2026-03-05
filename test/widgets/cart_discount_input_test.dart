import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cashier_app/models/cart.dart';
import 'package:smart_cashier_app/models/category.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';
import 'package:smart_cashier_app/module/cashier/widgets/cart_discount_input.dart';
import 'package:smart_cashier_app/utils/format_rupiah.dart' as format;

Product _fakeProduct() {
  return Product(
    id: 1,
    barcode: '123',
    productName: 'Test Product',
    stock: 10,
    purchasedPrice: 5000,
    idCategory: 1,
    units: [
      ProductUnit(
        id: 1,
        idProduct: 1,
        nameUnit: 'pcs',
        price: 10000,
        conversion: 1,
      ),
    ],
    category: Category(1, 'General'),
  );
}

class _DiscountHarness extends StatefulWidget {
  const _DiscountHarness({required this.item});
  final CartItem item;

  @override
  State<_DiscountHarness> createState() => _DiscountHarnessState();
}

class _DiscountHarnessState extends State<_DiscountHarness> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            CartDiscountInput(
              cartItem: widget.item,
              mode: DiscountInputMode.percent,
              inputKey: const Key('percent_input'),
              onChanged: () => setState(() {}),
            ),
            CartDiscountInput(
              cartItem: widget.item,
              mode: DiscountInputMode.amount,
              inputKey: const Key('amount_input'),
              onChanged: () => setState(() {}),
            ),
            Text(
              format.toRupiah(widget.item.total),
              key: const Key('total_text'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('discount percent updates total', (tester) async {
    final product = _fakeProduct();
    final item = CartItem(
      product: product,
      selectedUnit: product.units.first,
      qty: 2,
    );

    await tester.pumpWidget(_DiscountHarness(item: item));

    await tester.enterText(find.byKey(const Key('percent_input')), '10');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.text('10'), findsOneWidget);
    expect(find.byKey(const Key('total_text')), findsOneWidget);
    expect(find.text(format.toRupiah(18000)), findsOneWidget);
  });

  testWidgets('discount amount updates total', (tester) async {
    final product = _fakeProduct();
    final item = CartItem(
      product: product,
      selectedUnit: product.units.first,
      qty: 2,
    );

    await tester.pumpWidget(_DiscountHarness(item: item));

    await tester.enterText(find.byKey(const Key('amount_input')), '5000');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(find.byKey(const Key('total_text')), findsOneWidget);
    expect(find.text(format.toRupiah(15000)), findsOneWidget);
  });
}

