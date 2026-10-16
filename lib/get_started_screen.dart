import 'package:flutter/material.dart';

import 'main_layout.dart';

class GetStartedScreen extends StatelessWidget {
  const GetStartedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Ảnh nền full màn hình
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/nen.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 2. Lớp phủ Gradient mờ dần ở phía dưới để chữ và nút dễ nhìn hơn
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: [0.4, 0.7, 1.0],
              ),
            ),
          ),

          // 3. Nội dung chữ và nút bấm
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Tiêu đề lớn
                  Text(
                    'You want\nAuthentic, here\nyou go!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),

                  SizedBox(height: 14),

                  // Dòng chú thích nhỏ
                  Text(
                    'Find it here, buy it now!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFFF2F2F2),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 34),

                  // Nút Get Started
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainLayout(),
                          ),
                        );
                        // Chuyển sang Trang chủ (HomeScreen)
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF83758),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
