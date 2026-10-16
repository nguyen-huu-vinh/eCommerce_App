import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bouncing_button.dart';

class FeatureOfferBanner extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onVisitTap;

  const FeatureOfferBanner({
    super.key,
    this.imageAsset = 'assets/images/heels.png',
    this.title = 'Flat and Heels',
    this.subtitle = 'Stand a chance to get rewarded',
    this.buttonText = 'Visit now',
    this.onVisitTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 170,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // 1. DẢI VÀNG VÀ HÌNH ẢNH SẢN PHẨM BÊN TRÁI
            Stack(
              children: [
                // Vạch vàng viền trái
                Container(
                  width: 10,
                  height: double.infinity,
                  color: const Color(0xFFF3AB16),
                ),

                // Cụm hình ảnh đôi giày (kèm hiệu ứng vệt vàng hoạ tiết)
                Container(
                  width: 145,
                  padding: const EdgeInsets.only(left: 10),
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.style, size: 50, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ],
            ),

            // 2. NỘI DUNG CHỮ & NÚT BẤM BÊN PHẢI
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.end, // Căn lề phải theo Figma
                  children: [
                    // Tiêu đề sản phẩm
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 6),

                    // Phụ đề
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Nút "Visit now" (Dùng BouncingButton + Màu hồng rực)
                    BouncingButton(
                      onTap: onVisitTap ?? () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFE3E6C), // Màu nút hồng tươi
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonText,
                              style: GoogleFonts.montserrat(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
