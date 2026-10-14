import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'address_book_screen.dart';
import 'change_password_screen.dart';
import 'edit_account_screen.dart';
import 'login_screen.dart';
import 'my_orders_screen.dart';
import 'services/auth_service.dart';
import 'services/cart_controller.dart';
import 'services/order_service.dart';
import 'services/wishlist_controller.dart';
import 'widgets/user_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _pink = Color(0xFFFE3E6C);
  static const _pageColor = Color(0xFFF7F7F8);

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  bool _uploadingAvatar = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await AuthService.me();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải thông tin tài khoản.';
        _isLoading = false;
      });
    }
  }

  Future<void> _openEditor() async {
    final updatedProfile = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => EditAccountScreen(profile: _profile!)),
    );
    if (!mounted || updatedProfile == null) return;
    setState(() => _profile = updatedProfile);
    _showMessage('Thông tin tài khoản đã được cập nhật');
  }

  Future<void> _showAvatarOptions() async {
    final hasAvatar = AuthService.avatarUrl.value != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(sheetContext, 'gallery'),
            ),
            if (hasAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: _pink),
                title: const Text(
                  'Xóa ảnh đại diện',
                  style: TextStyle(color: _pink),
                ),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'delete') {
      await _runAvatarTask(AuthService.deleteAvatar, 'Đã xóa ảnh đại diện');
      return;
    }

    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        // Thu nhỏ ngay trên máy: ảnh gửi đi chỉ còn vài chục KB
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
    } catch (_) {
      _showMessage(
        choice == 'camera'
            ? 'Không mở được máy ảnh, hãy kiểm tra quyền truy cập máy ảnh'
            : 'Không mở được thư viện ảnh, hãy kiểm tra quyền truy cập ảnh',
      );
      return;
    }
    if (picked == null) return; // người dùng bấm hủy
    final bytes = await picked.readAsBytes();
    await _runAvatarTask(
      () => AuthService.uploadAvatar(bytes, picked!.name),
      'Đã cập nhật ảnh đại diện',
    );
  }

  Future<void> _runAvatarTask(
    Future<void> Function() task,
    String successMessage,
  ) async {
    setState(() => _uploadingAvatar = true);
    try {
      await task();
      if (mounted) _showMessage(successMessage);
    } on AuthException catch (e) {
      if (mounted) _showMessage(e.message);
    } catch (_) {
      if (mounted) _showMessage('Không kết nối được máy chủ, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _logout() async {
    // Xóa dữ liệu riêng của người này để tài khoản khác đăng nhập sau
    // không thấy giỏ hàng, yêu thích hay địa chỉ của họ
    await Future.wait([
      AuthService.logout(),
      CartController.clearSaved(),
      OrderService.clearLastShipping(),
      WishlistController.instance.clear(),
    ]);
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageColor,
      appBar: AppBar(
        backgroundColor: _pageColor,
        elevation: 0,
        // Mở từ tab Cài đặt thì là trang gốc, không có gì để quay lại
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                tooltip: 'Quay lại',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                color: const Color(0xFF222222),
              )
            : null,
        title: Text(
          'Tài khoản của tôi',
          style: GoogleFonts.montserrat(
            color: const Color(0xFF222222),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_profile != null && !_isLoading)
            IconButton(
              tooltip: 'Chỉnh sửa tài khoản',
              onPressed: _openEditor,
              icon: const Icon(Icons.edit_outlined),
              color: _pink,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _pink))
          : _profile == null
          ? _buildUnavailable()
          : _buildProfile(),
    );
  }

  Widget _buildProfile() {
    final profile = _profile!;
    final fullName = (profile['full_name'] as String?)?.trim();
    final displayName = fullName == null || fullName.isEmpty
        ? 'Khách hàng'
        : fullName;
    final isAdmin = profile['is_admin'] as bool? ?? false;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              _buildIdentityHeader(displayName, isAdmin),
              const SizedBox(height: 16),
              _buildMenuTile(
                icon: Icons.receipt_long_outlined,
                title: 'Đơn hàng của tôi',
                screen: const MyOrdersScreen(),
              ),
              const SizedBox(height: 10),
              _buildMenuTile(
                icon: Icons.location_on_outlined,
                title: 'Sổ địa chỉ',
                screen: const AddressBookScreen(),
              ),
              const SizedBox(height: 10),
              _buildMenuTile(
                icon: Icons.lock_reset_rounded,
                title: 'Đổi mật khẩu',
                screen: const ChangePasswordScreen(),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'THÔNG TIN CÁ NHÂN',
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF777777),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFECEDEF)),
                ),
                child: Column(
                  children: [
                    _buildReadOnlyRow(
                      label: 'Họ và tên',
                      icon: Icons.badge_outlined,
                      value: displayName,
                    ),
                    const Divider(height: 1, indent: 44),
                    _buildReadOnlyRow(
                      label: 'Email',
                      icon: Icons.email_outlined,
                      value: profile['email'] as String? ?? '',
                    ),
                    const Divider(height: 1, indent: 44),
                    _buildReadOnlyRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Loại tài khoản',
                      value: isAdmin ? 'Quản trị viên' : 'Khách hàng',
                    ),
                    const Divider(height: 1, indent: 44),
                    _buildReadOnlyRow(
                      icon: Icons.numbers_outlined,
                      label: 'Mã khách hàng',
                      value: '#${profile['id']}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required Widget screen,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFECEDEF)),
        ),
        leading: Icon(icon, color: _pink),
        title: Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF252525),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9B9B9B),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => screen),
        ),
      ),
    );
  }

  Widget _buildIdentityHeader(String displayName, bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECEDEF)),
      ),
      child: Column(
        children: [
          // Bấm vào ảnh hoặc nút máy ảnh để đổi ảnh đại diện
          GestureDetector(
            onTap: _uploadingAvatar ? null : _showAvatarOptions,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE6EC),
                    shape: BoxShape.circle,
                  ),
                  child: const UserAvatar(
                    size: 96,
                    fallbackAsset:
                        'assets/images/2289_SkVNQSBGQU1PIDEwMjgtMTE2 1.png',
                  ),
                ),
                if (_uploadingAvatar)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 1,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _pink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEDF1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAdmin ? 'QUẢN TRỊ VIÊN' : 'THÀNH VIÊN STYLISH',
              style: GoogleFonts.montserrat(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFD93358),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: _pink, size: 21),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: const Color(0xFF777777),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF252525),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: Color(0xFF9B9B9B)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: Text(
                  'Đăng xuất',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDA294F),
                  side: const BorderSide(color: Color(0xFFDA294F)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailable() {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 54,
                    color: Color(0xFF999999),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage ?? 'Phiên đăng nhập không còn hợp lệ.',
                    textAlign: TextAlign.center,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadProfile,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        _buildBottomActions(),
      ],
    );
  }
}
