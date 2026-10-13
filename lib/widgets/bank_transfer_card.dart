import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/order.dart';
import '../utils/currency.dart';

/// Mã VietQR kèm thông tin tài khoản để khách quét bằng app ngân hàng
class BankTransferCard extends StatelessWidget {
  final BankTransfer transfer;

  const BankTransferCard({super.key, required this.transfer});

  static const _pink = Color(0xFFFE3E6C);

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Đã sao chép $label')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFD3DE)),
      ),
      child: Column(
        children: [
          Text(
            'Quét mã QR để thanh toán',
            style: GoogleFonts.montserrat(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Mở app ngân hàng bất kỳ và quét mã bên dưới.\n'
            'Số tiền và nội dung đã được điền sẵn.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              height: 1.5,
              color: const Color(0xFF777777),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                transfer.qrUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(color: _pink),
                      ),
                errorBuilder: (context, error, stack) => Container(
                  color: const Color(0xFFF5F5F5),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Không tải được mã QR.\n'
                    'Bạn vẫn có thể chuyển khoản theo thông tin bên dưới.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CopyRow(label: 'Ngân hàng', value: transfer.bankId),
          _CopyRow(
            label: 'Số tài khoản',
            value: transfer.accountNo,
            onCopy: () => _copy(context, 'số tài khoản', transfer.accountNo),
          ),
          _CopyRow(label: 'Chủ tài khoản', value: transfer.accountName),
          _CopyRow(
            label: 'Số tiền',
            value: formatVnd(transfer.amount),
            onCopy: () =>
                _copy(context, 'số tiền', transfer.amount.round().toString()),
          ),
          _CopyRow(
            label: 'Nội dung',
            value: transfer.content,
            highlight: true,
            onCopy: () => _copy(context, 'nội dung', transfer.content),
          ),
          const SizedBox(height: 8),
          Text(
            'Đơn sẽ được xác nhận sau khi cửa hàng nhận được tiền.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11,
              color: const Color(0xFF777777),
            ),
          ),
        ],
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final VoidCallback? onCopy;

  const _CopyRow({
    required this.label,
    required this.value,
    this.highlight = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 36,
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: const Color(0xFF777777),
            ),
          ),
        ),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? const Color(0xFFFE3E6C)
                  : const Color(0xFF222222),
            ),
          ),
        ),
        SizedBox(
          width: 32,
          child: onCopy == null
              ? null
              : IconButton(
                  tooltip: 'Sao chép $label',
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                  onPressed: onCopy,
                  icon: const Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: Color(0xFF777777),
                  ),
                ),
        ),
      ],
    ),
  );
}
