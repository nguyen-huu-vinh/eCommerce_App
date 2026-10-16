import 'package:flutter/material.dart';

import 'product_list_screen.dart';
import 'services/product_service.dart';

class NewArrivalsScreen extends StatelessWidget {
  const NewArrivalsScreen({super.key});

  @override
  Widget build(BuildContext context) => ProductListScreen(
    title: 'New Arrivals',
    searchHint: 'Tìm sản phẩm mới...',
    icon: Icons.new_releases_outlined,
    errorText: 'Không thể tải sản phẩm mới. Vui lòng thử lại.',
    emptyText: 'Hiện chưa có sản phẩm mới.',
    countLabel: (n) => '$n sản phẩm mới',
    loader: () async => (await ProductService.fetchNewArrivals())
        .where((product) => product.isNew)
        .toList(),
  );
}
