import 'package:flutter_test/flutter_test.dart';

import 'package:ecommerce_a/models/product.dart';
import 'package:ecommerce_a/services/cart_controller.dart';

void main() {
  const product = Product(
    id: 7,
    name: 'Áo thun',
    price: 199000,
    imageUrl: 'https://example.com/shirt.png',
  );

  test('merges matching product sizes and calculates subtotal', () {
    final cart = CartController();

    cart
      ..add(product, 'M')
      ..add(product, 'M')
      ..add(product, 'L');

    expect(cart.items, hasLength(2));
    expect(cart.itemCount, 3);
    expect(cart.subtotal, 597000);

    cart.dispose();
  });

  test('updates quantities and removes items at zero', () {
    final cart = CartController()..add(product, 'S');
    final item = cart.items.single;

    cart.setQuantity(item, 3);
    expect(cart.itemCount, 3);
    expect(cart.subtotal, 597000);

    cart.setQuantity(cart.items.single, 0);
    expect(cart.items, isEmpty);
    expect(cart.itemCount, 0);

    cart.dispose();
  });
}
