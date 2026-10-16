import 'package:flutter/services.dart';
import 'utils/fly_to_cart.dart';
import 'widgets/image_viewer.dart';
import 'widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'widgets/bouncing_button.dart';
import 'models/product.dart'; // sửa đường dẫn cho khớp vị trí file product.dart
import 'services/product_service.dart'; // sửa đường dẫn cho khớp vị trí file product_service.dart
import 'widgets/cart_scope.dart';
import 'widgets/review_section.dart';
import 'checkout_screen.dart';
import 'utils/network_image.dart';
import 'services/wishlist_controller.dart';
import 'utils/currency.dart';

/// Trang chi tiết sản phẩm dùng chung cho mọi sản phẩm.
///
/// Chỉ cần truyền [productId]. Nếu đã có sẵn dữ liệu từ danh sách thì truyền
/// thêm [initialProduct] để trang hiện ngay, rồi tự làm mới từ backend.
class ProductDetailScreen extends StatefulWidget {
  final int productId;
  final Product? initialProduct;

  /// Nối với giỏ hàng / thanh toán sau này. Để null thì chỉ hiện thông báo tạm
  final void Function(Product product, String? size)? onGoToCart;
  final void Function(Product product, String? size)? onBuyNow;

  /// Cùng tag với ảnh ở thẻ sản phẩm để ảnh bay mượt sang trang này
  final String? heroTag;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.initialProduct,
    this.onGoToCart,
    this.onBuyNow,
    this.heroTag,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  static const _pink = Color(0xFFFE3E6C);
  static const _sizePink = Color(0xFFFA7189);

  final PageController _pageController = PageController();
  final GlobalKey _galleryKey = GlobalKey();
  final GlobalKey _cartKey = GlobalKey();
  double _cartScale = 1;

  Product? _product;
  List<Product> _similar = [];
  bool _isLoading = false;
  String? _error;

