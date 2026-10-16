import 'package:flutter/material.dart';

import 'models/product.dart';
import 'product_list_screen.dart';
import 'services/product_service.dart';
import 'utils/product_utils.dart';

class DiscountedProductsScreen extends StatelessWidget {
  final String title;

  /// Chỉ lấy sản phẩm giảm tối đa bấy nhiêu %, ví dụ 50 cho "up to 50% Off".
  /// Để null thì lấy mọi sản phẩm đang giảm giá.
  final int? maxDiscountPercent;

  const DiscountedProductsScreen({
    super.key,
    this.title = 'Ưu đãi trong ngày',
    this.maxDiscountPercent,
  });

  bool _hasDiscount(Product product) {
    final maxPercent = maxDiscountPercent;
    if (maxPercent != null) {
      final percent = discountPercent(product);
      return percent != null && percent <= maxPercent;
    }
    final discountedPrice = product.discountPrice;
    return product.isSale ||
        (discountedPrice != null && discountedPrice < product.price);
  }

  @override
  Widget build(BuildContext context) => ProductListScreen(
    title: title,
    searchHint: 'Tìm sản phẩm ưu đãi...',
    icon: Icons.local_offer_outlined,
    errorText: 'Không thể tải sản phẩm giảm giá. Vui lòng thử lại.',
    emptyText: 'Hiện chưa có sản phẩm giảm giá.',
    countLabel: (n) => '$n sản phẩm giảm giá',
    loader: () async =>
        (await ProductService.fetchProducts()).where(_hasDiscount).toList(),
  );
}
