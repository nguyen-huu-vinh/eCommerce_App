import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String homeIconPath;
  final String wishlistIconPath;
  final String cartIconPath;
  final String searchIconPath;
  final String settingIconPath;
  final int cartBadgeCount; // Số lượng trong giỏ hàng (VD: 19)

  /// true = thanh co nhỏ lại ở giữa (vẫn đủ 5 icon nhưng gọn hơn)
  final bool isCollapsed;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.homeIconPath,
    required this.wishlistIconPath,
    required this.cartIconPath,
    required this.searchIconPath,
    required this.settingIconPath,
    this.cartBadgeCount = 0,
    this.isCollapsed = false,
  });

  static const _duration = Duration(milliseconds: 300);
  static const _curve = Curves.easeInOutCubic;
  static const _pink = Color(0xFFFE3E6C);

  // Kích thước khi thanh mở rộng / thu nhỏ
  static const double _fullHeight = 64;
  static const double _smallHeight = 60;
  static const double _fullIcon = 24;
  static const double _smallIcon = 24;
  static const double _smallWidth = 340;

  @override
  Widget build(BuildContext context) {
    final List<String> iconPaths = [
      homeIconPath,
      wishlistIconPath,
      cartIconPath,
      searchIconPath,
      settingIconPath,
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double fullWidth = constraints.maxWidth;
          final double smallWidth = _smallWidth < fullWidth
              ? _smallWidth
              : fullWidth;

          // t = 0: mở rộng, t = 1: thu nhỏ. Mọi kích thước đều nội suy theo t
          // nên thanh co lại mượt mà và không bị lỗi tràn (overflow).
          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: isCollapsed ? 1.0 : 0.0),
            duration: _duration,
            curve: _curve,
            builder: (context, t, _) {
              final double width = lerpDouble(fullWidth, smallWidth, t)!;
              final double height = lerpDouble(_fullHeight, _smallHeight, t)!;
              final double iconSize = lerpDouble(_fullIcon, _smallIcon, t)!;
              final double padH = lerpDouble(16, 10, t)!;
              final double padV = lerpDouble(8, 6, t)!;

              return Align(
                alignment: Alignment.center,
                heightFactor: 1.0,
                child: Container(
                  width: width,
                  height: height,
                  // Lớp ngoài chỉ để đổ bóng (đặt ngoài ClipRRect kẻo bị cắt)
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      // Độ mờ vừa phải: vẫn ra hiệu ứng kính nhưng nhẹ hơn
                      // nhiều cho GPU khi cuộn (blur tính lại mỗi khung hình)
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              context.colors.surface.withOpacity(0.78),
                              context.colors.surface.withOpacity(0.55),
                            ],
                          ),
                          border: Border.all(
                            color: context.colors.border.withOpacity(0.8),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: List.generate(
                            iconPaths.length,
                            (i) => _buildTab(
                              context,
                              i,
                              iconPaths[i],
                              iconSize,
                              padH,
                              padV,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    int index,
    String iconPath,
    double iconSize,
    double padH,
    double padV,
  ) {
    final bool isSelected = currentIndex == index;

    // Expanded: cả ô của tab đều bấm được và chia đều chiều ngang
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isSelected ? _pink.withOpacity(0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: iconSize,
                    height: iconSize,
                    colorFilter: ColorFilter.mode(
                      isSelected ? _pink : context.colors.textSecondary,
                      BlendMode.srcIn,
                    ),
                  ),

                  // Badge số lượng ở giỏ hàng (Index 2)
                  if (index == 2 && cartBadgeCount > 0)
                    Positioned(
                      top: -6,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: _pink,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Center(
                          child: Text(
                            cartBadgeCount > 99 ? '99+' : '$cartBadgeCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
