import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'notification_service.dart';

const String baseUrl = 'https://stylish-backend-lyrx.onrender.com';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

/// Tài khoản chưa xác minh email: đăng nhập phải qua bước nhập OTP
class EmailNotVerifiedException extends AuthException {
  EmailNotVerifiedException(super.message);
}

class AuthService {
  static const _storage = FlutterSecureStorage();

  /// Link ảnh đại diện của người đang đăng nhập (null: dùng ảnh mặc định).
  /// Mọi chỗ hiện avatar cùng nghe biến này nên đổi ảnh là cập nhật khắp app.
  static final ValueNotifier<String?> avatarUrl = ValueNotifier(null);

  static void _setAvatar(Map<String, dynamic> profile) {
    final path = profile['avatar_url'] as String?;
    avatarUrl.value = path == null ? null : '$baseUrl$path';
  }

  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  static const _timeout = Duration(seconds: 70);

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    await _storage.write(key: _tokenKey, value: data['access_token'] as String);
    final refresh = data['refresh_token'] as String?;
    if (refresh != null) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
  }

  /// Đổi refresh token lấy phiên mới. False nếu không có hoặc đã hết hạn.
  static Future<bool> refreshSession() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) return false;
    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(_timeout);
      if (res.statusCode != 200) return false;
      await _saveSession(jsonDecode(res.body) as Map<String, dynamic>);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Xác minh email bằng OTP; thành công thì đăng nhập luôn.
  static Future<void> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/verify-email'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim(), 'otp': otp.trim()}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw AuthException(_errorMessage(res));
    await _saveSession(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> resendVerification(String email) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/resend-verification'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw AuthException(_errorMessage(res));
  }

  /// True nếu server yêu cầu xác minh email (đã gửi OTP) trước khi đăng nhập.
  static Future<bool> register({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/register'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'password': password,
            if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return data['verification_required'] == true;
    }
    throw AuthException(_errorMessage(res));
  }

  static Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/login'),
          body: {'username': email.trim(), 'password': password},
        )
        .timeout(_timeout);

    if (res.statusCode == 403) {
      throw EmailNotVerifiedException(_errorMessage(res));
    }
    if (res.statusCode != 200) {
      throw AuthException(_errorMessage(res));
    }

    await _saveSession(jsonDecode(res.body) as Map<String, dynamic>);
  }

  /// Đăng nhập bằng Google. Client ID truyền lúc build:
  /// --dart-define=GOOGLE_SERVER_CLIENT_ID=... (và GOOGLE_IOS_CLIENT_ID cho iOS)
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '612145757266-qppf42au046qfq56lfptp3i4q71cdoe8.apps.googleusercontent.com',
  );
  static const _googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '612145757266-97tj87rtcbv72v8comovo4q96b0oann9.apps.googleusercontent.com',
  );
  static bool _googleReady = false;

  static Future<void> loginWithGoogle() async {
    if (_googleServerClientId.isEmpty) {
      throw AuthException('Đăng nhập Google chưa được cấu hình trong app');
    }
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
        serverClientId: _googleServerClientId,
      );
      _googleReady = true;
    }

    final String idToken;
    try {
      final account = await google.authenticate();
      final token = account.authentication.idToken;
      if (token == null) {
        throw AuthException('Không lấy được thông tin từ Google');
      }
      idToken = token;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Bạn đã hủy đăng nhập Google');
      }
      throw AuthException(
        'Đăng nhập Google thất bại (${e.code.name}): ${e.description ?? ''}',
      );
    }

    final res = await http
        .post(
          Uri.parse('$baseUrl/login/google'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id_token': idToken}),
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw AuthException(_errorMessage(res));
    await _saveSession(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  /// Còn token chưa hết hạn hay không. Chỉ đọc hạn dùng ghi trong token nên
  /// không cần gọi mạng: mở app là biết ngay có vào thẳng trang chủ được không.
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return false;
    try {
      final parts = token.split('.');
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final exp = payload['exp'] as num?;
      if (exp == null) return true;
      final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      // Chừa 1 phút để không vào app rồi hết hạn ngay lập tức
      if (DateTime.now().isBefore(
        expiresAt.subtract(const Duration(minutes: 1)),
      )) {
        return true;
      }
    } catch (_) {
      // Token hỏng: coi như chưa đăng nhập
    }
    // Access token hết hạn: thử đổi bằng refresh token trước khi bắt đăng nhập lại
    if (await refreshSession()) return true;
    await logout();
    return false;
  }

  static Future<void> logout() {
    if (_googleReady) GoogleSignIn.instance.signOut().catchError((Object _) {});
    avatarUrl.value = null;
    NotificationService.unread.value = 0;
    return _clearSession();
  }

  static Future<void> _clearSession() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh != null) {
      // Thu hồi trên server, không chờ và bỏ qua lỗi mạng
      http
          .post(
            Uri.parse('$baseUrl/logout'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refresh_token': refresh}),
          )
          .timeout(const Duration(seconds: 10))
          .then<void>((_) {}, onError: (Object _) {});
    }
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _tokenKey);
  }

  static Future<Map<String, dynamic>?> me() async {
    final token = await getToken();
    if (token == null) return null;

    final res = await http
        .get(
          Uri.parse('$baseUrl/me'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_timeout);

    if (res.statusCode == 401) {
      await logout();
      return null;
    }
    if (res.statusCode != 200) return null;
    final profile =
        jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    _setAvatar(profile);
    return profile;
  }

  /// Tải ảnh đại diện mới lên (ảnh đã được thu nhỏ khi chọn)
  static Future<void> uploadAvatar(Uint8List bytes, String filename) async {
    final token = await getToken();
    if (token == null) throw AuthException('Bạn chưa đăng nhập');

    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/me/avatar'))
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: filename),
          );
    final res = await http.Response.fromStream(
      await request.send().timeout(_timeout),
    );
    if (res.statusCode != 200) throw AuthException(_errorMessage(res));
    _setAvatar(jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>);
  }

  static Future<void> deleteAvatar() async {
    final token = await getToken();
    if (token == null) throw AuthException('Bạn chưa đăng nhập');

    final res = await http
        .delete(
          Uri.parse('$baseUrl/me/avatar'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_timeout);
    if (res.statusCode != 200) throw AuthException(_errorMessage(res));
    avatarUrl.value = null;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    required String email,
  }) async {
    final token = await getToken();
    if (token == null) throw AuthException('Bạn chưa đăng nhập');

    final response = await http
        .put(
          Uri.parse('$baseUrl/me'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'full_name': fullName.trim(),
            'email': email.trim(),
          }),
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw AuthException(_errorMessage(response));
    }

    final data =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    _setAvatar(data);
    final refreshedToken = data['access_token'] as String?;
    if (refreshedToken != null && refreshedToken.isNotEmpty) {
      await _storage.write(key: _tokenKey, value: refreshedToken);
    }
    return data;
  }

  static Future<void> forgotPassword(String email) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email.trim()}),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) throw AuthException(_errorMessage(res));
  }

  static Future<void> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/reset-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email.trim(),
            'otp': otp.trim(),
            'new_password': newPassword,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) throw AuthException(_errorMessage(res));
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw AuthException('Bạn chưa đăng nhập');
    }

    final res = await http
        .post(
          Uri.parse('$baseUrl/change-password'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'current_password': currentPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode != 200) throw AuthException(_errorMessage(res));
  }

  static String _errorMessage(http.Response res) {
    try {
      final data = jsonDecode(utf8.decode(res.bodyBytes));
      final detail = data['detail'];
      if (detail is String) return detail;
      if (res.statusCode == 422) {
        return 'Dữ liệu không hợp lệ';
      }
    } catch (_) {}
    return 'Có lỗi xảy ra (mã ${res.statusCode})';
  }
}
