import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.backgroundColor = Colors.white,
    this.textColor = const Color(0xFF000000),
    this.iconColor = const Color(0xFF000000),
    this.fontSize = 12,
    this.fontWeight = FontWeight.w400, // Montserrat Regular mặc định
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    this.borderRadius = 6.0,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  // Hiệu ứng co nảy khi chạm: thu nhỏ 5%, chỉ đổi tỉ lệ khi vẽ
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 0.95,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Phản hồi ngay, không chờ hết hiệu ứng mới mở trang
          onTap: () {
            _controller.forward().then((_) => _controller.reverse());
            widget.onTap();
          },
          onTapDown: (_) => _controller.forward(),
          onTapCancel: () => _controller.reverse(),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.montserrat(
                    fontSize: widget.fontSize,
                    fontWeight: widget.fontWeight,
                    color: widget.textColor,
                  ),
                ),
                if (widget.icon != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    widget.icon,
                    size: widget.fontSize + 2,
                    color: widget.iconColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
