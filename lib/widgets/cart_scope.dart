import 'package:flutter/widgets.dart';

import '../search_screen.dart';
import '../services/cart_controller.dart';

class CartScope extends InheritedWidget {
  final CartController controller;
  final VoidCallback onOpenCart;

  /// Chuyển sang tab Search và mở bàn phím / bảng sắp xếp / bảng lọc
  final ValueChanged<SearchAction>? onOpenSearch;

  const CartScope({
    super.key,
    required this.controller,
    required this.onOpenCart,
    this.onOpenSearch,
    required super.child,
  });

  static CartScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartScope>();

  @override
  bool updateShouldNotify(CartScope oldWidget) =>
      controller != oldWidget.controller ||
      onOpenCart != oldWidget.onOpenCart ||
      onOpenSearch != oldWidget.onOpenSearch;
}
