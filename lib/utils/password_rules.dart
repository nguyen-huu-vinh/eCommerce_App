/// Quy tắc mật khẩu khớp với server: ít nhất 8 ký tự, gồm cả chữ và số.
/// Trả về thông báo lỗi, hoặc null nếu hợp lệ.
String? validatePassword(String password) {
  if (password.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự';
  if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password)) {
    return 'Mật khẩu phải gồm cả chữ và số';
  }
  return null;
}
