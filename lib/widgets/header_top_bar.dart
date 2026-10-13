import 'package:flutter/material.dart'; // Đã sửa import package0 thành package
import 'package:flutter_svg/flutter_svg.dart';

import 'bouncing_button.dart';

class HeaderTopBar extends StatelessWidget {
  final String menuSvgAsset;
  final String logoAsset;
  final String avatarAsset;
  final VoidCallback? onMenuTap;
  final VoidCallback? onLogoTap;
  final VoidCallback? onAvatarTap;

  const HeaderTopBar({
    super.key,
    this.menuSvgAsset = '',
    this.logoAsset = '',
    this.avatarAsset = '',
    this.onMenuTap,
    this.onLogoTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.transparent, // Không bọc khung dài tổng
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. MENU BỌC KHUNG VIÊN THUỐC + NÚT BẤM BOUNCING
          BouncingButton(
            onTap: onMenuTap ?? () {},
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle, // Dạng tròn viên thuốc cho icon
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: menuSvgAsset.isNotEmpty
                    ? SvgPicture.asset(menuSvgAsset, fit: BoxFit.contain)
                    : const Icon(Icons.menu, size: 20, color: Colors.black),
              ),
            ),
          ),

          // 2. LOGO BỌC KHUNG VIÊN THUỐC + NÚT BẤM BOUNCING
          BouncingButton(
            onTap: onLogoTap ?? () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20), // Khung viên thuốc dài
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SizedBox(
                width: 100,
                height: 26,
                child: logoAsset.isNotEmpty
                    ? Image.asset(logoAsset, fit: BoxFit.contain)
                    : const SizedBox(),
              ),
            ),
          ),

          // 3. AVATAR BỌC KHUNG VIÊN THUỐC TRÒN + NÚT BẤM BOUNCING
          BouncingButton(
            onTap: onAvatarTap ?? () {},
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle, // Khung viên thuốc tròn
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: avatarAsset.isNotEmpty
                      ? Image.asset(avatarAsset, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
