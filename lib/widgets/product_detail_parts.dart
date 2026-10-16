import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import 'bouncing_button.dart';
import 'skeleton.dart';

/// Nút tròn − / + chọn số lượng. [onTap] null thì mờ đi và không bấm được.
class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const QuantityButton({super.key, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) => BouncingButton(
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
}

/// Hàng 5 ngôi sao kèm số lượt đánh giá.
class RatingStars extends StatelessWidget {
  final double rating;
  final int? count;
  const RatingStars({super.key, required this.rating, this.count});

  @override
  Widget build(BuildContext context) {
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
          return Icon(icon, size: 16, color: const Color(0xFFEDB310));
        }),
        if (count != null) ...[
          const SizedBox(width: 6),
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
}

/// Giá hiện tại, giá gốc gạch ngang và phần trăm giảm.
class PriceRow extends StatelessWidget {
  final Product product;
  const PriceRow({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
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
              color: brandPink,
            ),
          ),
        ],
      ],
    );
  }
}

/// Khung chờ của trang chi tiết: ảnh lớn, các dòng chữ và hai nút.
class DetailSkeleton extends StatelessWidget {
  const DetailSkeleton({super.key});

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