  int _selectedSizeIndex = 0;
  int _quantity = 1;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _product = widget.initialProduct;
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading =
          _product == null; // đã có dữ liệu sẵn thì không hiện vòng tải
      _error = null;
    });

    try {
      final product = await ProductService.fetchProduct(widget.productId);
      if (!mounted) return;
      setState(() => _product = product);
    } catch (e) {
      if (!mounted) return;
      // Chỉ báo lỗi khi chưa có gì để hiển thị
      if (_product == null) {
        setState(
          () => _error = e is ProductException
              ? e.message
              : 'Không kết nối được máy chủ, vui lòng thử lại',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    _loadSimilar();
  }

  // Mục "Similar To": lấy các sản phẩm khác, lỗi thì bỏ qua âm thầm
  Future<void> _loadSimilar() async {
    try {
      final products = await ProductService.fetchProducts();
      final all = products
          .where((p) => p.id != widget.productId)
          .take(8)
          .toList();
      if (!mounted) return;
      setState(() => _similar = all);
    } catch (_) {}
  }

  void _showMessage(String message) {
    // Bấm liên tục thì thay thông báo cũ, không xếp hàng chờ
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // Server đã trả size mặc định cho sản phẩm cũ; rỗng = không có size
  List<String> get _sizes => _product?.sizes ?? <String>[];

  /// Kiểm tra trước khi thêm vào giỏ: hết hàng hoặc đã đủ số lượng trong kho
  bool _addToCart(CartScope scope) {
    final product = _product!;
    if (!product.inStock) {
      _showMessage('Sản phẩm này đã hết hàng');
      return false;
    }
    var added = 0;
    for (var i = 0; i < _quantity; i++) {
      if (!scope.controller.add(product, _selectedSize)) break;
      added++;
    }
    if (added == 0) {
      _showMessage(
        'Giỏ hàng đã có đủ ${product.stock} sản phẩm còn lại trong kho',
      );
      return false;
    }
    if (mounted) setState(() => _quantity = 1);
    HapticFeedback.lightImpact();
    return true;
  }

  String? get _selectedSize {
    final sizes = _sizes;
    if (sizes.isEmpty) return null;
    return sizes[_selectedSizeIndex.clamp(0, sizes.length - 1)];
  }

  void _goToCart() {
    final callback = widget.onGoToCart;
    if (callback != null) {
      callback(_product!, _selectedSize);
      return;
    }
    final scope = CartScope.maybeOf(context);
    if (scope == null) {
      _showMessage('Không thể mở giỏ hàng');
      return;
    }
    if (!_addToCart(scope)) return;
    _flyToCartIcon();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Đã thêm vào giỏ hàng'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Xem giỏ',
            textColor: const Color(0xFFFF8DA8),
            onPressed: scope.onOpenCart,
          ),
        ),
      );
  }

  Rect? _rectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// Ảnh sản phẩm bay vào icon giỏ hàng rồi icon nảy lên một nhịp
  void _flyToCartIcon() {
    final product = _product;
    final target = _rectOf(_cartKey);
    if (product == null || target == null) return;
    final screen = MediaQuery.sizeOf(context);
    final source = _rectOf(_galleryKey);
    // Ảnh đã cuộn khuất khỏi màn hình thì cho bay từ giữa màn hình
    final center = source == null
        ? Offset(screen.width / 2, screen.height * 0.6)
        : Offset(
            source.center.dx,
            source.center.dy.clamp(120.0, screen.height - 160),
          );
    flyToCart(
      context: context,
      from: Rect.fromCenter(center: center, width: 90, height: 90),
      to: target,
      image: cachedImage(product.gallery.first, width: 1080),
      onDone: () {
        if (!mounted) return;
        HapticFeedback.mediumImpact();
        setState(() => _cartScale = 1.3);
        Future.delayed(const Duration(milliseconds: 160), () {
          if (mounted) setState(() => _cartScale = 1);
        });
      },
    );
  }

  void _buyNow() {
    final callback = widget.onBuyNow;
    if (callback == null) {
      final scope = CartScope.maybeOf(context);
      if (scope == null) {
        _showMessage('Không thể mở trang thanh toán');
        return;
      }
      if (!_product!.inStock) {
        _showMessage('Sản phẩm này đã hết hàng');
        return;
      }
      // Đã đủ số lượng trong giỏ thì vẫn sang thanh toán với giỏ hiện có
      _addToCart(scope);
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => CheckoutScreen(controller: scope.controller),
        ),
      );
      return;
    }
    callback(_product!, _selectedSize);
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;

    return Scaffold(
      backgroundColor: context.colors.page,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: product != null
                  ? _buildContent(product)
                  : _isLoading
                  ? const _DetailSkeleton()
                  : _buildError(),
            ),
          ],
        ),
      ),
    );
  }

  // 1. TOP BAR (BACK & CART)
  Widget _buildTopBar() {
    Widget circle(
      IconData icon,
      VoidCallback onTap, {
      Color? color,
    }) => BouncingButton(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: color ?? context.colors.textPrimary),
      ),
    );
    final wishlist = WishlistController.instance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          circle(Icons.arrow_back_ios_new, () => Navigator.maybePop(context)),
          Row(
            children: [
              ListenableBuilder(
                listenable: wishlist,
                builder: (context, _) {
                  final product = _product;
                  final liked =
                      product != null && wishlist.contains(product.id);
                  return circle(
                    liked ? Icons.favorite : Icons.favorite_border,
                    color: liked ? _pink : context.colors.textPrimary,
                    () {
                      if (product == null) return;
                      final added = wishlist.toggle(product);
                      HapticFeedback.selectionClick();
                      _showMessage(
                        added
                            ? 'Đã thêm vào yêu thích'
                            : 'Đã bỏ khỏi yêu thích',
                      );
                    },
                  );
                },
              ),
              const SizedBox(width: 10),
              _buildCartButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartButton() {
    final scope = CartScope.maybeOf(context);
    return BouncingButton(
      onTap: () {
        if (scope == null) {
          _showMessage('Không thể mở giỏ hàng');
        } else {
          scope.onOpenCart();
        }
      },
      child: AnimatedScale(
        scale: _cartScale,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              key: _cartKey,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 20,
                color: context.colors.textPrimary,
              ),
            ),
            if (scope != null)
              Positioned(
                right: -4,
                top: -4,
                child: ListenableBuilder(
                  listenable: scope.controller,
                  builder: (context, _) {
                    final count = scope.controller.itemCount;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: _pink,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: context.colors.page,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error ?? 'Có lỗi xảy ra',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Thử lại',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. NỘI DUNG CUỘN
  Widget _buildContent(Product product) {
    final gallery = product.gallery;
    final sizes = _sizes;
    final description = product.description?.trim() ?? '';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      // Chừa chỗ dưới cho thanh điều hướng nằm đè lên nội dung
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // SLIDER ẢNH
          Stack(
            alignment: Alignment.centerRight,
            children: [
              SizedBox(
                key: _galleryKey,
                height: 260,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    // Nền phía sau ảnh, lộ ra khi ảnh không vừa khít khung
                    color: context.colors.surfaceAlt,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentImageIndex = index),
                      itemCount: gallery.length,
                      itemBuilder: (context, index) {
                        final image = GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            PageRouteBuilder<void>(
                              opaque: false,
                              barrierColor: Colors.black,
                              transitionDuration: const Duration(
                                milliseconds: 220,
                              ),
                              pageBuilder: (_, _, _) => ImageViewer(
                                images: gallery,
                                initialIndex: index,
                              ),
                              transitionsBuilder: (_, anim, _, child) =>
                                  FadeTransition(opacity: anim, child: child),
                            ),
                          ),
                          child: Image(
                            image: cachedImage(gallery[index], width: 1080),
                            // contain: luôn thấy trọn ảnh, không bị cắt
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Shimmer(
                                child: SkeletonBox(radius: 0),
                              );
                            },
                            errorBuilder: (context, error, stack) => Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 48,
                                color: context.colors.textMuted,
                              ),
                            ),
                          ),
                        );
                        return index == 0 && widget.heroTag != null
                            ? Hero(tag: widget.heroTag!, child: image)
                            : image;
                      },
                    ),
                  ),
                ),
              ),
              if (gallery.length > 1)
                Positioned(
                  right: 12,
                  child: BouncingButton(
                    onTap: () {
                      if (_currentImageIndex < gallery.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        color: context.colors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // INDICATOR DOTS (chỉ hiện khi có nhiều hơn 1 ảnh)
          if (gallery.length > 1) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(gallery.length, (index) {
                final active = _currentImageIndex == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 12 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? _pink : context.colors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 20),

          // CHỌN SIZE
          if (sizes.isNotEmpty) ...[
            Text(
              'Size: ${_selectedSize ?? ''}',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(sizes.length, (index) {
                  final selected = _selectedSizeIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: BouncingButton(
                      onTap: () => setState(() => _selectedSizeIndex = index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected ? _sizePink : context.colors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _sizePink, width: 1.2),
                        ),
                        child: Text(
                          sizes[index],
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : _sizePink,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // TÊN SẢN PHẨM
          Text(
            product.name,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          // MÔ TẢ (chỉ hiện khi backend có dữ liệu)
          if (description.isNotEmpty) ...[
            SizedBox(height: 4),
            Text(
              description,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.4,
                color: context.colors.textSecondary,
              ),
            ),
          ],

          // RATING (chỉ hiện khi backend có dữ liệu)
          if (product.rating != null) ...[
            const SizedBox(height: 8),
            _buildRating(product.rating!, product.ratingCount),
          ],

          const SizedBox(height: 8),

          // GIÁ TIỀN
          _buildPrice(product),

          // TỒN KHO: chỉ nhắc khi hết hoặc sắp hết
          if (!product.inStock || (product.stock ?? 99) <= 5) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  product.inStock
                      ? Icons.inventory_2_outlined
                      : Icons.remove_shopping_cart_outlined,
                  size: 16,
                  color: product.inStock
                      ? const Color(0xFFE08A00)
                      : const Color(0xFFD32F2F),
                ),
                const SizedBox(width: 6),
                Text(
                  product.inStock
                      ? 'Chỉ còn ${product.stock} sản phẩm'
                      : 'Hết hàng',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: product.inStock
                        ? const Color(0xFFE08A00)
                        : const Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // SỐ LƯỢNG
          if (product.inStock) ...[
            Row(
              children: [
                Text(
                  'Số lượng',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                _qtyButton(
                  Icons.remove,
                  _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                SizedBox(
                  width: 44,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      '$_quantity',
                      key: ValueKey(_quantity),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                _qtyButton(
                  Icons.add,
                  _quantity < (product.stock ?? 99)
                      ? () => setState(() => _quantity++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // NÚT MUA HÀNG (mờ đi khi hết hàng)
          Opacity(
            opacity: product.inStock ? 1 : 0.45,
            child: Row(
              children: [
                Expanded(
                  child: BouncingButton(
                    onTap: _goToCart,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.colors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _pink, width: 1.4),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: _pink,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Thêm vào giỏ',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _pink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BouncingButton(
                    onTap: _buyNow,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: _pink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.touch_app_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Mua ngay',
                            style: GoogleFonts.montserrat(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ĐÁNH GIÁ
          const SizedBox(height: 24),
          ReviewSection(
            key: ValueKey('reviews-${product.id}'),
            productId: product.id,
            productName: product.name,
            onChanged: _load,
          ),

          // SIMILAR TO
          if (_similar.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Sản phẩm tương tự',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
              children: _similar.map(_buildSimilarCard).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) => BouncingButton(
    onTap: onTap ?? () {},
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: context.colors.surfaceAlt,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 18,
        color: onTap == null
            ? context.colors.textMuted
            : context.colors.textPrimary,
      ),
    ),
  );

  Widget _buildRating(double rating, int? count) {
    final full = rating.floor();
    final hasHalf = rating - full >= 0.5;

    return Row(
      children: [
        ...List.generate(5, (i) {
          IconData icon = Icons.star_border;
          if (i < full) {
            icon = Icons.star;
          } else if (i == full && hasHalf) {
            icon = Icons.star_half;
          }
          return Icon(icon, size: 16, color: Color(0xFFEDB310));
        }),
        if (count != null) ...[
          SizedBox(width: 6),
          Text(
            '$count',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrice(Product product) {
    final original = product.originalPrice;
    final hasDiscount = original != null && original > product.price;

    return Row(
      children: [
        if (hasDiscount) ...[
          Text(
            formatVnd(original),
            style: GoogleFonts.montserrat(
              fontSize: 14,
              decoration: TextDecoration.lineThrough,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          formatVnd(product.price),
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 8),
          Text(
            '${((original - product.price) / original * 100).round()}% Off',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _pink,
            ),
          ),
        ],
      ],
    );
  }

  // Thẻ trong mục Similar To: bấm vào lại mở chính trang này cho sản phẩm khác
  Widget _buildSimilarCard(Product p) {
    return BouncingButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(
              productId: p.id,
              initialProduct: p,
              onGoToCart: widget.onGoToCart,
              onBuyNow: widget.onBuyNow,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: Image(
                  image: cachedImage(p.imageUrl, width: 480),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: context.colors.surfaceAlt,
                    child: Icon(
                      Icons.broken_image,
                      color: context.colors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatVnd(p.price),
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _pink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Khung chờ của trang chi tiết: ảnh lớn, các dòng chữ và hai nút.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => const Shimmer(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(height: 260, width: double.infinity, radius: 16),
          SizedBox(height: 24),
          SkeletonBox(height: 22, width: 240),
          SizedBox(height: 12),
          SkeletonBox(height: 14, width: double.infinity),
          SizedBox(height: 8),
          SkeletonBox(height: 14, width: 180),
          SizedBox(height: 16),
          SkeletonBox(height: 20, width: 120),
          SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 48, radius: 10)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 48, radius: 10)),
            ],
          ),
        ],
      ),
    ),
  );
}
