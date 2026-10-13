import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/product.dart';
import 'services/product_service.dart';
import 'utils/currency.dart';
import 'widgets/product_card.dart';

const _accented =
    'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
final _plain =
    '${'a' * 17}${'e' * 11}${'i' * 5}${'o' * 17}${'u' * 11}${'y' * 5}d';

/// Chữ thường, bỏ dấu tiếng Việt: gõ "ao thun" vẫn tìm ra "Áo thun"
String _normalize(String text) {
  final buffer = StringBuffer();
  for (final char in text.toLowerCase().split('')) {
    final index = _accented.indexOf(char);
    buffer.write(index == -1 ? char : _plain[index]);
  }
  return buffer.toString().trim();
}

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
      _isLoading = _products.isEmpty;
      _errorMessage = null;
    });

    try {
      final products = await ProductService.fetchProducts();
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
    final query = _normalize(_searchController.text);
    if (query.isEmpty) return _products;
    return _products
        .where((product) => _normalize(product.name).contains(query))
        .toList();
  }

  String? _discountLabel(Product product) {
    final discountPrice = product.discountPrice;
    if (discountPrice == null || discountPrice >= product.price) return null;
    final percent = ((product.price - discountPrice) / product.price * 100)
        .round();
    return percent > 0 ? '$percent% Off' : null;
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;
    final hasQuery = _searchController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F9),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Tìm kiếm',
          style: GoogleFonts.montserrat(
            color: Colors.black,
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
              textInputAction: TextInputAction.search,
              style: GoogleFonts.montserrat(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm theo tên...',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFFBBBBBB),
                ),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF626262)),
                suffixIcon: hasQuery
                    ? IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: _searchController.clear,
                        icon: const Icon(Icons.close),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          if (!_isLoading && _errorMessage == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  hasQuery
                      ? '${products.length} kết quả'
                      : 'Tất cả sản phẩm (${products.length})',
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          Expanded(child: _buildContent(products, hasQuery)),
        ],
      ),
    );
  }

  Widget _buildContent(List<Product> products, bool hasQuery) {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.search_off_rounded,
                size: 54,
                color: Color(0xFFB8B8B8),
              ),
              const SizedBox(height: 12),
              Text(
                hasQuery
                    ? 'Không tìm thấy sản phẩm nào cho "${_searchController.text.trim()}"'
                    : 'Cửa hàng chưa có sản phẩm.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF808488),
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
        return _loadProducts();
      },
      color: const Color(0xFFFE3E6C),
      child: MasonryGridView.count(
        // Chừa chỗ cho thanh điều hướng nổi ở dưới
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 116),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
