import 'package:flutter/widgets.dart';

import '../services/cart_controller.dart';

class CartScope extends InheritedWidget {
  final CartController controller;
  final VoidCallback onOpenCart;

  const CartScope({
    super.key,
    required this.controller,
    required this.onOpenCart,
    required super.child,
  });

  static CartScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartScope>();

  @override
  bool updateShouldNotify(CartScope oldWidget) =>
      controller != oldWidget.controller || onOpenCart != oldWidget.onOpenCart;
}
