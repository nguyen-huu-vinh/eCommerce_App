import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  static Future<ReviewSummary> fetch(int productId) async {
    final json = await apiCall(
      'GET',
      '/products/$productId/reviews',
      auth: false,
    );
    return ReviewSummary.fromJson(json as Map<String, dynamic>);
  }

  static Future<MyReviewStatus> myStatus(int productId) async {
    final json = await apiCall('GET', '/products/$productId/reviews/me');
    return MyReviewStatus.fromJson(json as Map<String, dynamic>);
  }

  static Future<void> save(int productId, int rating, String? comment) =>
      apiCall(
        'POST',
        '/products/$productId/reviews',
        body: {
          'rating': rating,
          if (comment != null && comment.trim().isNotEmpty)
            'comment': comment.trim(),
        },
      );

  static Future<void> deleteMine(int productId) =>
      apiCall('DELETE', '/products/$productId/reviews/me');
}
