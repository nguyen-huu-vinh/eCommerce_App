import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'login_screen.dart';
import 'order_success_screen.dart';
import 'services/auth_service.dart';
import 'services/cart_controller.dart';
import 'services/order_service.dart';
import 'utils/currency.dart';

class CheckoutScreen extends StatefulWidget {
  final CartController controller;

  const CheckoutScreen({super.key, required this.controller});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _pink = Color(0xFFFE3E6C);
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();
  String _paymentMethod = 'cod';
  bool _submitting = false;
  // Chưa đăng nhập hoặc phiên hết hạn: báo ngay, không để điền xong mới lỗi
  bool _needsLogin = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _prefillShipping();
  }

  /// Điền sẵn thông tin lần đặt trước, hoặc họ tên trong hồ sơ
  Future<void> _prefillShipping() async {
    final last = await OrderService.loadLastShipping();
    if (!mounted) return;
    if (last != null) {
      _fillIfEmpty(_nameController, last.fullName);
      _fillIfEmpty(_phoneController, last.phone);
      _fillIfEmpty(_addressController, last.address);
    }
    if (_nameController.text.isNotEmpty) return;

    try {
      final profile = await AuthService.me();
      final fullName = profile?['full_name'] as String?;
      if (mounted && fullName != null) _fillIfEmpty(_nameController, fullName);
    } catch (_) {
      // Không lấy được hồ sơ thì để người dùng tự nhập
    }
  }

  Future<void> _checkLogin() async {
    final loggedIn = await AuthService.hasValidToken();
    if (mounted && !loggedIn) setState(() => _needsLogin = true);
  }

  void _goToLogin() {
    // Giỏ hàng đã lưu trên máy nên đăng nhập xong vẫn còn nguyên
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _fillIfEmpty(TextEditingController controller, String value) {
    if (controller.text.isEmpty) controller.text = value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (widget.controller.items.isEmpty) {
      Navigator.pop(context);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    final shipping = ShippingInfo(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );

    try {
      final order = await OrderService.placeOrder(
        items: widget.controller.items,
        shipping: shipping,
        paymentMethod: _paymentMethod,
        note: _noteController.text,
      );
      await OrderService.saveLastShipping(shipping);
      if (!mounted) return;
      widget.controller.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              OrderSuccessScreen(order: order, paymentMethod: _paymentMethod),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is OrderException
          ? error.message
          : 'Không thể kết nối máy chủ, vui lòng thử lại';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E3E3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E3E3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _pink),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final subtotal = widget.controller.subtotal;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        title: Text(
          'Thanh toán',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF222222),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
          children: [
            if (_needsLogin) ...[
              _LoginRequiredCard(onLogin: _goToLogin),
              const SizedBox(height: 16),
            ],
            _SectionTitle(title: 'Thông tin giao hàng'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: _inputDecoration('Họ và tên', Icons.person_outline),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập họ tên'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _inputDecoration(
                'Số điện thoại',
                Icons.phone_outlined,
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';
                if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
                if (phone.length < 9 || phone.length > 11) {
                  return 'Số điện thoại cần có từ 9 đến 11 chữ số';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressController,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Địa chỉ nhận hàng',
                Icons.location_on_outlined,
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập địa chỉ nhận hàng'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _noteController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Ghi chú (không bắt buộc)',
                Icons.edit_note_rounded,
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle(title: 'Phương thức thanh toán'),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: _paymentMethod,
              onChanged: (value) {
                if (value != null) setState(() => _paymentMethod = value);
              },
              child: Column(
                children: [
                  _PaymentOption(
                    value: 'cod',
                    groupValue: _paymentMethod,
                    title: 'Thanh toán khi nhận hàng',
                    subtitle: 'Tiền mặt khi giao hàng',
                    icon: Icons.local_shipping_outlined,
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value),
                  ),
                  const SizedBox(height: 8),
                  _PaymentOption(
                    value: 'bank',
                    groupValue: _paymentMethod,
                    title: 'Chuyển khoản ngân hàng',
                    subtitle: 'Quét mã QR bằng app ngân hàng',
                    icon: Icons.account_balance_outlined,
                    onChanged: (value) =>
                        setState(() => _paymentMethod = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _SectionTitle(title: 'Đơn hàng của bạn'),
            const SizedBox(height: 10),
            for (final item in widget.controller.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.product.name} × ${item.quantity}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          color: const Color(0xFF555555),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatVnd(item.lineTotal),
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tổng thanh toán',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  formatVnd(subtotal),
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Miễn phí vận chuyển',
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: const Color(0xFF777777),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _submitting || _needsLogin ? null : _placeOrder,
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Xác nhận đơn hàng',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginRequiredCard extends StatelessWidget {
  final VoidCallback onLogin;

  const _LoginRequiredCard({required this.onLogin});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFEDF1),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        const Icon(Icons.lock_outline_rounded, color: Color(0xFFD93358)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Bạn cần đăng nhập để đặt hàng',
            style: GoogleFonts.montserrat(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF7A1D33),
            ),
          ),
        ),
        TextButton(
          onPressed: onLogin,
          style: TextButton.styleFrom(foregroundColor: const Color(0xFFD93358)),
          child: const Text('Đăng nhập'),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: GoogleFonts.montserrat(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF252525),
    ),
  );
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _PaymentOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? const Color(0xFFFE3E6C) : const Color(0xFFE3E3E3),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF555555), size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      color: const Color(0xFF777777),
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(value: value, activeColor: const Color(0xFFFE3E6C)),
          ],
        ),
      ),
    );
  }
}
