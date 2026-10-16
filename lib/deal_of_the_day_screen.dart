import 'package:flutter/material.dart';

import 'product_list_screen.dart';
import 'services/product_service.dart';

class DealOfTheDayScreen extends StatelessWidget {
  const DealOfTheDayScreen({super.key});

  @override
  Widget build(BuildContext context) => ProductListScreen(
    title: 'Deal of the Day',
    searchHint: 'Tìm Deal of the Day...',
    icon: Icons.local_offer_outlined,
    errorText: 'Không thể tải Deal of the Day. Vui lòng thử lại.',
    emptyText: 'Hiện chưa có Deal of the Day.',
    countLabel: (n) => '$n ưu đãi trong ngày',
    loader: () async => (await ProductService.fetchDealsOfTheDay())
        .where((product) => product.isDealOfTheDay)
        .toList(),
    bottomPadding: 20,
  );
}
