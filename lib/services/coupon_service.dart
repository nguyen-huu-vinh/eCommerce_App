import 'api_client.dart';

class CouponResult {
  final String code;
  final String? description;
  final double discount;

  const CouponResult({
    required this.code,
    required this.description,
    required this.discount,
  });
}

class CouponService {
  /// Kiểm tra mã với tạm tính hiện tại; ném [ApiException] nếu mã không dùng được
  static Future<CouponResult> validate(String code, double subtotal) async {
    final json = await apiCall(
      'POST',
      '/coupons/validate',
      body: {'code': code.trim(), 'subtotal': subtotal},
    ) as Map<String, dynamic>;
    return CouponResult(
      code: json['code'] as String,
      description: json['description'] as String?,
      discount: (json['discount'] as num).toDouble(),
    );
  }
}
