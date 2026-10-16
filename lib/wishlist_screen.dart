import 'widgets/empty_state.dart';
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/product.dart';
import 'services/wishlist_controller.dart';
import 'utils/currency.dart';
import 'widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  final VoidCallback? onBack;

  const WishlistScreen({super.key, this.onBack});

  static const _pink = Color(0xFFFE3E6C);

  String? _discountLabel(Product product) {
    final discountPrice = product.discountPrice;
    if (discountPrice == null || discountPrice >= product.price) return null;
    final percent = ((product.price - discountPrice) / product.price * 100)
        .round();
    return '-$percent%';
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistController.instance;
    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: AppBar(
        backgroundColor: context.colors.page,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: onBack == null
            ? null
            : IconButton(
                tooltip: 'Quay lại',
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: context.colors.textPrimary,
                ),
              ),
        centerTitle: true,
        title: Text(
          'Yêu thích',
          style: GoogleFonts.montserrat(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: wishlist,
        builder: (context, _) {
          final products = wishlist.items;
          if (products.isEmpty) return _buildEmpty(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  '${products.length} sản phẩm',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: MasonryGridView.count(
                  // Chừa chỗ cho thanh điều hướng nổi ở dưới
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 116),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    final hasReducedPrice =
                        product.discountPrice != null &&
                        product.discountPrice! < product.price;
                    return Stack(
                      children: [
                        ProductCard(
                          title: product.name,
                          description: product.description,
                          price: formatVnd(
                            hasReducedPrice
                                ? product.discountPrice!
                                : product.price,
                          ),
                          originalPrice: hasReducedPrice
                              ? formatVnd(product.price)
                              : null,
                          discount: _discountLabel(product),
                          image: product.imageUrl,
                          id: product.id,
                          product: product,
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Material(
                            color: context.colors.surface,
                            shape: CircleBorder(),
                            elevation: 1,
                            child: IconButton(
                              tooltip: 'Bỏ yêu thích',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => wishlist.remove(product.id),
                              icon: Icon(
                                Icons.favorite,
                                color: _pink,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) => EmptyState(
    icon: Icons.favorite_border_rounded,
    title: 'Chưa có sản phẩm yêu thích',
    message: 'Bấm vào trái tim ở trang sản phẩm để lưu lại món bạn thích',
    actionLabel: 'Khám phá sản phẩm',
    onAction: onBack ?? () => Navigator.maybePop(context),
  );
}
