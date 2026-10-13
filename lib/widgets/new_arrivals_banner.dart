import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bouncing_button.dart';

class NewArrivalsBanner extends StatelessWidget {
  final String imageAsset;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onViewAllTap;

  const NewArrivalsBanner({
    super.key,
    this.imageAsset = 'assets/images/hot_summer_sale.png',
    this.title = 'New Arrivals',
    this.subtitle = "Summer' 25 Collections",
    this.buttonText = 'View all',
    this.onViewAllTap,
  });

  @override
  Widget build(BuildContext context) {
    // Bấm vào bất kỳ chỗ nào trên banner cũng mở danh sách sản phẩm mới
    return BouncingButton(onTap: onViewAllTap ?? () {}, child: _buildCard());
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BANNER HÌNH ẢNH "HOT SUMMER SALE"
            AspectRatio(
              aspectRatio: 16 / 9, // Tỷ lệ ảnh chuẩn banner
              child: Image.asset(
                imageAsset,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(
                      0xFFFBE4C8,
                    ), // Màu cam nhạt giống nền thiết kế
                    child: const Center(
                      child: Icon(Icons.image, size: 48, color: Colors.orange),
                    ),
                  );
                },
              ),
            ),

            // 2. PHẦN THÔNG TIN BÊN DƯỚI (TIÊU ĐỀ + NÚT BẤM)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Cụm chữ bên trái
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),

                  // Nút "View all" bên phải (Sử dụng BouncingButton)
                  BouncingButton(
                    onTap: onViewAllTap ?? () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFFE3E6C,
                        ), // Màu hồng tươi đặc trưng
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
            ),
          ],
        ),
      ),
    );
  }
}
