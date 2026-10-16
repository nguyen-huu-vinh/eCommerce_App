import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/product.dart';
import 'services/product_service.dart';
import 'theme/app_theme.dart';
import 'utils/currency.dart';
import 'utils/product_utils.dart';
import 'widgets/product_card.dart';
import 'widgets/skeleton.dart';

/// Trang danh sách sản phẩm dạng lưới có ô tìm nhanh, tải lại và các trạng
/// thái đang tải / lỗi / trống. Các trang như Mới về, Giảm giá, Danh mục chỉ
/// khác nhau ở cấu hình truyền vào, không viết lại giao diện.
class ProductListScreen extends StatefulWidget {
  final String title;
  final String searchHint;

  /// Biểu tượng cạnh số lượng và ở màn hình trống; null thì chỉ hiện chữ.
  final IconData? icon;
  final String errorText;
  final String emptyText;
  final String Function(int count) countLabel;

  /// Lấy (và lọc) danh sách sản phẩm của trang.
  final Future<List<Product>> Function() loader;

  /// Chừa chỗ cho thanh điều hướng nổi ở dưới khi trang nằm trong tab.
  final double bottomPadding;
  final ScrollController? scrollController;

  /// Gọi khi bấm back mà không còn trang nào để quay lại (trang là gốc của tab).
  final VoidCallback? onBack;

  const ProductListScreen({
    super.key,
    required this.title,
    required this.searchHint,
    required this.errorText,
    required this.emptyText,
    required this.countLabel,
    required this.loader,
    this.icon,
    this.bottomPadding = 116,
    this.scrollController,
    this.onBack,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final products = await widget.loader();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ProductException
            ? error.message
            : widget.errorText;
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _products
        .where((product) => product.name.toLowerCase().contains(query))
        .toList();
  }

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      widget.onBack?.call();
    }
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
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: context.colors.textPrimary,
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
                hintText: widget.searchHint,
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
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: brandPink, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.countLabel(products.length),
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
    if (_isLoading) return const ProductGridSkeleton();

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
                onPressed: _load,
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
              Icon(
                widget.icon ?? Icons.search_off_rounded,
                size: 44,
                color: context.colors.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                _searchController.text.isEmpty
                    ? widget.emptyText
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
        return _load();
      },
      color: brandPink,
      child: MasonryGridView.count(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(16, 4, 16, widget.bottomPadding),
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
            discount: discountLabel(product),
            image: product.imageUrl,
            id: product.id,
            product: product,
          );
        },
      ),
    );
  }
}
