import 'package:flutter/material.dart'; // Đã sửa import package0 thành package
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

import 'bouncing_button.dart';
import 'user_avatar.dart';

class HeaderTopBar extends StatelessWidget {
  final String menuSvgAsset;
  final String logoAsset;
  final String avatarAsset;
  final VoidCallback? onMenuTap;
  final VoidCallback? onLogoTap;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onBellTap;
  final int unreadCount;

  const HeaderTopBar({
    super.key,
    this.menuSvgAsset = '',
    this.logoAsset = '',
    this.avatarAsset = '',
    this.onMenuTap,
    this.onLogoTap,
    this.onAvatarTap,
    this.onBellTap,
    this.unreadCount = 0,
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
                color: context.colors.surface,
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
                    : Icon(
                        Icons.menu,
                        size: 20,
                        color: context.colors.textPrimary,
                      ),
              ),
            ),
          ),

          // 2. LOGO BỌC KHUNG VIÊN THUỐC + NÚT BẤM BOUNCING
          BouncingButton(
            onTap: onLogoTap ?? () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.surface,
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

          // 3. CHUÔNG THÔNG BÁO + AVATAR
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBellTap != null) ...[
                BouncingButton(
                  onTap: onBellTap!,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.surface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          size: 20,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: brandPink,
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: context.colors.page,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              BouncingButton(
                onTap: onAvatarTap ?? () {},
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle, // Khung viên thuốc tròn
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  // Ảnh người dùng tự đặt; chưa có thì dùng avatarAsset mặc định
                  child: UserAvatar(size: 34, fallbackAsset: avatarAsset),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
