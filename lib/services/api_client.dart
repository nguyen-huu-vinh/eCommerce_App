import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

/// Gọi API backend, tự gắn token, xử lý hết phiên đăng nhập và lỗi từ server.
/// Trả về JSON đã giải mã (hoặc null nếu phản hồi rỗng).
Future<dynamic> apiCall(
  String method,
  String path, {
  Object? body,
  bool auth = true,
}) async {
  final headers = <String, String>{'Content-Type': 'application/json'};
  if (auth) {
    final token = await AuthService.getToken();
    if (token == null) throw ApiException('Vui lòng đăng nhập để tiếp tục');
    headers['Authorization'] = 'Bearer $token';
  }

  final request = http.Request(method, Uri.parse('$baseUrl$path'))
    ..headers.addAll(headers);
  if (body != null) request.body = jsonEncode(body);

  final res = await http.Response.fromStream(
    await request.send().timeout(const Duration(seconds: 70)),
  );

  if (res.statusCode == 401 && auth) {
    await AuthService.logout();
    throw ApiException('Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại');
  }
  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(_errorMessage(res));
  }
  if (res.bodyBytes.isEmpty) return null;
  return jsonDecode(utf8.decode(res.bodyBytes));
}

String _errorMessage(http.Response res) {
  try {
    final detail = jsonDecode(utf8.decode(res.bodyBytes))['detail'];
    if (detail == 'Not Found') return 'Máy chủ chưa hỗ trợ tính năng này';
    if (detail is String) return detail;
    if (res.statusCode == 422) return 'Thông tin không hợp lệ';
  } catch (_) {}
  return 'Có lỗi xảy ra (mã ${res.statusCode})';
}

/// Thông báo thân thiện cho mọi loại lỗi (mất mạng, timeout...)
String errorText(Object error) =>
    error is ApiException ? error.message : 'Không thể kết nối máy chủ, vui lòng thử lại';
