import 'widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/product.dart';
import 'services/product_service.dart';
import 'widgets/product_card.dart';
import 'utils/currency.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String category;

  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ProductService.fetchProducts(
        category: widget.category,
      );
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
            : 'Không thể tải danh sách sản phẩm. Vui lòng thử lại.';
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    final category = widget.category.trim().toLowerCase();
    final query = _searchController.text.trim().toLowerCase();

    return _products.where((product) {
      final productCategory = product.category?.trim().toLowerCase();
      return productCategory == category &&
          product.name.toLowerCase().contains(query);
    }).toList();
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
          color: context.colors.textPrimary,
        ),
        title: Text(
          widget.category,
          style: GoogleFonts.montserrat(
            color: context.colors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
                hintText: 'Tìm trong ${widget.category}...',
                prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${products.length} sản phẩm',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(child: _buildContent(products)),
        ],
      ),
    );
  }

  Widget _buildContent(List<Product> products) {
    if (_isLoading) {
      return const ProductGridSkeleton();
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: _loadProducts,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    if (products.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            _searchController.text.isEmpty
                ? 'Danh mục này chưa có sản phẩm.'
                : 'Không tìm thấy sản phẩm phù hợp.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 14,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () {
        ProductService.clearCache();
        return _loadProducts();
      },
      color: const Color(0xFFFE3E6C),
      child: MasonryGridView.count(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(
            title: product.name,
            description: product.description,
            price: formatVnd(product.price),
            originalPrice: product.originalPrice == null
                ? null
                : formatVnd(product.originalPrice!),
            rating: product.rating,
            ratingCount: product.ratingCount,
            image: product.imageUrl,
            id: product.id,
            product: product,
          );
        },
      ),
    );
  }
}
