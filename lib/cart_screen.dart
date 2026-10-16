import 'widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'services/cart_controller.dart';
import 'checkout_screen.dart';
import 'utils/currency.dart';
import 'utils/network_image.dart';

class CartScreen extends StatelessWidget {
  final CartController controller;
  final VoidCallback? onBack;

  const CartScreen({super.key, required this.controller, this.onBack});

  static const _pink = Color(0xFFFE3E6C);

  Future<void> _confirmClear(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Xóa toàn bộ giỏ hàng?',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Tất cả sản phẩm trong giỏ sẽ bị xóa.',
          style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _pink),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true) controller.clear();
  }

  /// Xóa một dòng và cho phép hoàn tác trong vài giây
  void _removeWithUndo(BuildContext context, CartItem item) {
    controller.remove(item);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Đã xóa "${item.product.name}"',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          action: SnackBarAction(
            label: 'Hoàn tác',
            textColor: const Color(0xFFFF8DA8),
            onPressed: () => controller.restore(item),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: AppBar(
        backgroundColor: context.colors.page,
        elevation: 0,
        centerTitle: true,
        leading: onBack == null
            ? null
            : IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: context.colors.textPrimary,
                ),
                onPressed: onBack,
              ),
        title: Text(
          'Giỏ hàng',
          style: GoogleFonts.montserrat(
            color: context.colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) => controller.items.isEmpty
                ? const SizedBox(width: 12)
                : IconButton(
                    tooltip: 'Xóa toàn bộ giỏ hàng',
                    onPressed: () => _confirmClear(context),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final items = controller.items;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Giỏ hàng đang trống',
              message: 'Hãy chọn món đồ bạn yêu thích và thêm vào giỏ nhé',
              actionLabel: 'Mua sắm ngay',
              onAction: onBack ?? () => Navigator.maybePop(context),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 116),
            children: [
              Text(
                '${controller.itemCount} sản phẩm',
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              for (final item in items) ...[
                Dismissible(
                  key: ValueKey('cart-${item.product.id}-${item.size}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeWithUndo(context, item),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  child: _CartItemTile(
                    item: item,
                    canIncrease: controller.canAddMore(item.product),
                    onQuantityChanged: (quantity) =>
                        controller.setQuantity(item, quantity),
                    onRemove: () => _removeWithUndo(context, item),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 10),
              _OrderSummary(
                subtotal: formatVnd(controller.subtotal),
                total: formatVnd(controller.subtotal),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _pink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => CheckoutScreen(controller: controller),
                    ),
                  ),
                  child: Text(
                    'Tiến hành thanh toán',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final bool canIncrease;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.canIncrease,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image(
              image: cachedImage(item.product.imageUrl, width: 250),
              width: 82,
              height: 96,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                width: 82,
                height: 96,
                color: context.colors.surfaceAlt,
                child: const Icon(Icons.image_not_supported_outlined),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Xóa sản phẩm',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (item.size != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Kích cỡ: ${item.size}',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
                SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      formatVnd(item.unitPrice),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: item.isDiscounted
                            ? Color(0xFFFE3E6C)
                            : context.colors.textPrimary,
                      ),
                    ),
                    if (item.isDiscounted)
                      Text(
                        formatVnd(item.product.price),
                        style: GoogleFonts.montserrat(
                          fontSize: 11,
                          color: context.colors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onPressed: () => onQuantityChanged(item.quantity - 1),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      // Đủ số lượng còn trong kho thì không cho tăng nữa
                      onPressed: canIncrease
                          ? () => onQuantityChanged(item.quantity + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    height: 28,
    child: IconButton.filledTonal(
      tooltip: icon == Icons.add ? 'Tăng số lượng' : 'Giảm số lượng',
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      style: IconButton.styleFrom(
        foregroundColor: context.colors.textPrimary,
        backgroundColor: context.colors.surfaceAlt,
      ),
    ),
  );
}

class _OrderSummary extends StatelessWidget {
  final String subtotal;
  final String total;

  const _OrderSummary({required this.subtotal, required this.total});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: context.colors.border),
        bottom: BorderSide(color: context.colors.border),
      ),
    ),
    child: Column(
      children: [
        _SummaryRow(label: 'Tạm tính', value: subtotal),
        SizedBox(height: 10),
        _SummaryRow(label: 'Phí vận chuyển', value: 'Miễn phí'),
        SizedBox(height: 12),
        _SummaryRow(label: 'Tổng cộng', value: total, emphasized: true),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: emphasized ? 14 : 12,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
            color: context.colors.textSecondary,
          ),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.montserrat(
          fontSize: emphasized ? 14 : 12,
          fontWeight: FontWeight.w700,
          color: emphasized ? context.colors.textPrimary : context.colors.textSecondary,
        ),
      ),
    ],
  );
}
