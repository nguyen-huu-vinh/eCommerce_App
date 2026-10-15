import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/review.dart';
import '../services/api_client.dart';
import '../services/review_service.dart';

/// Hộp viết / sửa đánh giá. Trả về true nếu đã lưu hoặc xóa đánh giá.
Future<bool?> showReviewSheet(
  BuildContext context, {
  required int productId,
  required String productName,
}) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useRootNavigator: true,
  useSafeArea: true,
  backgroundColor: Colors.white,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
  ),
  builder: (_) => _ReviewSheet(productId: productId, productName: productName),
);

class _ReviewSheet extends StatefulWidget {
  final int productId;
  final String productName;

  const _ReviewSheet({required this.productId, required this.productName});

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  static const _pink = Color(0xFFFE3E6C);
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _loading = true;
  bool _saving = false;
  bool _hasExisting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    try {
      final MyReviewStatus status = await ReviewService.myStatus(
        widget.productId,
      );
      if (!mounted) return;
      if (!status.canReview) {
        setState(() => _error = 'Bạn chỉ có thể đánh giá sau khi đã nhận hàng');
      }
      final existing = status.review;
      if (existing != null) {
        _rating = existing.rating;
        _commentController.text = existing.comment ?? '';
        _hasExisting = true;
      }
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      setState(() => _error = 'Vui lòng chọn số sao');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ReviewService.save(
        widget.productId,
        _rating,
        _commentController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    setState(() => _saving = true);
    try {
      await ReviewService.deleteMine(widget.productId);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = errorText(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _error == 'Bạn chỉ có thể đánh giá sau khi đã nhận hàng';
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        20 +
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).viewPadding.bottom,
      ),
      child: _loading
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasExisting ? 'Sửa đánh giá' : 'Đánh giá sản phẩm',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var star = 1; star <= 5; star++)
                        IconButton(
                          tooltip: '$star sao',
                          onPressed: blocked || _saving
                              ? null
                              : () => setState(() {
                                  _rating = star;
                                  _error = null;
                                }),
                          iconSize: 36,
                          icon: Icon(
                            star <= _rating
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFEDB310),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commentController,
                    enabled: !blocked && !_saving,
                    maxLength: 1000,
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ cảm nhận của bạn (không bắt buộc)',
                      hintStyle: GoogleFonts.montserrat(fontSize: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _error!,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (_hasExisting)
                        TextButton(
                          onPressed: _saving ? null : _delete,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFD32F2F),
                          ),
                          child: const Text('Xóa đánh giá'),
                        ),
                      const Spacer(),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _pink,
                          minimumSize: const Size(130, 44),
                        ),
                        onPressed: blocked || _saving ? null : _submit,
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Gửi đánh giá'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
