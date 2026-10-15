import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Các từ khóa tìm kiếm gần đây, lưu trên máy (mới nhất trước).
class SearchHistory {
  static const _storage = FlutterSecureStorage();
  static const _key = 'search_history';
  static const maxItems = 10;

  static Future<List<String>> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null) return [];
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return [];
    }
  }

  /// Thêm từ khóa lên đầu; trùng (không phân biệt hoa thường) thì chỉ đưa lên đầu.
  static Future<List<String>> add(String query) async {
    final term = query.trim();
    if (term.length < 2) return load();
    final items = await load();
    items.removeWhere((e) => e.toLowerCase() == term.toLowerCase());
    items.insert(0, term);
    if (items.length > maxItems) items.removeRange(maxItems, items.length);
    return _save(items);
  }

  static Future<List<String>> remove(String query) async {
    final items = await load()
      ..removeWhere((e) => e.toLowerCase() == query.toLowerCase());
    return _save(items);
  }

  static Future<List<String>> clear() => _save([]);

  static Future<List<String>> _save(List<String> items) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(items));
    } catch (_) {}
    return items;
  }
}
