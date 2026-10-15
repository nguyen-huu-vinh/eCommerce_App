import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart'; // sửa đường dẫn cho khớp vị trí file product.dart
import '../models/product_category.dart';

// Trùng với baseUrl trong auth_service.dart; đổi cả hai nếu bạn đổi địa chỉ server
const String _baseUrl = 'https://stylish-backend-lyrx.onrender.com';

class ProductException implements Exception {
  final String message;
  ProductException(this.message);

  @override
  String toString() => message;
}

class ProductService {
  // Render gói free có thể mất ~1 phút để "thức dậy"
  static const _timeout = Duration(seconds: 70);

  // Danh sách đã tải được giữ lại một lúc để các màn mở lại hiện ngay,
  // và nhiều màn cùng gọi một API thì chỉ gửi đúng một request.
  static const _cacheDuration = Duration(minutes: 5);
  static final Map<Uri, (DateTime, Future<List<Product>>)> _listCache = {};

  /// Xóa dữ liệu đã lưu tạm, dùng khi người dùng kéo xuống để tải lại.
  static void clearCache() => _listCache.clear();

  /// Sản phẩm thường, có thể lọc theo danh mục.
  static Future<List<Product>> fetchProducts({String? category}) {
    final uri = Uri.parse('$_baseUrl/products');
    return _getList(
      category == null
          ? uri
          : uri.replace(queryParameters: {'category': category}),
    );
  }

  static Future<List<ProductCategory>> fetchCategories() async {
    final response = await http
        .get(Uri.parse('$_baseUrl/categories'))
        .timeout(_timeout);
    if (response.statusCode != 200) {
      throw ProductException(
        'Không thể tải danh mục (mã ${response.statusCode})',
      );
    }
    final categories = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return categories
        .map((item) => ProductCategory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Sản phẩm trending (GET /trending)
  static Future<List<Product>> fetchTrending() =>
      _getList(Uri.parse('$_baseUrl/trending'));

  /// Sản phẩm Deal of the Day được chọn riêng trong admin.
  static Future<List<Product>> fetchDealsOfTheDay() =>
      _getList(Uri.parse('$_baseUrl/deals-of-the-day'));

  /// Sản phẩm mới được đánh dấu "New" trong admin.
  static Future<List<Product>> fetchNewArrivals() =>
      _getList(Uri.parse('$_baseUrl/new-arrivals'));

  /// Một sản phẩm theo id (GET /products/{id})
  static Future<Product> fetchProduct(int id) async {
    final res = await http
        .get(Uri.parse('$_baseUrl/products/$id'))
        .timeout(_timeout);

    if (res.statusCode == 404) {
      throw ProductException('Không tìm thấy sản phẩm');
    }
    if (res.statusCode != 200) {
      throw ProductException('Có lỗi xảy ra (mã ${res.statusCode})');
    }
    return Product.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  static Future<List<Product>> _getList(Uri uri) {
    final cached = _listCache[uri];
    if (cached != null &&
        DateTime.now().difference(cached.$1) < _cacheDuration) {
      return cached.$2;
    }
    final future = _fetchList(uri);
    _listCache[uri] = (DateTime.now(), future);
    // Lỗi thì không giữ lại, lần sau sẽ thử tải lại
    future.catchError((Object _) {
      if (_listCache[uri]?.$2 == future) _listCache.remove(uri);
      return const <Product>[];
    });
    return future;
  }

  static Future<List<Product>> _fetchList(Uri uri) async {
    // Render vừa "thức dậy" hay mạng chập chờn thường lỗi ngay lần đầu:
    // thử lại vài lần trước khi báo lỗi cho người dùng
    const maxAttempts = 3;
    for (var attempt = 1; ; attempt++) {
      try {
        final res = await http.get(uri).timeout(_timeout);
        if (res.statusCode >= 500 && attempt < maxAttempts) {
          await Future<void>.delayed(Duration(seconds: 2 * attempt));
          continue;
        }
        if (res.statusCode != 200) {
          throw ProductException('Có lỗi xảy ra (mã ${res.statusCode})');
        }
        final list = jsonDecode(utf8.decode(res.bodyBytes)) as List;
        return list
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      } on ProductException {
        rethrow;
      } catch (_) {
        // Hết thời gian chờ 70s đã đủ lâu, không đợi thêm lần nữa
        if (attempt >= maxAttempts) rethrow;
        await Future<void>.delayed(Duration(seconds: 2 * attempt));
      }
    }
  }
}
