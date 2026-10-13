import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'widgets/custom_bottom_navbar.dart';
import 'widgets/cart_scope.dart';
import 'cart_screen.dart';
import 'services/cart_controller.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'services/wishlist_controller.dart';
import 'wishlist_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  final CartController _cartController = CartController();

  // Thanh điều hướng đang thu nhỏ hay không (đổi theo hướng cuộn)
  bool _navCollapsed = false;

  // Bấm lại tab Home thì cuộn về đầu trang
  final ScrollController _homeScrollController = ScrollController();

  // Mỗi tab có một Navigator riêng: khi bấm vào sản phẩm (Navigator.push),
  // trang mới mở BÊN TRONG tab nên thanh điều hướng dưới vẫn hiện
  final List<GlobalKey<NavigatorState>> _navKeys = List.generate(
    5,
    (_) => GlobalKey<NavigatorState>(),
  );

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _cartController.addListener(_onCartChanged);
    _cartController.load();
    WishlistController.instance.load();
    // 2. Truyền controller tương ứng cho từng màn hình
    _screens = [
      _TabNavigator(
        navigatorKey: _navKeys[0],
        child: HomeScreen(scrollController: _homeScrollController),
      ),
      _TabNavigator(navigatorKey: _navKeys[1], child: const WishlistScreen()),
      _TabNavigator(
        navigatorKey: _navKeys[2],
        child: CartScreen(controller: _cartController),
      ),
      _TabNavigator(navigatorKey: _navKeys[3], child: const SearchScreen()),
      _TabNavigator(navigatorKey: _navKeys[4], child: const ProfileScreen()),
    ];
  }

  void _onCartChanged() {
    if (mounted) setState(() {});
  }

  void _openCart() {
    setState(() {
      _currentIndex = 2;
      _navCollapsed = false;
    });
  }

  @override
  void dispose() {
    // Giải phóng bộ nhớ cho các controllers
    _homeScrollController.dispose();
    _cartController
      ..removeListener(_onCartChanged)
      ..dispose();
    super.dispose();
  }

  // 3. Hàm xử lý khi bấm vào icon Tab / Đổi tab
  void _onTabTapped(int index) {
    if (index == _currentIndex) {
      // Bấm lại tab đang mở: nếu đang ở trang con (VD chi tiết sản phẩm) thì
      // quay về trang gốc của tab, nếu không thì cuộn về đầu trang
      final nav = _navKeys[index].currentState;
      if (nav != null && nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
        setState(() => _navCollapsed = false);
        return;
      }
      final controller = index == 0 ? _homeScrollController : null;
      if (controller != null && controller.hasClients) {
        controller.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
      return;
    }

    // Chuyển sang tab khác
    setState(() {
      _currentIndex = index;
      _navCollapsed = false; // đổi tab thì mở rộng thanh lại
    });
  }

  // 4. Nghe cuộn dọc: kéo xuống -> thu nhỏ, kéo lên -> mở rộng
  bool _onScroll(ScrollUpdateNotification n) {
    // Chỉ xét cuộn dọc (bỏ qua danh sách ngang bên trong)
    if (n.metrics.axis != Axis.vertical) return false;

    final delta = n.scrollDelta ?? 0;
    if (delta > 1 && !_navCollapsed) {
      setState(() => _navCollapsed = true);
    } else if (delta < -1 && _navCollapsed) {
      setState(() => _navCollapsed = false);
    }
    return false; // để thông báo đi tiếp, không chặn các widget khác
  }

  @override
  Widget build(BuildContext context) {
    // Nút Back của hệ thống: thoát trang con trước, rồi về tab Home, rồi mới thoát app
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final nav = _navKeys[_currentIndex].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
            _navCollapsed = false;
          });
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody:
            true, // cho nội dung tràn xuống dưới thanh để thấy hiệu ứng kính mờ
        body: CartScope(
          controller: _cartController,
          onOpenCart: _openCart,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: _onScroll,
            child: IndexedStack(
              index: _currentIndex,
              children: [
                // Tab đang ẩn vẫn giữ trạng thái nhưng tạm dừng mọi hiệu ứng
                // và bộ đếm giờ (VD banner tự chạy) để đỡ tốn CPU và pin
                for (var i = 0; i < _screens.length; i++)
                  TickerMode(enabled: i == _currentIndex, child: _screens[i]),
              ],
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomNavBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          homeIconPath: 'assets/icon/home 1.svg',
          wishlistIconPath: 'assets/icon/heart 1.svg',
          cartIconPath: 'assets/icon/shopping-cart 2.svg',
          searchIconPath: 'assets/icon/search 1.svg',
          settingIconPath: 'assets/icon/settings.svg',
          isCollapsed: _navCollapsed,
          cartBadgeCount: _cartController.itemCount,
        ),
      ),
    );
  }
}

/// Bọc mỗi tab trong một Navigator riêng để các trang con mở ra bên trong tab
class _TabNavigator extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  const _TabNavigator({required this.navigatorKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (context) => child, settings: settings),
    );
  }
}
