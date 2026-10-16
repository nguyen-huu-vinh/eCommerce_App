import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../theme/app_theme.dart';

/// Vệt sáng chạy ngang qua các khối bên trong, dùng làm khung chờ khi đang tải.
/// Một AnimationController dùng chung cho cả cụm khối nên không nặng máy.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.surfaceAlt;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highlight = dark ? const Color(0xFF3A3A3C) : Colors.white;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) {
          final t = _controller.value;
          return LinearGradient(
            begin: Alignment(-1.5 + 3 * t, -0.3),
            end: Alignment(-0.5 + 3 * t, 0.3),
            colors: [base, highlight, base],
            stops: const [0.2, 0.5, 0.8],
          ).createShader(rect);
        },
        child: child,
      ),
    );
  }
}

/// Một khối bo góc màu xám, là viên gạch của khung chờ.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double radius;
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.colors.surfaceAlt,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Khung chờ có hình dáng giống ProductCard.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(10),
    ),
    clipBehavior: Clip.antiAlias,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(aspectRatio: 1, child: SkeletonBox(radius: 0)),
        Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(height: 12, width: double.infinity),
              SizedBox(height: 6),
              SkeletonBox(height: 12, width: 90),
              SizedBox(height: 10),
              SkeletonBox(height: 14, width: 70),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Hàng ngang khung chờ cho các mục sản phẩm cuộn ngang ở trang chủ.
class ProductRowSkeleton extends StatelessWidget {
  const ProductRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, _) =>
          const SizedBox(width: 170, child: ProductCardSkeleton()),
    ),
  );
}

/// Lưới 2 cột khung chờ cho các trang danh sách sản phẩm.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Shimmer(
    child: MasonryGridView.count(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      itemCount: 6,
      itemBuilder: (_, _) => const ProductCardSkeleton(),
    ),
  );
}
