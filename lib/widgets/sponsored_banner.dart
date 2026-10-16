import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'package:google_fonts/google_fonts.dart';

class SponsoredBanner extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const SponsoredBanner({
    super.key,
    this.title = 'Sponsored',
    this.subtitle = 'up to 50% Off',
    this.imageAsset = 'assets/images/sponsored_shoes.png',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TIÊU ĐỀ "Sponsored"
          Text(
            title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // 2. KHUNG HÌNH ẢNH BANNER + NÚT BẤM DƯỚI
          GestureDetector(
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    // Hình ảnh QC
                    AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.asset(
                        imageAsset,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Dòng chữ "up to 50% Off" + Icon mũi tên
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            subtitle,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: context.colors.textPrimary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
