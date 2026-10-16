import 'widgets/skeleton.dart';
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

import 'package:google_fonts/google_fonts.dart';

import 'widgets/header_top_bar.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/bouncing_button.dart';
import 'widgets/app_button.dart';
import 'widgets/promo_banner_slider.dart';
import 'widgets/deal_of_the_day_section.dart';
import 'widgets/product_card.dart';
import 'services/api_client.dart';
import 'services/notification_service.dart';
import 'notifications_screen.dart';
import 'widgets/trending_products_section.dart';
import 'widgets/new_arrivals_banner.dart';
import 'widgets/sponsored_banner.dart';
import 'models/product.dart';
import 'models/product_category.dart';
import 'services/product_service.dart';
import 'trending_products_screen.dart';
import 'category_products_screen.dart';
import 'deal_of_the_day_screen.dart';
import 'new_arrivals_screen.dart';
import 'discounted_products_screen.dart';
import 'profile_screen.dart';
import 'utils/currency.dart';
import 'services/auth_service.dart';
import 'search_screen.dart';
import 'widgets/cart_scope.dart';

class HomeScreen extends StatefulWidget {
  final ScrollController? scrollController; // Controller nhận từ MainLayout

  const HomeScreen({super.key, this.scrollController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> futureDealProducts;
  late Future<List<Product>> futureTrendingProducts;

  @override
  void initState() {
    super.initState();
    futureDealProducts = ProductService.fetchDealsOfTheDay();
    futureTrendingProducts = ProductService.fetchTrending();
    // Lấy hồ sơ để avatar góc trên hiện ảnh người dùng; lỗi thì giữ ảnh mặc định
    AuthService.me().catchError((Object _) => null);
    NotificationService.refreshUnread();
  }

  bool _isDiscounted(Product product) {
    final discountedPrice = product.discountPrice;
    return product.isSale ||
        (discountedPrice != null && discountedPrice < product.price);
  }

  String? _discountLabel(Product product) {
    final discountPrice = product.discountPrice;
    if (discountPrice == null || discountPrice >= product.price) return null;
    final percent = ((product.price - discountPrice) / product.price * 100)
        .round();
    return '-$percent%';
  }

  /// Kéo xuống để tải lại Deal of the Day và Trending
  Future<void> _refreshHome() async {
    ProductService.clearCache();
    NotificationService.refreshUnread();
    final deals = ProductService.fetchDealsOfTheDay();
    final trending = ProductService.fetchTrending();
    setState(() {
      futureDealProducts = deals;
      futureTrendingProducts = trending;
    });
    try {
      await Future.wait([deals, trending]);
    } catch (_) {
      // Lỗi đã được từng khu vực tự hiển thị
    }
  }

  void _reloadHome() {
    ProductService.clearCache();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) =>
            HomeScreen(scrollController: widget.scrollController),
        transitionDuration: const Duration(milliseconds: 180),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Future<void> _openCategoryMenu() async {
    var categoriesFuture = ProductService.fetchCategories();
    final selectedCategory = await showGeneralDialog<ProductCategory>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Đóng danh mục',
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 280),
      pageBuilder: (dialogContext, _, _) => StatefulBuilder(
        builder: (panelContext, setPanelState) {
          final width = MediaQuery.sizeOf(dialogContext).width;
          return Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: context.colors.surfaceAlt,
              child: SizedBox(
                width: width < 400 ? width * 0.84 : 336,
                height: double.infinity,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 12, 20),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFE3E6C),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront_outlined,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mua sắm theo danh mục',
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Đóng',
                              onPressed: () => Navigator.pop(dialogContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                        child: Text(
                          'DANH MỤC',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<ProductCategory>>(
                          future: categoriesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFE3E6C),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return _CategoryMenuMessage(
                                message: 'Không thể tải danh mục.',
                                onRetry: () => setPanelState(
                                  () => categoriesFuture =
                                      ProductService.fetchCategories(),
                                ),
                              );
                            }
                            final categories = snapshot.data ?? const [];
                            if (categories.isEmpty) {
                              return const _CategoryMenuMessage(
                                message: 'Chưa có danh mục nào.',
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              itemCount: categories.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final category = categories[index];
                                final icon = _categoryIcon(category.name);
                                return ListTile(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  leading: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _categoryColor(category.name),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icon,
                                      color: const Color(0xFF333333),
                                      size: 21,
                                    ),
                                  ),
                                  title: Text(
                                    category.name,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.chevron_right,
                                    color: context.colors.textSecondary,
                                  ),
                                  onTap: () =>
                                      Navigator.pop(dialogContext, category),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      transitionBuilder: (_, animation, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(slide), child: child);
      },
    );

    if (!mounted || selectedCategory == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreen(category: selectedCategory.name),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.trim().toLowerCase()) {
      case 'beauty':
        return Icons.face_retouching_natural;
      case 'fashion':
        return Icons.checkroom_outlined;
      case 'kids':
        return Icons.child_care_outlined;
      case 'mens':
        return Icons.man_outlined;
      case 'womens':
        return Icons.woman_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _categoryColor(String category) {
    switch (category.trim().toLowerCase()) {
      case 'beauty':
        return const Color(0xFFFFE0E7);
      case 'fashion':
        return const Color(0xFFFFE6CC);
      case 'kids':
        return const Color(0xFFFFF1B8);
      case 'mens':
        return const Color(0xFFD9E9FF);
      case 'womens':
        return const Color(0xFFE9DFFF);
      default:
        return const Color(0xFFE8E8E8);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    NotificationService.refreshUnread();
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  // Đưa danh sách categories vào trong State để quản lý dễ dàng hơn
  final List<Map<String, String>> categories = [
    {'title': 'Beauty', 'image': 'assets/images/Ellipse 4.png'},
    {'title': 'Fashion', 'image': 'assets/images/unsplash__3Q3tsJ01nc.png'},
    {'title': 'Kids', 'image': 'assets/images/unsplash_GCDjllzoKLo.png'},
    {'title': 'Mens', 'image': 'assets/images/unsplash_OYYE4g-I5ZQ.png'},
    {'title': 'Womens', 'image': 'assets/images/unsplash_xPJYL0l5Ii8.png'},
  ];
  // THÊM MỚI:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.page,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFE3E6C),
          onRefresh: _refreshHome,
          child: SingleChildScrollView(
            controller: widget
                .scrollController, // GẮN CONTROLLER VÀO ĐÂY ĐỂ TỰ ĐỘNG CUỘN
            // Luôn kéo được để làm mới, kể cả khi nội dung ngắn
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 1. HEADER TOP BAR
                ValueListenableBuilder<int>(
                  valueListenable: NotificationService.unread,
                  builder: (context, unread, _) => HeaderTopBar(
                    menuSvgAsset: 'assets/icon/menu.svg',
                    logoAsset: 'assets/images/logoipsum.png',
                    avatarAsset:
                        'assets/images/2289_SkVNQSBGQU1PIDEwMjgtMTE2 1.png',
                    onMenuTap: _openCategoryMenu,
                    onLogoTap: _reloadHome,
                    onAvatarTap: _openProfile,
                    onBellTap: _openNotifications,
                    unreadCount: unread,
                  ),
                ),

                const SizedBox(height: 16),

                // 2. SEARCH BAR: bấm vào là sang tab Search và mở bàn phím
                SearchBarWidget(
                  onTap: () =>
                      CartScope.maybeOf(context)?.onOpenSearch
                          ?.call(SearchAction.focus),
                ),

                const SizedBox(height: 20),

                // 3. SECTION: ALL FEATURED + BUTTONS
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Featured',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      Row(
                        children: [
                          AppButton(
                            label: 'Sort',
                            icon: Icons.swap_vert,
                            onTap: () =>
                                CartScope.maybeOf(context)?.onOpenSearch
                                    ?.call(SearchAction.sort),
                          ),
                          SizedBox(width: 8),
                          AppButton(
                            label: 'Filter',
                            icon: Icons.filter_alt_outlined,
                            onTap: () =>
                                CartScope.maybeOf(context)?.onOpenSearch
                                    ?.call(SearchAction.filter),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 18),

                // 4. CATEGORIES (DANH MỤC TRÒN)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  padding: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 96,
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => SizedBox(width: 16),
                      itemBuilder: (context, index) {
                        final category = categories[index];

                        return BouncingButton(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CategoryProductsScreen(
                                  category: category['title']!,
                                ),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: context.colors.surfaceAlt,
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    category['image']!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                category['title']!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // 5. BANNER SLIDE
                PromoBannerSlider(),

                SizedBox(height: 20),

                // 6. DEAL OF THE DAY SECTION
                DealOfTheDaySection(
                  onViewAllTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DealOfTheDayScreen()),
                    );
                  },
                ),

                SizedBox(height: 20),

                // 7. DANH SÁCH SẢN PHẨM DEALS (đã đổi sang API thật)
                SizedBox(
                  height: 290,
                  child: FutureBuilder<List<Product>>(
                    future: futureDealProducts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ProductRowSkeleton();
                      }
                      if (snapshot.hasError) {
                        return _SectionRetry(
                          message: errorText(snapshot.error!),
                          onRetry: _refreshHome,
                        );
                      }
                      final products = (snapshot.data ?? [])
                          .where(
                            (product) =>
                                product.isDealOfTheDay &&
                                _isDiscounted(product),
                          )
                          .toList();
                      if (products.isEmpty) {
                        return Center(
                          child: Text(
                            'Hiện chưa có sản phẩm giảm giá.',
                            style: GoogleFonts.montserrat(
                              fontSize: 13,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = products[index];
                          final hasReducedPrice =
                              item.discountPrice != null &&
                              item.discountPrice! < item.price;
                          return SizedBox(
                            width: 170,
                            child: ProductCard(
                              title: item.name,
                              description: item.description,
                              price: formatVnd(
                                hasReducedPrice
                                    ? item.discountPrice!
                                    : item.price,
                              ),
                              originalPrice: hasReducedPrice
                                  ? formatVnd(item.price)
                                  : null,
                              discount: _discountLabel(item),
                              image: item.imageUrl,
                              id: item.id,
                              product: item,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // SizedBox(height: 20),
                //
                // // 8. SPECIAL OFFERS CARD
                // SpecialOffersCard(
                //   imageAsset: 'assets/images/Rectangle 56.png',
                //   onOfferTap: () {
                //     print('Đã chọn sản phẩm special offer');
                //   },
                // ),

                // 9. FEATURE OFFER BANNER
                // FeatureOfferBanner(
                //   imageAsset: 'assets/images/Rectangle 55.png',
                //   onVisitTap: () {},
                // ),
                SizedBox(height: 20),

                // 10. TRENDING PRODUCTS SECTION
                TrendingProductsSection(
                  onViewAllTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrendingProductsScreen(),
                      ),
                    );
                  },
                ),

                SizedBox(height: 12),

                // 11. DANH SÁCH TRENDING PRODUCTS
                SizedBox(
                  height: 290,
                  child: FutureBuilder<List<Product>>(
                    future: futureTrendingProducts,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const ProductRowSkeleton();
                      }
                      if (snapshot.hasError) {
                        return _SectionRetry(
                          message: errorText(snapshot.error!),
                          onRetry: _refreshHome,
                        );
                      }
                      final products = snapshot.data ?? [];
                      if (products.isEmpty) {
                        return _SectionRetry(
                          message: 'Hiện chưa có sản phẩm trending.',
                        );
                      }
                      return ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: products.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final item = products[index];
                          final hasReducedPrice =
                              item.discountPrice != null &&
                              item.discountPrice! < item.price;
                          return SizedBox(
                            width: 170,
                            // Không truyền onTap: ProductCard tự mở trang chi tiết
                            child: ProductCard(
                              title: item.name,
                              description: item.description,
                              price: formatVnd(
                                hasReducedPrice
                                    ? item.discountPrice!
                                    : item.price,
                              ),
                              originalPrice: hasReducedPrice
                                  ? formatVnd(item.price)
                                  : null,
                              discount: _discountLabel(item),
                              image: item.imageUrl,
                              id: item.id,
                              product: item,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                SizedBox(height: 16),

                // 12. NEW ARRIVALS BANNER
                NewArrivalsBanner(
                  imageAsset: 'assets/images/Mask Group (4).png',
                  onViewAllTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => NewArrivalsScreen()),
                    );
                  },
                ),

                SizedBox(height: 20),

                // 13. SPONSERD BANNER
                SponsoredBanner(
                  imageAsset: 'assets/images/image 12.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DiscountedProductsScreen(
                          title: 'Giảm đến 50%',
                          maxDiscountPercent: 50,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Thông báo trong một khu vực của trang chủ, kèm nút thử lại khi tải lỗi.
class _SectionRetry extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _SectionRetry({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              color: context.colors.textSecondary,
            ),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFE3E6C),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryMenuMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _CategoryMenuMessage({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onRetry, child: const Text('Đóng')),
            ],
          ],
        ),
      ),
    );
  }
}
