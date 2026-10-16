import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

import 'package:flutter/services.dart';

import 'services/auth_service.dart';

class OtpResetPasswordScreen extends StatefulWidget {
  const OtpResetPasswordScreen({required this.email, super.key});

  final String email;

  @override
  State<OtpResetPasswordScreen> createState() => _OtpResetPasswordScreenState();
}

class _OtpResetPasswordScreenState extends State<OtpResetPasswordScreen> {
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _hidePassword = true;
  bool _hideConfirmPassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (otp.length != 6 || password.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Vui lòng nhập OTP 6 số và đầy đủ mật khẩu');
      return;
    }
    if (password.length < 6) {
      _showMessage('Mật khẩu mới phải có ít nhất 6 ký tự');
      return;
    }
    if (password != confirmPassword) {
      _showMessage('Xác nhận mật khẩu không khớp');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.resetPasswordWithOtp(
        email: widget.email,
        otp: otp,
        newPassword: password,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Không thể đặt lại mật khẩu. Vui lòng thử lại.');
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.maybePop(context),
                icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: context.colors.textPrimary,
                style: IconButton.styleFrom(
                  backgroundColor: context.colors.surfaceAlt,
                  padding: const EdgeInsets.all(10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Nhập mã OTP',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mã xác minh đã được gửi đến ${widget.email}',
                style: const TextStyle(
                  color: Color(0xFF676767),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _buildField(
                controller: _otpController,
                hintText: 'Nhập OTP 6 số',
                icon: Icons.pin_outlined,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _passwordController,
                hintText: 'Mật khẩu mới',
                icon: Icons.lock_outline,
                obscureText: _hidePassword,
                onToggleVisibility: () =>
                    setState(() => _hidePassword = !_hidePassword),
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _confirmPasswordController,
                hintText: 'Xác nhận mật khẩu mới',
                icon: Icons.lock_outline,
                obscureText: _hideConfirmPassword,
                onToggleVisibility: () => setState(
                  () => _hideConfirmPassword = !_hideConfirmPassword,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF83758),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Đặt lại mật khẩu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: context.colors.textMuted, fontSize: 14),
        prefixIcon: Icon(icon, color: context.colors.textSecondary),
        suffixIcon: onToggleVisibility == null
            ? null
            : IconButton(
                onPressed: onToggleVisibility,
                icon: Icon(
                  obscureText
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: context.colors.textSecondary,
                ),
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2B80FF), width: 2),
        ),
      ),
    );
  }
}
