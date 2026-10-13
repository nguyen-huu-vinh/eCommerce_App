import 'package:flutter/material.dart';

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleFactor; // Độ co nảy (mặc định 5%)

  const BouncingButton({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.05,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  );
  // Chỉ đổi tỉ lệ khi vẽ, không build lại child ở mỗi khung hình
  late final Animation<double> _scale = Tween<double>(
    begin: 1,
    end: 1 - widget.scaleFactor,
  ).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
