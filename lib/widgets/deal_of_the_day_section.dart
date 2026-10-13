import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bouncing_button.dart';

class DealOfTheDaySection extends StatelessWidget {
  final String title;
  final String remainingTime;
  final VoidCallback? onViewAllTap;

  const DealOfTheDaySection({
    super.key,
    this.title = 'Deal of the Day',
    this.remainingTime = '22h 55m 20s remaining',
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF4392F9), // Màu nền xanh dương theo thiết kế
        borderRadius: BorderRadius.circular(10), // Bo góc nhẹ
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // BÊN TRÁI: TIÊU ĐỀ & ĐỒNG HỒ ĐẾM NGƯỢC
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tiêu đề "Deal of the Day"
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              // Dãy đếm ngược có Icon đồng hồ
              Row(
                children: [
                  const Icon(
                    Icons.access_time, // Icon đồng hồ báo thức
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    remainingTime,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w400, // Regular
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // BÊN PHẢI: NÚT "View all" CÓ VIỀN TRẮNG (DÙNG BouncingButton)
          BouncingButton(
            onTap: onViewAllTap ?? () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w500, // Medium
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
