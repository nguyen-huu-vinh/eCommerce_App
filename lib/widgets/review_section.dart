import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

import 'package:google_fonts/google_fonts.dart';

import '../models/review.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import 'review_sheet.dart';

/// Mục đánh giá ở trang chi tiết sản phẩm: điểm trung bình, phân bố sao,
/// danh sách nhận xét và nút viết đánh giá (chỉ khi đã nhận hàng).
class ReviewSection extends StatefulWidget {
  final int productId;
  final String productName;

  /// Gọi sau khi người dùng thêm / sửa / xóa đánh giá để trang cha tải lại điểm
  final VoidCallback? onChanged;

  const ReviewSection({
    super.key,
    required this.productId,
    required this.productName,
    this.onChanged,
  });

  @override
  State<ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  static const _gold = Color(0xFFEDB310);
  static const _collapsedCount = 3;

  ReviewSummary? _summary;
  MyReviewStatus? _mine;
  bool _loading = true;
  bool _expanded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await ReviewService.fetch(widget.productId);
      MyReviewStatus? mine;
      if (await AuthService.hasValidToken()) {
        try {
          mine = await ReviewService.myStatus(widget.productId);
        } catch (_) {
          // Không lấy được trạng thái của tôi thì chỉ ẩn nút viết đánh giá
        }
      }
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _mine = mine;
      });
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _write() async {
    final changed = await showReviewSheet(
      context,
      productId: widget.productId,
      productName: widget.productName,
    );
    if (changed == true) {
      await _load();
      widget.onChanged?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final canReview = _mine?.canReview ?? false;
    final hasMine = _mine?.review != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Đánh giá sản phẩm',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (canReview)
              TextButton.icon(
                onPressed: _write,
                icon: Icon(
                  hasMine ? Icons.edit_outlined : Icons.rate_review_outlined,
                  size: 18,
                ),
                label: Text(hasMine ? 'Sửa đánh giá' : 'Viết đánh giá'),
                style: TextButton.styleFrom(foregroundColor: brandPink),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading && summary == null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
          )
        else if (_error != null && summary == null)
          Row(
            children: [
              Expanded(
                child: Text(
                  _error!,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
              TextButton(onPressed: _load, child: Text('Thử lại')),
            ],
          )
        else if (summary != null && summary.count == 0)
          Text(
            'Chưa có đánh giá nào. Hãy là người đầu tiên sau khi nhận hàng!',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: context.colors.textSecondary,
            ),
          )
        else if (summary != null) ...[
          _buildSummary(summary),
          const SizedBox(height: 14),
          for (final review in summary.reviews.take(
            _expanded ? summary.reviews.length : _collapsedCount,
          ))
            _ReviewTile(review: review),
          if (summary.reviews.length > _collapsedCount)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded
                      ? 'Thu gọn'
                      : 'Xem tất cả ${summary.reviews.length} đánh giá',
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSummary(ReviewSummary summary) {
    final maxCount = summary.distribution.values.fold<int>(
      1,
      (a, b) => a > b ? a : b,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          children: [
            Text(
              summary.average?.toStringAsFixed(1) ?? '-',
              style: GoogleFonts.montserrat(
                fontSize: 34,
                fontWeight: FontWeight.w800,
              ),
            ),
            _Stars(rating: summary.average ?? 0, size: 14),
            SizedBox(height: 2),
            Text(
              '${summary.count} đánh giá',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (var star = 5; star >= 1; star--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 12,
                        child: Text(
                          '$star',
                          style: GoogleFonts.montserrat(fontSize: 11),
                        ),
                      ),
                      const Icon(Icons.star_rounded, size: 12, color: _gold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (summary.distribution[star] ?? 0) / maxCount,
                            minHeight: 6,
                            color: _gold,
                            backgroundColor: context.colors.surfaceAlt,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${summary.distribution[star] ?? 0}',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  final double rating;
  final double size;

  const _Stars({required this.rating, required this.size});

  @override
  Widget build(BuildContext context) {
    final full = rating.floor();
    final hasHalf = rating - full >= 0.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++)
          Icon(
            i < full
                ? Icons.star_rounded
                : (i == full && hasHalf
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
            size: size,
            color: const Color(0xFFEDB310),
          ),
      ],
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;

  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final comment = review.comment;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                review.dateLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _Stars(rating: review.rating.toDouble(), size: 14),
          if (comment != null && comment.isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              comment,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                height: 1.45,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
