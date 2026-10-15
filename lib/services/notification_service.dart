import 'package:flutter/foundation.dart';

import 'api_client.dart';

/// Một thông báo trong hộp thư của người dùng.
class AppNotification {
  final int id;
  final String title;
  final String body;
  final int? orderId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.orderId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as int,
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        orderId: json['order_id'] as int?,
        isRead: json['is_read'] as bool? ?? false,
        // Server trả giờ UTC không kèm múi giờ
        createdAt: DateTime.parse('${json['created_at']}Z').toLocal(),
      );

  AppNotification copyWith({bool? isRead}) => AppNotification(
    id: id,
    title: title,
    body: body,
    orderId: orderId,
    isRead: isRead ?? this.isRead,
    createdAt: createdAt,
  );
}

/// Hộp thư thông báo; [unread] dùng cho chấm đỏ trên chuông ở trang chủ.
class NotificationService {
  static final ValueNotifier<int> unread = ValueNotifier(0);

  /// Cập nhật số chưa đọc; lỗi mạng hay chưa đăng nhập thì giữ nguyên số cũ.
  static Future<void> refreshUnread() async {
    try {
      final data = await apiCall('GET', '/me/notifications/unread-count');
      unread.value = (data as Map<String, dynamic>)['unread'] as int? ?? 0;
    } catch (_) {}
  }

  static Future<List<AppNotification>> fetchAll() async {
    final data =
        await apiCall('GET', '/me/notifications') as Map<String, dynamic>;
    unread.value = data['unread'] as int? ?? 0;
    return (data['items'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markRead(int id) async {
    final data = await apiCall(
      'POST',
      '/me/notifications/$id/read',
    ) as Map<String, dynamic>;
    unread.value = data['unread'] as int? ?? 0;
  }

  static Future<void> markAllRead() async {
    await apiCall('POST', '/me/notifications/read-all');
    unread.value = 0;
  }
}
