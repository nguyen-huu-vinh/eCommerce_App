import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/product.dart';

/// Danh sách sản phẩm yêu thích, lưu trên máy để mở lại app vẫn còn.
///
/// Dùng chung một bản ([instance]) cho cả trang chi tiết và tab Yêu thích.
class WishlistController extends ChangeNotifier {
  WishlistController._();

  static final WishlistController instance = WishlistController._();

  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'wishlist_items';

  // Giữ thứ tự thêm vào; LinkedHashMap mặc định của Dart
  final Map<int, Product> _items = {};

  /// Mới thêm gần nhất đứng đầu
  List<Product> get items => _items.values.toList().reversed.toList();

  bool contains(int productId) => _items.containsKey(productId);

  Future<void> load() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null) return;
      for (final entry in jsonDecode(raw) as List) {
        final product = Product.fromJson(entry as Map<String, dynamic>);
        _items.putIfAbsent(product.id, () => product);
      }
      notifyListeners();
    } catch (_) {
      await _storage.delete(key: _storageKey);
    }
  }

  /// Thêm nếu chưa có, bỏ nếu đã có. Trả về true khi vừa được thêm.
  bool toggle(Product product) {
    final added = _items.remove(product.id) == null;
    if (added) _items[product.id] = product;
    _changed();
    return added;
  }

  void remove(int productId) {
    if (_items.remove(productId) != null) _changed();
  }

  /// Xóa hết, cả trên máy. Dùng khi đăng xuất.
  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _storage.delete(key: _storageKey);
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  Future<void> _save() async {
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(_items.values.map((p) => p.toJson()).toList()),
      );
    } catch (_) {}
  }
}
