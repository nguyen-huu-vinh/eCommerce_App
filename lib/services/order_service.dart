import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/order.dart';
import 'auth_service.dart';
import 'cart_controller.dart';

class OrderException implements Exception {
  final String message;
  OrderException(this.message);

  @override
  String toString() => message;
}

/// Thông tin giao hàng, được nhớ lại cho lần đặt hàng sau
class ShippingInfo {
  final String fullName;
  final String phone;
  final String address;

  const ShippingInfo({
    required this.fullName,
    required this.phone,
    required this.address,
  });

  factory ShippingInfo.fromJson(Map<String, dynamic> json) => ShippingInfo(
    fullName: json['full_name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    address: json['address'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'phone': phone,
    'address': address,
  };
}

class OrderService {
  static const _storage = FlutterSecureStorage();
  static const _shippingKey = 'last_shipping_info';
  static const _timeout = Duration(seconds: 70);

  /// Gửi đơn hàng lên máy chủ.
  ///
  /// Chỉ gửi id, size, số lượng; backend tự tính giá từ database để
  /// người dùng không thể sửa giá từ phía app.
  static Future<Order> placeOrder({
    required List<CartItem> items,
    required ShippingInfo shipping,
    required String paymentMethod,
    String? note,
  }) async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw OrderException('Vui lòng đăng nhập để đặt hàng');
    }

    final res = await http
        .post(
          Uri.parse('$baseUrl/orders'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            ...shipping.toJson(),
            if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
            'payment_method': paymentMethod,
            'items': [
              for (final item in items)
                {
                  'product_id': item.product.id,
                  'size': item.size,
                  'quantity': item.quantity,
                },
            ],
          }),
        )
        .timeout(_timeout);

    if (res.statusCode == 401) {
      await AuthService.logout();
      throw OrderException(
        'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
      );
    }
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw OrderException(_errorMessage(res));
    }
    return Order.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Lịch sử đơn của người dùng đang đăng nhập, mới nhất trước
  static Future<List<Order>> fetchMyOrders() async {
    final token = await AuthService.getToken();
    if (token == null) {
      throw OrderException('Vui lòng đăng nhập để xem đơn hàng');
    }

    final res = await http
        .get(
          Uri.parse('$baseUrl/orders/me'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_timeout);

    if (res.statusCode == 401) {
      await AuthService.logout();
      throw OrderException(
        'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
      );
    }
    if (res.statusCode != 200) throw OrderException(_errorMessage(res));
    return (jsonDecode(utf8.decode(res.bodyBytes)) as List)
        .map((item) => Order.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Lấy lại một đơn để cập nhật trạng thái mới nhất
  static Future<Order> fetchOrder(int id) async {
    final res = await http
        .get(Uri.parse('$baseUrl/orders/$id'), headers: await _authHeaders())
        .timeout(_timeout);
    await _throwIfFailed(res);
    return Order.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  /// Khách tự hủy đơn khi đơn vẫn đang chờ xác nhận
  static Future<Order> cancelOrder(int id, {String? reason}) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/orders/$id/cancel'),
          headers: {
            ...await _authHeaders(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            if (reason != null && reason.trim().isNotEmpty)
              'reason': reason.trim(),
          }),
        )
        .timeout(_timeout);
    await _throwIfFailed(res);
    return Order.fromJson(
      jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>,
    );
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    if (token == null) throw OrderException('Vui lòng đăng nhập lại');
    return {'Authorization': 'Bearer $token'};
  }

  static Future<void> _throwIfFailed(http.Response res) async {
    if (res.statusCode == 401) {
      await AuthService.logout();
      throw OrderException(
        'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
      );
    }
    if (res.statusCode != 200) throw OrderException(_errorMessage(res));
  }

  static Future<ShippingInfo?> loadLastShipping() async {
    try {
      final raw = await _storage.read(key: _shippingKey);
      if (raw == null) return null;
      return ShippingInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearLastShipping() => _storage.delete(key: _shippingKey);

  static Future<void> saveLastShipping(ShippingInfo info) async {
    try {
      await _storage.write(key: _shippingKey, value: jsonEncode(info.toJson()));
    } catch (_) {}
  }

  static String _errorMessage(http.Response res) {
    try {
      final detail = jsonDecode(utf8.decode(res.bodyBytes))['detail'];
      // FastAPI trả "Not Found" khi server chưa có route /orders
      if (detail == 'Not Found') return 'Máy chủ chưa hỗ trợ đặt hàng';
      if (detail is String) return detail;
      if (res.statusCode == 422) return 'Thông tin đơn hàng không hợp lệ';
    } catch (_) {}
    return 'Có lỗi xảy ra (mã ${res.statusCode})';
  }
}
