import 'package:flutter/material.dart';

import 'product_list_screen.dart';
import 'services/product_service.dart';

class CategoryProductsScreen extends StatelessWidget {
  final String category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final wanted = category.trim().toLowerCase();
    return ProductListScreen(
      title: category,
      searchHint: 'Tìm trong $category...',
      errorText: 'Không thể tải danh sách sản phẩm. Vui lòng thử lại.',
      emptyText: 'Chưa có sản phẩm nào trong danh mục này.',
      countLabel: (n) => '$n sản phẩm',
      loader: () async =>
          (await ProductService.fetchProducts(category: category))
              .where((p) => p.category?.trim().toLowerCase() == wanted)
              .toList(),
    );
  }
}
