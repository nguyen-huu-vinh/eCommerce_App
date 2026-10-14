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

/// Việc mà nơi khác (VD trang chủ) muốn màn Search làm khi mở ra
enum SearchAction { focus, sort, filter }

/// Kênh gửi yêu cầu cho màn Search. Gửi cùng một việc 2 lần vẫn được xử lý
/// (ValueNotifier thì bỏ qua nếu giá trị không đổi).
class SearchRequests extends ChangeNotifier {
  SearchAction? last;

  void send(SearchAction action) {
    last = action;
    notifyListeners();
  }
}

enum _SortOption {
  relevance('Mặc định'),
  priceAsc('Giá thấp đến cao'),
  priceDesc('Giá cao đến thấp'),
  discount('Giảm giá nhiều nhất'),
  nameAsc('Tên A → Z');

  const _SortOption(this.label);
  final String label;
}

double _salePrice(Product p) {
  final discount = p.discountPrice;
  return discount != null && discount < p.price ? discount : p.price;
}

double _discountRatio(Product p) => 1 - _salePrice(p) / p.price;

class SearchScreen extends StatefulWidget {
  final SearchRequests? requests;

  const SearchScreen({super.key, this.requests});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  _SortOption _sort = _SortOption.relevance;
  final Set<String> _categories = {};
  bool _onlySale = false;
  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    widget.requests?.addListener(_handleRequest);
    _loadProducts();
  }

  @override
  void dispose() {
    widget.requests?.removeListener(_handleRequest);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _handleRequest() {
    final action = widget.requests?.last;
    // Đợi tab Search hiện lên rồi mới mở bàn phím / bảng chọn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (action) {
        case SearchAction.focus:
          _searchFocus.requestFocus();
        case SearchAction.sort:
          _openSortSheet();
        case SearchAction.filter:
          _openFilterSheet();
        case null:
          break;
      }
    });
    // Yêu cầu vẽ khung hình kế tiếp để việc trên chắc chắn chạy, kể cả khi
    // đang đứng sẵn ở tab Search (không có gì khác thay đổi trên màn hình)
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  int get _activeFilterCount => _categories.length + (_onlySale ? 1 : 0);

  bool get _isFiltering =>
      _searchController.text.trim().isNotEmpty || _activeFilterCount > 0;

  /// Danh mục lấy ngay từ danh sách sản phẩm, không cần gọi thêm API
  List<String> get _availableCategories {
    final names = {
      for (final p in _products)
        if (p.category != null && p.category!.trim().isNotEmpty)
          p.category!.trim(),
    }.toList()..sort();
    return names;
  }

  Future<void> _openSortSheet() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<_SortOption>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetTitle('Sắp xếp theo'),
            for (final option in _SortOption.values)
              ListTile(
                title: Text(option.label),
                trailing: option == _sort
                    ? const Icon(Icons.check_rounded, color: _pink)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _sort = picked);
  }

  Future<void> _openFilterSheet() async {
    FocusScope.of(context).unfocus();
    final categories = _availableCategories;
    final selected = {..._categories};
    var onlySale = _onlySale;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetTitle('Lọc sản phẩm', padding: EdgeInsets.zero),
                const SizedBox(height: 14),
                Text(
                  'Danh mục',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (categories.isEmpty)
                  Text(
                    'Chưa có danh mục',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF888888),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final name in categories)
                        FilterChip(
                          label: Text(name),
                          selected: selected.contains(name),
                          selectedColor: const Color(0xFFFFE3E9),
                          checkmarkColor: _pink,
                          onSelected: (on) => setSheetState(
                            () =>
                                on ? selected.add(name) : selected.remove(name),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: _pink,
                  title: const Text('Chỉ sản phẩm đang giảm giá'),
                  value: onlySale,
                  onChanged: (v) => setSheetState(() => onlySale = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheetState(() {
                          selected.clear();
                          onlySale = false;
                        }),
                        child: const Text('Xóa lọc'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: _pink),
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text('Áp dụng'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _categories
          ..clear()
          ..addAll(selected);
        _onlySale = onlySale;
      });
    }
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
    final result = _products.where((product) {
      if (query.isNotEmpty && !_normalize(product.name).contains(query)) {
        return false;
      }
      if (_categories.isNotEmpty &&
          !_categories.contains(product.category?.trim())) {
        return false;
      }
      if (_onlySale && _salePrice(product) >= product.price) return false;
      return true;
    }).toList();

    switch (_sort) {
      case _SortOption.relevance:
        break;
      case _SortOption.priceAsc:
        result.sort((a, b) => _salePrice(a).compareTo(_salePrice(b)));
      case _SortOption.priceDesc:
        result.sort((a, b) => _salePrice(b).compareTo(_salePrice(a)));
      case _SortOption.discount:
        result.sort((a, b) => _discountRatio(b).compareTo(_discountRatio(a)));
      case _SortOption.nameAsc:
        result.sort((a, b) => _normalize(a.name).compareTo(_normalize(b.name)));
    }
    return result;
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
              focusNode: _searchFocus,
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
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isFiltering
                          ? '${products.length} kết quả'
                          : 'Tất cả sản phẩm (${products.length})',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  _ToolbarButton(
                    icon: Icons.swap_vert_rounded,
                    label: _sort == _SortOption.relevance
                        ? 'Sắp xếp'
                        : _sort.label,
                    active: _sort != _SortOption.relevance,
                    onTap: _openSortSheet,
                  ),
                  _ToolbarButton(
                    icon: Icons.filter_alt_outlined,
                    label: _activeFilterCount == 0
                        ? 'Lọc'
                        : 'Lọc ($_activeFilterCount)',
                    active: _activeFilterCount > 0,
                    onTap: _openFilterSheet,
                  ),
                ],
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
                    : _activeFilterCount > 0
                    ? 'Không có sản phẩm nào khớp bộ lọc'
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

const _pink = Color(0xFFFE3E6C);

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    style: TextButton.styleFrom(
      foregroundColor: active ? _pink : const Color(0xFF444444),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      visualDensity: VisualDensity.compact,
    ),
    icon: Icon(icon, size: 18),
    label: Text(
      label,
      style: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      ),
    ),
  );
}

class _SheetTitle extends StatelessWidget {
  final String text;
  final EdgeInsets padding;

  const _SheetTitle(
    this.text, {
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(
      text,
      style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );
}
