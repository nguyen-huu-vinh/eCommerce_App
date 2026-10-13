import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/network_image.dart';

/// Ảnh đại diện của người đang đăng nhập, tự đổi khi họ cập nhật ảnh.
/// Chưa có ảnh thì hiện [fallbackAsset] (hoặc biểu tượng người).
class UserAvatar extends StatelessWidget {
  final double size;
  final String? fallbackAsset;

  const UserAvatar({super.key, required this.size, this.fallbackAsset});

  @override
  Widget build(BuildContext context) {
    final fallback = fallbackAsset != null && fallbackAsset!.isNotEmpty
        ? Image.asset(
            fallbackAsset!,
            width: size,
            height: size,
            fit: BoxFit.cover,
          )
        : Container(
            width: size,
            height: size,
            color: Colors.grey.shade300,
            child: Icon(Icons.person, color: Colors.white, size: size * 0.6),
          );

    return ClipOval(
      child: ValueListenableBuilder<String?>(
        valueListenable: AuthService.avatarUrl,
        builder: (context, url, _) => url == null
            ? fallback
            : Image(
                // Giải mã gấp 3 kích thước hiển thị cho sắc nét trên màn dày điểm ảnh
                image: cachedImage(url, width: (size * 3).round()),
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => fallback,
              ),
      ),
    );
  }
}
