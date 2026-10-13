import 'package:flutter/material.dart';

import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'get_started_screen.dart';
// Sửa đường dẫn này cho khớp vị trí file auth_service.dart trong project của bạn
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller lấy dữ liệu nhập vào
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Biến trạng thái ẩn/hiện mật khẩu
  bool _isPasswordHidden = true;

  // Đang gọi API đăng nhập
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Xử lý đăng nhập: gọi backend, lưu token, rồi chuyển màn hình
  Future<void> _login() async {
    final email = _usernameController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Vui lòng nhập email và mật khẩu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.login(email: email, password: password);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GetStartedScreen()),
      );
    } on AuthException catch (e) {
      // Hiện đúng lý do từ máy chủ, VD sai mật khẩu
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Không kết nối được máy chủ, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // 1. Tiêu đề Welcome Back!
              const Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 32),

              // 2. Ô nhập Email (backend đăng nhập bằng email)
              TextField(
                controller: _usernameController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: const TextStyle(
                    color: Color(0xFFA8A8A9),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.person,
                    color: Color(0xFF626262),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F3F3),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFA8A8A9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFA8A8A9)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. Ô nhập Password
              TextField(
                controller: _passwordController,
                obscureText: _isPasswordHidden,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(
                    color: Color(0xFFA8A8A9),
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(Icons.lock, color: Color(0xFF626262)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordHidden
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: const Color(0xFF626262),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF3F3F3),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFA8A8A9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFA8A8A9)),
                  ),
                ),
              ),

              // 4. Nút Forgot Password?
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Color(0xFFF83758),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // 5. Nút Login đỏ (khoá lại và hiện vòng tải khi đang gọi API)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF83758),
                    disabledBackgroundColor: const Color(0xFFF83758)
                        .withOpacity(0.6),
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
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              // const SizedBox(height: 40),

              // // 6. Dòng chữ "- OR Continue with -"
              // const Center(
              //   child: Text(
              //     '- OR Continue with -',
              //     style: TextStyle(
              //       color: Color(0xFF575757),
              //       fontSize: 12,
              //     ),
              //   ),
              // ),

              // const SizedBox(height: 20),

              // // 7. Nút Đăng nhập bằng Google
              // Center(
              //   child: ElevatedButton(
              //     onPressed: () {
              //       // Xử lý đăng nhập Google
              //     },
              //     style: ElevatedButton.styleFrom(
              //       shape: const CircleBorder(),
              //     ),
              //     child: Image.asset(
              //       'assets/images/Google.png',
              //     ),
              //   ),
              // ),

              // 8. Dòng chữ "Create An Account Sign Up"
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Create An Account ',
                      style: TextStyle(color: Color(0xFF575757), fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
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
