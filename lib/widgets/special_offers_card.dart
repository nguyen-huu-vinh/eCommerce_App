import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bouncing_button.dart'; // Import BouncingButton

class SpecialOffersCard extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final VoidCallback? onOfferTap; // Callback khi bấm vào nút Special Offer

  const SpecialOffersCard({
    super.key,
    this.imageAsset = 'assets/images/special_offer.png',
    this.title = 'Special Offers',
    this.subtitle = 'We make sure you get the\noffer you need at best prices',
    this.onOfferTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // 1. NÚT "SPECIAL OFFER" BÊN TRÁI (SỬ DỤNG BouncingButton)
          BouncingButton(
            onTap:
                onOfferTap ??
                () {
                  print('Đã bấm vào Special Offer Button!');
                },
            child: SizedBox(
              width: 75,
              height: 75,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.local_offer_outlined,
                      color: Color(0xFFFA7189),
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(width: 16),

          // 2. CỤM TIÊU ĐỀ VÀ MÔ TẢ BÊN PHẢI
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title + Emoji
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Emoji 😱
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.surface,
                        border: Border.all(
                          color: context.colors.border,
                          width: 1,
                        ),
                      ),
                      child: const Text('😱', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                SizedBox(height: 4),

                // Subtitle
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    height: 1.3,
                    color: context.colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
