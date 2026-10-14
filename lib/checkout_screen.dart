import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'address_book_screen.dart';
import 'login_screen.dart';
import 'order_success_screen.dart';
import 'models/address.dart';
import 'services/address_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/cart_controller.dart';
import 'services/coupon_service.dart';
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
  final _couponController = TextEditingController();
  String _paymentMethod = 'cod';
  bool _submitting = false;
  // Chưa đăng nhập hoặc phiên hết hạn: báo ngay, không để điền xong mới lỗi
  bool _needsLogin = false;

  // Mã giảm giá đã được server xác nhận cho tạm tính hiện tại
  CouponResult? _coupon;
  String? _couponError;
  bool _applyingCoupon = false;

  // Sổ địa chỉ: gợi ý lưu địa chỉ mới nhập vào sổ sau khi đặt hàng
  bool _addressBookEmpty = false;
  bool _saveToBook = false;
  bool _usedSavedAddress = false;

  @override
  void initState() {
    super.initState();
    _checkLogin();
    _prefillShipping();
  }

  /// Điền sẵn thông tin lần đặt trước, hoặc họ tên trong hồ sơ
  Future<void> _prefillShipping() async {
    try {
      final saved = await AddressService.list();
      if (!mounted) return;
      if (saved.isEmpty) {
        setState(() {
          _addressBookEmpty = true;
          _saveToBook = true;
        });
      } else {
        final preferred = saved.firstWhere(
          (a) => a.isDefault,
          orElse: () => saved.first,
        );
        _applyAddress(preferred);
        return;
      }
    } catch (_) {
      // Chưa đăng nhập hoặc mất mạng: dùng thông tin lần đặt trước
    }

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

  void _applyAddress(SavedAddress address) {
    setState(() {
      _nameController.text = address.fullName;
      _phoneController.text = address.phone;
      _addressController.text = address.address;
      _usedSavedAddress = true;
      _saveToBook = false;
    });
  }

  Future<void> _pickAddress() async {
    final picked = await Navigator.push<SavedAddress>(
      context,
      MaterialPageRoute(
        builder: (_) => const AddressBookScreen(pickMode: true),
      ),
    );
    if (picked != null && mounted) _applyAddress(picked);
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty || _applyingCoupon) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });
    try {
      final result = await CouponService.validate(
        code,
        widget.controller.subtotal,
      );
      if (mounted) setState(() => _coupon = result);
    } catch (e) {
      if (mounted) setState(() => _couponError = errorText(e));
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  void _removeCoupon() => setState(() {
    _coupon = null;
    _couponError = null;
    _couponController.clear();
  });

  void _fillIfEmpty(TextEditingController controller, String value) {
    if (controller.text.isEmpty) controller.text = value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    _couponController.dispose();
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
        couponCode: _coupon?.code,
      );
      await OrderService.saveLastShipping(shipping);
      if (_saveToBook && !_usedSavedAddress) {
        try {
          await AddressService.create(
            fullName: shipping.fullName,
            phone: shipping.phone,
            address: shipping.address,
            isDefault: true,
          );
        } catch (_) {
          // Lưu sổ địa chỉ chỉ là tiện ích, đơn đã đặt xong
        }
      }
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

  Widget _buildCouponBox() {
    final coupon = _coupon;
    if (coupon != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE6F6EC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_rounded,
              color: Color(0xFF1E8E4A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${coupon.code} · giảm ${formatVnd(coupon.discount)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E8E4A),
                    ),
                  ),
                  if (coupon.description != null &&
                      coupon.description!.isNotEmpty)
                    Text(
                      coupon.description!,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: const Color(0xFF4F7A5E),
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Bỏ mã giảm giá',
              onPressed: _submitting ? null : _removeCoupon,
              icon: const Icon(Icons.close_rounded, size: 20),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => _applyCoupon(),
                decoration: _inputDecoration(
                  'Nhập mã giảm giá',
                  Icons.local_offer_outlined,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _applyingCoupon || _needsLogin ? null : _applyCoupon,
                child: _applyingCoupon
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Áp dụng'),
              ),
            ),
          ],
        ),
        if (_couponError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _couponError!,
              style: GoogleFonts.montserrat(
                fontSize: 11,
                color: const Color(0xFFD32F2F),
              ),
            ),
          ),
      ],
    );
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
            Row(
              children: [
                Expanded(child: _SectionTitle(title: 'Thông tin giao hàng')),
                if (!_needsLogin)
                  TextButton.icon(
                    onPressed: _pickAddress,
                    icon: const Icon(Icons.bookmark_border_rounded, size: 18),
                    label: const Text('Sổ địa chỉ'),
                    style: TextButton.styleFrom(foregroundColor: _pink),
                  ),
              ],
            ),
            const SizedBox(height: 8),
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
            if (_addressBookEmpty && !_usedSavedAddress)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _pink,
                value: _saveToBook,
                onChanged: (v) => setState(() => _saveToBook = v ?? false),
                title: Text(
                  'Lưu địa chỉ này vào sổ địa chỉ',
                  style: GoogleFonts.montserrat(fontSize: 12),
                ),
              ),
            const SizedBox(height: 22),
            _SectionTitle(title: 'Mã giảm giá'),
            const SizedBox(height: 8),
            _buildCouponBox(),
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
            if (_coupon != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tạm tính',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF555555),
                      ),
                    ),
                  ),
                  Text(
                    formatVnd(subtotal),
                    style: GoogleFonts.montserrat(fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Giảm giá (${_coupon!.code})',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: const Color(0xFF1E8E4A),
                      ),
                    ),
                  ),
                  Text(
                    '-${formatVnd(_coupon!.discount)}',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E8E4A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
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
                  formatVnd(subtotal - (_coupon?.discount ?? 0)),
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
