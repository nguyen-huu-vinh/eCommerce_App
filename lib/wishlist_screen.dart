import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/product.dart';
import 'services/wishlist_controller.dart';
import 'utils/currency.dart';
import 'widgets/product_card.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

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
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'Yêu thích',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: wishlist,
        builder: (context, _) {
          final products = wishlist.items;
          if (products.isEmpty) return _buildEmpty();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 116),
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
                            color: Colors.white,
                            shape: const CircleBorder(),
                            elevation: 1,
                            child: IconButton(
                              tooltip: 'Bỏ yêu thích',
                              visualDensity: VisualDensity.compact,
                              onPressed: () => wishlist.remove(product.id),
                              icon: const Icon(
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

  Widget _buildEmpty() => Center(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 116),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.favorite_border_rounded,
            size: 58,
            color: Color(0xFFB8B8B8),
          ),
          const SizedBox(height: 14),
          Text(
            'Chưa có sản phẩm yêu thích',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF303030),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Bấm vào trái tim ở trang sản phẩm để lưu lại món bạn thích',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    ),
  );
}
