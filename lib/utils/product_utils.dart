import '../models/product.dart';

/// Phần trăm giảm giá làm tròn, null nếu sản phẩm không giảm.
int? discountPercent(Product product) {
  final discountPrice = product.discountPrice;
  if (discountPrice == null || discountPrice >= product.price) return null;
  final percent = ((product.price - discountPrice) / product.price * 100)
      .round();
  return percent > 0 ? percent : null;
}

/// Nhãn giảm giá hiện trên thẻ sản phẩm, ví dụ "-20%".
String? discountLabel(Product product) {
  final percent = discountPercent(product);
  return percent == null ? null : '-$percent%';
}
