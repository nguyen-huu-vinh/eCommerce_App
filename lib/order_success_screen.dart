import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'models/order.dart';
import 'utils/currency.dart';
import 'widgets/bank_transfer_card.dart';

class OrderSuccessScreen extends StatelessWidget {
  final Order order;
  final String paymentMethod;

  const OrderSuccessScreen({
    super.key,
    required this.order,
    required this.paymentMethod,
  });

  static const _pink = Color(0xFFFE3E6C);

  @override
  Widget build(BuildContext context) {
    final transfer = order.awaitingTransfer ? order.bankTransfer : null;
    return Scaffold(
      backgroundColor: context.colors.page,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 116),
          children: [
            Icon(Icons.check_circle_rounded, color: _pink, size: 76),
            SizedBox(height: 18),
            Text(
              'Đặt hàng thành công!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Cảm ơn bạn đã mua sắm tại Stylish.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _InfoRow(label: 'Mã đơn hàng', value: order.code),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Tổng thanh toán',
                    value: formatVnd(order.total),
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: 'Thanh toán',
                    value: paymentMethod == 'bank'
                        ? 'Chuyển khoản'
                        : 'Khi nhận hàng',
                  ),
                ],
              ),
            ),
            if (transfer != null) ...[
              const SizedBox(height: 14),
              BankTransferCard(transfer: transfer),
            ],
            SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: Text(
                  transfer != null ? 'Tôi đã chuyển khoản' : 'Tiếp tục mua sắm',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            color: context.colors.textSecondary,
          ),
        ),
      ),
      Text(
        value,
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.colors.textPrimary,
        ),
      ),
    ],
  );
}
