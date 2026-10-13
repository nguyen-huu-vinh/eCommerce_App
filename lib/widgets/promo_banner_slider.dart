import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bouncing_button.dart';
import '../product_detail_screen.dart';
import '../models/product.dart';

class PromoBannerSlider extends StatefulWidget {
  const PromoBannerSlider({super.key});

  @override
  State<PromoBannerSlider> createState() => _PromoBannerSliderState();
}

class _PromoBannerSliderState extends State<PromoBannerSlider> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  // Giữ nguyên toàn bộ cấu trúc dữ liệu Banner của bạn
  final List<Map<String, String>> _bannerData = const [
    {
      'discount': '50-40% OFF',
      'title': 'Now in (product)',
      'subtitle': 'All colours',
      'buttonText': 'Shop Now',
      'image': 'assets/images/Rectangle 48.png',
    },
    {
      'discount': '30% OFF',
      'title': 'Summer Collection',
      'subtitle': 'New Arrival',
      'buttonText': 'Shop Now',
      'image': 'assets/images/banner_model.png',
    },
    {
      'discount': '70% OFF',
      'title': 'Flash Sale Today',
      'subtitle': 'Limited items',
      'buttonText': 'Shop Now',
      'image': 'assets/images/banner_model.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Đặt initialPage ở số lớn để cuộn vòng lặp vô hạn mượt mà
    _pageController = PageController(initialPage: 1000 * _bannerData.length);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Chỉ tự chuyển slide khi banner đang hiển thị: sang tab khác hoặc mở
    // trang chi tiết đè lên thì dừng, quay lại thì chạy tiếp
    if (TickerMode.valuesOf(context).enabled) {
      _startAutoSlider();
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _startAutoSlider() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Giải phóng timer tránh rò rỉ bộ nhớ
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. KHUNG BANNER SLIDE (TỰ ĐỘNG CHUYỂN SLIDE SAU 1S)
        Container(
          height: 180,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index % _bannerData.length;
              });
            },
            itemBuilder: (context, index) {
              final item = _bannerData[index % _bannerData.length];
              return _buildBannerCard(item);
            },
          ),
        ),

        const SizedBox(height: 12),

        // 2. CHỈ SỐ TRANG (DOTS INDICATOR)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _bannerData.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 10 : 8,
              height: _currentPage == index ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? const Color(0xFFFA7189) // Màu hồng tươi khi Active
                    : const Color(0xFFD9D9D9), // Màu xám mờ khi Inactive
              ),
            ),
          ),
        ),
      ],
    );
  }

  // GIỮ NGUYÊN HOÀN TOÀN WIDGET VẼ CARD BANNER CỦA BẠN
  Widget _buildBannerCard(Map<String, String> item) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFA3B3), // Màu nền hồng
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // ẢNH MẪU / SẢN PHẨM Ở BÊN PHẢI
          Positioned(
            right: 0,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.asset(
                item['image']!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const SizedBox(width: 140);
                },
              ),
            ),
          ),

          // NỘI DUNG CHỮ & NÚT BẤM Ở BÊN TRÁI
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Phần trăm giảm giá
                Text(
                  item['discount']!,
                  style: GoogleFonts.montserrat(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),

                // Tiêu đề phụ
                Text(
                  item['title']!,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                Text(
                  item['subtitle']!,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // NÚT SHOP NOW (DÙNG BouncingButton)
                BouncingButton(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductDetailScreen(productId: 14),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item['buttonText']!,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
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
        ],
      ),
    );
  }
}
