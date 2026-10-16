import 'package:flutter/material.dart';

import 'product_list_screen.dart';
import 'services/product_service.dart';

class TrendingProductsScreen extends StatelessWidget {
  final ScrollController? scrollController;
  final VoidCallback? onBack;

  const TrendingProductsScreen({super.key, this.scrollController, this.onBack});

  @override
  Widget build(BuildContext context) => ProductListScreen(
    title: 'Sản phẩm nổi bật',
    searchHint: 'Tìm sản phẩm nổi bật...',
    icon: Icons.local_fire_department_outlined,
    errorText: 'Không thể tải sản phẩm nổi bật. Vui lòng thử lại.',
    emptyText: 'Hiện chưa có sản phẩm nổi bật.',
    countLabel: (n) => '$n sản phẩm nổi bật',
    loader: ProductService.fetchTrending,
    scrollController: scrollController,
    onBack: onBack,
    bottomPadding: 20,
  );
}
