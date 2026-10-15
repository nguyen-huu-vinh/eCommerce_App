import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/product.dart';
import 'services/product_service.dart';
import 'widgets/product_card.dart';
import 'utils/currency.dart';

class DiscountedProductsScreen extends StatefulWidget {
  final String title;

  /// Chỉ lấy sản phẩm giảm tối đa bấy nhiêu %, ví dụ 50 cho "up to 50% Off".
  /// Để null thì lấy mọi sản phẩm đang giảm giá.
  final int? maxDiscountPercent;

  const DiscountedProductsScreen({
    super.key,
    this.title = 'Ưu đãi trong ngày',
    this.maxDiscountPercent,
  });

  @override
  State<DiscountedProductsScreen> createState() =>
      _DiscountedProductsScreenState();
}

class _DiscountedProductsScreenState extends State<DiscountedProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadDiscountedProducts();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> _loadDiscountedProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final allProducts = await ProductService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = allProducts.where(_hasDiscount).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ProductException
            ? error.message
            : 'Không thể tải sản phẩm giảm giá. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  bool _hasDiscount(Product product) {
    final maxPercent = widget.maxDiscountPercent;
    if (maxPercent != null) {
      final percent = _discountPercent(product);
      return percent != null && percent <= maxPercent;
    }
    final discountedPrice = product.discountPrice;
    return product.isSale ||
        (discountedPrice != null && discountedPrice < product.price);
  }

  int? _discountPercent(Product product) {
    final discountedPrice = product.discountPrice;
    if (discountedPrice == null || discountedPrice >= product.price) {
      return null;
    }
    final percent = ((product.price - discountedPrice) / product.price * 100)
        .round();
    return percent > 0 ? percent : null;
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products
        .where((product) => product.name.toLowerCase().contains(query))
        .toList();
  }

  String? _discountLabel(Product product) {
    final percent = _discountPercent(product);
    return percent == null ? null : '-$percent%';
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: AppBar(
        backgroundColor: context.colors.page,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: Color(0xFF222222),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.montserrat(
            color: context.colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.montserrat(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm ưu đãi...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.colors.textSecondary,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: context.colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: Color(0xFFFE3E6C),
                  size: 19,
                ),
                SizedBox(width: 8),
                Text(
                  '${products.length} sản phẩm giảm giá',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildContent(products)),
        ],
      ),
    );
  }

  Widget _buildContent(List<Product> products) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFE3E6C)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(fontSize: 14),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _loadDiscountedProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sell_outlined,
                size: 44,
                color: Color(0xFFB1B1B1),
              ),
              SizedBox(height: 12),
              Text(
                _searchController.text.isEmpty
                    ? 'Hiện chưa có sản phẩm giảm giá.'
                    : 'Không tìm thấy sản phẩm phù hợp.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        ProductService.clearCache();
        return _loadDiscountedProducts();
      },
      color: const Color(0xFFFE3E6C),
      child: MasonryGridView.count(
        // Chừa chỗ cho thanh điều hướng nổi ở dưới
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 116),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final hasReducedPrice =
              product.discountPrice != null &&
              product.discountPrice! < product.price;
          return ProductCard(
            title: product.name,
            description: product.description,
            price: formatVnd(
              hasReducedPrice ? product.discountPrice! : product.price,
            ),
            originalPrice: hasReducedPrice ? formatVnd(product.price) : null,
            discount: _discountLabel(product),
            image: product.imageUrl,
            id: product.id,
            product: product,
          );
        },
      ),
    );
  }
}
