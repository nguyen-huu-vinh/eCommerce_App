class Review {
  final int id;
  final String userName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final raw = json['created_at'] as String;
    final hasZone = raw.endsWith('Z') || raw.contains('+');
    return Review(
      id: json['id'] as int,
      userName: json['user_name'] as String? ?? 'Khách hàng',
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      // Backend lưu giờ UTC nhưng không kèm múi giờ
      createdAt: DateTime.parse(hasZone ? raw : '${raw}Z').toLocal(),
    );
  }

  String get dateLabel {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(createdAt.day)}/${two(createdAt.month)}/${createdAt.year}';
  }
}

class ReviewSummary {
  final double? average;
  final int count;

  /// Số đánh giá theo từng mức sao (1..5)
  final Map<int, int> distribution;
  final List<Review> reviews;

  const ReviewSummary({
    required this.average,
    required this.count,
    required this.distribution,
    required this.reviews,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    final dist = (json['distribution'] as Map<String, dynamic>? ?? const {});
    return ReviewSummary(
      average: (json['average'] as num?)?.toDouble(),
      count: json['count'] as int? ?? 0,
      distribution: {
        for (var star = 1; star <= 5; star++)
          star: (dist['$star'] as num?)?.toInt() ?? 0,
      },
      reviews: (json['reviews'] as List? ?? const [])
          .map((e) => Review.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Người dùng hiện tại có được đánh giá sản phẩm này không, và đã đánh giá chưa
class MyReviewStatus {
  final bool canReview;
  final Review? review;

  const MyReviewStatus({required this.canReview, required this.review});

  factory MyReviewStatus.fromJson(Map<String, dynamic> json) => MyReviewStatus(
    canReview: json['can_review'] as bool? ?? false,
    review: json['review'] == null
        ? null
        : Review.fromJson(json['review'] as Map<String, dynamic>),
  );
}
