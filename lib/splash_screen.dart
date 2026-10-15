import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

import 'main_layout.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';
import 'onboarding/onboarding_screen.dart'; // 1. Thêm import này (chỉnh lại đường dẫn cho đúng vị trí file của bạn)

// 2. Chuyển thành StatefulWidget
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openNextScreen();
  }

  /// Đã đăng nhập (token còn hạn) thì vào thẳng trang chủ,
  /// chưa thì đi qua giới thiệu và đăng nhập như cũ.
  Future<void> _openNextScreen() async {
    final results = await Future.wait([
      AuthService.hasValidToken(),
      // Giữ logo trên màn hình một chút cho khỏi chớp
      Future<void>.delayed(Duration(milliseconds: 1500)),
    ]);
    if (!mounted) return;
    final loggedIn = results[0] as bool;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            loggedIn ? const MainLayout() : const OnboardingScreen(),
      ),
    );
    if (loggedIn) {
      // Mở app sẵn đã đăng nhập: cập nhật token thiết bị, rồi mở màn hình
      // mà thông báo (nếu có) trỏ tới
      PushService.registerDevice();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => PushService.openPending(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.page,
      body: Center(
        child: Image.asset(
          'assets/images/logoipsum.png',
          width: 275,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
