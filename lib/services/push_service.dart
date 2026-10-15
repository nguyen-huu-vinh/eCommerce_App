import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../my_orders_screen.dart';
import 'api_client.dart';

/// Khóa toàn cục để hiện thông báo và mở màn hình từ ngoài cây widget
/// (tin nhắn push đến lúc nào cũng được, không gắn với màn hình cụ thể).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Push notification qua Firebase Cloud Messaging (FCM).
///
/// Luồng: app xin quyền -> FCM cấp "token" riêng cho máy này -> app gửi token
/// lên backend -> khi đơn đổi trạng thái, backend nhờ FCM đẩy tin tới token đó.
/// Chưa cấu hình Firebase (thiếu google-services.json) thì mọi hàm ở đây
/// chỉ bỏ qua, app vẫn chạy bình thường.
class PushService {
  static bool _ready = false;
  static String? _token;
  // Tin được bấm lúc app tắt: giữ lại tới khi splash chuyển xong màn hình
  static RemoteMessage? _pending;

  /// Gọi một lần ở main(), trước runApp.
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase chưa được cấu hình, tắt push: $e');
      return;
    }
    _ready = true;
    final messaging = FirebaseMessaging.instance;

    // Đang mở app: hệ điều hành không tự hiện thông báo nên ta tự hiện banner
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: Duration(seconds: 6),
            content: Text(
              '${notification.title ?? ''}\n${notification.body ?? ''}'.trim(),
            ),
            action: SnackBarAction(
              label: 'Xem',
              onPressed: () => _openOrders(message),
            ),
          ),
        );
    });

    // Bấm vào thông báo khi app đang chạy nền
    FirebaseMessaging.onMessageOpenedApp.listen(_openOrders);

    // Bấm vào thông báo khi app đã bị tắt hẳn
    _pending = await messaging.getInitialMessage();

    // FCM thỉnh thoảng đổi token: gửi lại cho server để không mất thông báo
    messaging.onTokenRefresh.listen((token) {
      _token = token;
      _sendToken(token);
    });
  }

  /// Gọi sau khi đăng nhập (hoặc khi mở app lúc đã đăng nhập sẵn).
  static Future<void> registerDevice() async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      // Android 13+ và iOS bắt buộc người dùng đồng ý mới được hiện thông báo
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (Platform.isIOS) {
        // iOS cần token APNs trước khi FCM cấp được token; simulator không có
        // nên bỏ qua thay vì treo hoặc báo lỗi
        String? apns;
        for (var i = 0; i < 5 && apns == null; i++) {
          apns = await messaging.getAPNSToken();
          if (apns == null) await Future<void>.delayed(Duration(seconds: 1));
        }
        if (apns == null) {
          debugPrint('Chưa có token APNs (simulator?), bỏ qua đăng ký push');
          return;
        }
      }
      final token = await messaging.getToken();
      if (token == null) return;
      _token = token;
      await _sendToken(token);
    } catch (e) {
      debugPrint('Đăng ký thiết bị push thất bại: $e');
    }
  }

  /// Gọi trước khi đăng xuất: máy này thôi nhận thông báo của tài khoản cũ.
  /// Phải gọi trước AuthService.logout vì cần token đăng nhập để báo server.
  static Future<void> unregisterDevice() async {
    final token = _token;
    if (!_ready || token == null) return;
    try {
      await apiCall(
        'POST',
        '/me/devices/unregister',
        body: {'token': token, 'platform': _platform},
      );
    } catch (e) {
      debugPrint('Hủy đăng ký thiết bị push thất bại: $e');
    }
  }

  /// Splash gọi sau khi đã vào trang chủ để mở màn hình mà thông báo trỏ tới.
  static void openPending() {
    final message = _pending;
    _pending = null;
    if (message != null) _openOrders(message);
  }

  static String get _platform => Platform.isIOS ? 'ios' : 'android';

  static Future<void> _sendToken(String token) async {
    try {
      await apiCall(
        'POST',
        '/me/devices',
        body: {'token': token, 'platform': _platform},
      );
    } catch (e) {
      // Chưa đăng nhập hoặc mất mạng: lần mở app sau sẽ gửi lại
      debugPrint('Gửi token push lên server thất bại: $e');
    }
  }

  static void _openOrders(RemoteMessage message) {
    if (message.data['type'] != 'order') return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
    );
  }
}
