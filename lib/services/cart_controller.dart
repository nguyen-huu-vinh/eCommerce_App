import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/product.dart';

class CartItem {
  final Product product;
  final String? size;
  final int quantity;

  const CartItem({required this.product, this.size, this.quantity = 1});

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: Product.fromJson(json['product'] as Map<String, dynamic>),
    size: json['size'] as String?,
    quantity: json['quantity'] as int,
  );

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'size': size,
    'quantity': quantity,
  };

  String get key => '${product.id}:${size ?? ''}';

  CartItem withQuantity(int value) =>
      CartItem(product: product, size: size, quantity: value);

  /// Giá bán thực tế: dùng giá giảm nếu có và thấp hơn giá gốc
  double get unitPrice {
    final discount = product.discountPrice;
    return discount != null && discount < product.price
        ? discount
        : product.price;
  }

  bool get isDiscounted => unitPrice < product.price;

  double get lineTotal => unitPrice * quantity;
}

class CartController extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'cart_items';

  final Map<String, CartItem> _items = {};

  List<CartItem> get items => List.unmodifiable(_items.values);

  int get itemCount =>
      _items.values.fold(0, (total, item) => total + item.quantity);

  double get subtotal =>
      _items.values.fold(0, (total, item) => total + item.lineTotal);

  /// Xóa giỏ đã lưu trên máy (khi đăng xuất), để người sau không thấy
  static Future<void> clearSaved() => _storage.delete(key: _storageKey);

  /// Khôi phục giỏ hàng đã lưu từ lần mở app trước
  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null) return;
      for (final entry in jsonDecode(raw) as List) {
        final item = CartItem.fromJson(entry as Map<String, dynamic>);
        // Không ghi đè món người dùng vừa thêm trong lúc đang tải
        _items.putIfAbsent(item.key, () => item);
      }
      notifyListeners();
    } catch (_) {
      // Dữ liệu cũ hỏng hoặc khác định dạng: bỏ đi
      await _storage.delete(key: _storageKey);
    }
  }

  void add(Product product, String? size) {
    final item = CartItem(product: product, size: size);
    final existing = _items[item.key];
    _items[item.key] = item.withQuantity((existing?.quantity ?? 0) + 1);
    _changed();
  }

  void setQuantity(CartItem item, int quantity) {
    if (quantity <= 0) {
      _items.remove(item.key);
    } else {
      _items[item.key] = item.withQuantity(quantity);
    }
    _changed();
  }

  void remove(CartItem item) {
    _items.remove(item.key);
    _changed();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(_items.values.map((item) => item.toJson()).toList()),
      );
    } catch (_) {
      // Lưu thất bại thì giỏ hàng vẫn dùng được trong phiên hiện tại
    }
  }
}
