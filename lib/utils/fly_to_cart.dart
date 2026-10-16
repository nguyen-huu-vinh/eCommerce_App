import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Thả một ảnh nhỏ bay theo đường cong từ [from] tới [to] (toạ độ màn hình),
/// vừa bay vừa thu nhỏ rồi biến mất. Gọi [onDone] khi ảnh chạm đích.
void flyToCart({
  required BuildContext context,
  required Rect from,
  required Rect to,
  required ImageProvider image,
  VoidCallback? onDone,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  final controller = AnimationController(
    vsync: overlay,
    duration: const Duration(milliseconds: 650),
  );
  final curve = CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic);

  const startSize = 90.0;
  final start = from.center;
  final end = to.center;
  // Điểm uốn nằm cao hơn đường thẳng để ảnh bay thành vòng cung
  final control = Offset((start.dx + end.dx) / 2, math.min(start.dy, end.dy) - 90);

  Offset bezier(double t) {
    final u = 1 - t;
    return start * (u * u) + control * (2 * u * t) + end * (t * t);
  }

  entry = OverlayEntry(
    builder: (_) => AnimatedBuilder(
      animation: curve,
      builder: (_, _) {
        final t = curve.value;
        final size = startSize * (1 - 0.75 * t);
        final pos = bezier(t);
        return Positioned(
          left: pos.dx - size / 2,
          top: pos.dy - size / 2,
          width: size,
          height: size,
          child: IgnorePointer(
            child: Opacity(
              opacity: 1 - 0.3 * t,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 8),
                  ],
                  image: DecorationImage(image: image, fit: BoxFit.cover),
                ),
              ),
            ),
          ),
        );
      },
    ),
  );

  overlay.insert(entry);
  controller.forward().whenComplete(() {
    entry.remove();
    controller.dispose();
    onDone?.call();
  });
}
