import 'dart:convert';

import 'theme/app_theme.dart';

import 'package:flutter/material.dart';

import 'login_screen.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controller lấy dữ liệu nhập vào
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Biến trạng thái ẩn/hiện mật khẩu
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  // Đang gọi API đăng ký
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Kiểm tra dữ liệu, gọi backend đăng ký, rồi tự đăng nhập
  Future<void> _register() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin');
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      _showMessage('Email không hợp lệ');
      return;
    }
    if (password.length < 8) {
      _showMessage('Mật khẩu phải có ít nhất 8 ký tự');
      return;
    }
    // bcrypt chỉ dùng tối đa 72 byte
    if (utf8.encode(password).length > 72) {
      _showMessage('Mật khẩu quá dài (tối đa 72 ký tự)');
      return;
    }
    if (password != confirm) {
      _showMessage('Mật khẩu nhập lại không khớp');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.register(email: email, password: password);

      if (!mounted) return;
      _showMessage('Đăng ký thành công, vui lòng đăng nhập');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (e) {
      debugPrint('Register error: $e');
      _showMessage('Không kết nối được máy chủ, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 1. Tiêu đề Create an account
              Text(
                'Tạo tài khoản\nmới',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                  height: 1.2,
                ),
              ),

              SizedBox(height: 32),

              // 2. Ô nhập Email
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.person,
                    color: context.colors.textSecondary,
                  ),
                  filled: true,
                  fillColor: context.colors.surfaceAlt,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 3. Ô nhập Password
              TextField(
                controller: _passwordController,
                obscureText: _isPasswordHidden,
                decoration: InputDecoration(
                  hintText: 'Mật khẩu',
                  hintStyle: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.lock,
                    color: context.colors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.colors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: context.colors.surfaceAlt,
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                ),
              ),

              SizedBox(height: 20),

              // 4. Ô nhập Confirm Password
              TextField(
                controller: _confirmPasswordController,
                obscureText: _isConfirmPasswordHidden,
                decoration: InputDecoration(
                  hintText: 'Xác nhận mật khẩu',
                  hintStyle: TextStyle(
                    color: context.colors.textMuted,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.lock,
                    color: context.colors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: context.colors.textSecondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: context.colors.surfaceAlt,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: context.colors.border),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 5. Điều khoản
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  children: const [
                    TextSpan(text: 'Khi bấm nút '),
                    TextSpan(
                      text: 'Tạo tài khoản',
                      style: TextStyle(color: Color(0xFFFF4B2B)),
                    ),
                    TextSpan(text: ', bạn đồng ý với điều khoản sử dụng'),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 6. Nút Create Account
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF83758),
                    disabledBackgroundColor: const Color(0xFFF83758)
                        .withValues(alpha: 0.6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Tạo tài khoản',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 9. Dòng chữ "I Already Have an Account Login"
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Đã có tài khoản? ',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng nhập',
                        style: TextStyle(
                          color: Color(0xFFF83758),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
