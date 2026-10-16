import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../services/wishlist_controller.dart';
import '../theme/app_theme.dart';

/// Nút trái tim nhỏ đặt trên ảnh sản phẩm: bấm để thích / bỏ thích,
/// trái tim nảy lên một nhịp và máy rung nhẹ.
class FavoriteButton extends StatefulWidget {
  final Product product;
  const FavoriteButton({super.key, required this.product});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wishlist = WishlistController.instance;
    return ListenableBuilder(
      listenable: wishlist,
      builder: (context, _) {
        final liked = wishlist.contains(widget.product.id);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            final added = wishlist.toggle(widget.product);
            HapticFeedback.selectionClick();
            if (added) _controller.forward(from: 0);
          },
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: context.colors.surface.withValues(alpha: 0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 4,
                ),
              ],
            ),
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                size: 17,
                color: liked ? brandPink : context.colors.textSecondary,
              ),
            ),
          ),
        );
      },
    );
  }
}
