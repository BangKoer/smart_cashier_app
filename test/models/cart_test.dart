import 'package:flutter_test/flutter_test.dart';
import 'package:smart_cashier_app/models/cart.dart';
import 'package:smart_cashier_app/models/category.dart';
import 'package:smart_cashier_app/models/product.dart';
import 'package:smart_cashier_app/models/product_unit.dart';

void main() {
  Product fakeProduct() => Product(
        id: 1,
        barcode: '123',
        productName: 'Item',
        stock: 10,
        purchasedPrice: 1000,
        idCategory: 1,
        units: [
          ProductUnit(
            id: 1,
            idProduct: 1,
            nameUnit: 'pcs',
            price: 10000,
            conversion: 1,
          )
        ],
        category: Category(1, 'General'),
      );

  test("discount percent compute correctly", () {
    final item = CartItem(product: fakeProduct(), selectedUnit: fakeProduct().units.first, qty: 2);
    item.applyDiscountPercent(10);
    expect(item.totalBeforeDiscount, 20000);
    expect(item.discountAmount, 2000);
    expect(item.total, 18000);
  },);

  test('discount amount computes percent payload', () {
    final item = CartItem(product: fakeProduct(), selectedUnit: fakeProduct().units.first, qty: 2);
    item.applyDiscountAmount(5000);
    expect(item.discountAmount, 5000);
    expect(item.discountPercentForPayload, 25.0);
    expect(item.total, 15000);
  });
}