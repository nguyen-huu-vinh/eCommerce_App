import 'dart:async';
import 'theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'models/address.dart';
import 'services/address_service.dart';
import 'services/api_client.dart';
import 'services/place_service.dart';
import 'widgets/map_address_picker.dart';

/// Sổ địa chỉ giao hàng. Với [pickMode] = true, chạm vào một địa chỉ sẽ đóng
/// màn hình và trả địa chỉ đó về cho nơi gọi (dùng ở bước thanh toán).
class AddressBookScreen extends StatefulWidget {
  final bool pickMode;

  const AddressBookScreen({super.key, this.pickMode = false});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  static const _pink = Color(0xFFFE3E6C);

  List<SavedAddress>? _addresses;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await AddressService.list();
      if (mounted) setState(() => _addresses = list);
    } catch (e) {
      if (mounted) setState(() => _error = errorText(e));
    }
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _openForm([SavedAddress? address]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddressFormScreen(address: address)),
    );
    if (saved == true) _load();
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) _toast(errorText(e));
    }
  }

  Future<void> _confirmDelete(SavedAddress address) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xóa địa chỉ?'),
        content: Text(address.address),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _pink),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok == true) _run(() => AddressService.delete(address.id));
  }

  @override
  Widget build(BuildContext context) {
    final addresses = _addresses;
    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: AppBar(
        backgroundColor: context.colors.page,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.pickMode ? 'Chọn địa chỉ' : 'Sổ địa chỉ',
          style: GoogleFonts.montserrat(
            color: context.colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 84),
        child: FloatingActionButton.extended(
          backgroundColor: _pink,
          foregroundColor: Colors.white,
          onPressed: () => _openForm(),
          icon: const Icon(Icons.add_location_alt_outlined),
          label: const Text('Thêm địa chỉ'),
        ),
      ),
      body: _error != null && addresses == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                  TextButton(onPressed: _load, child: const Text('Thử lại')),
                ],
              ),
            )
          : addresses == null
          ? const Center(child: CircularProgressIndicator())
          : addresses.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_off_outlined,
                      size: 56,
                      color: context.colors.textMuted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Bạn chưa lưu địa chỉ nào',
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lưu địa chỉ để đặt hàng nhanh hơn',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(16, 4, 16, 196),
                itemCount: addresses.length,
                separatorBuilder: (_, _) => SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final address = addresses[index];
                  return _AddressCard(
                    address: address,
                    onTap: widget.pickMode
                        ? () => Navigator.pop(context, address)
                        : () => _openForm(address),
                    onEdit: () => _openForm(address),
                    onDelete: () => _confirmDelete(address),
                    onSetDefault: address.isDefault
                        ? null
                        : () =>
                              _run(() => AddressService.setDefault(address.id)),
                  );
                },
              ),
            ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onSetDefault;

  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final label = address.label;
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(14, 12, 6, 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: address.isDefault
                  ? Color(0xFFFE3E6C)
                  : context.colors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (label != null && label.isNotEmpty) ...[
                    Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                  ],
                  if (address.isDefault)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xFFFFEDF1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Mặc định',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD93358),
                        ),
                      ),
                    ),
                  Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Tùy chọn',
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'default') onSetDefault?.call();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'edit', child: Text('Sửa')),
                      if (onSetDefault != null)
                        PopupMenuItem(
                          value: 'default',
                          child: Text('Đặt làm mặc định'),
                        ),
                      PopupMenuItem(value: 'delete', child: Text('Xóa')),
                    ],
                  ),
                ],
              ),
              Text(
                '${address.fullName} · ${address.phone}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 3),
              Padding(
                padding: EdgeInsets.only(right: 8, bottom: 8),
                child: Text(
                  address.address,
                  style: GoogleFonts.montserrat(
                    fontSize: 12,
                    height: 1.4,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Form thêm / sửa địa chỉ; trả true nếu đã lưu
class AddressFormScreen extends StatefulWidget {
  final SavedAddress? address;

  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  static const _pink = Color(0xFFFE3E6C);
  final _formKey = GlobalKey<FormState>();
  late final _label = TextEditingController(text: widget.address?.label);
  late final _name = TextEditingController(text: widget.address?.fullName);
  late final _phone = TextEditingController(text: widget.address?.phone);
  late final _address = TextEditingController(text: widget.address?.address);
  late bool _isDefault = widget.address?.isDefault ?? false;
  bool _saving = false;

  List<Place> _suggestions = [];
  Timer? _debounce;
  LatLng? _picked;
  // Chữ vừa được điền từ gợi ý/bản đồ: không tìm gợi ý lại cho chính nó
  String? _filled;

  @override
  void initState() {
    super.initState();
    _address.addListener(_onAddressChanged);
  }

  void _onAddressChanged() {
    final text = _address.text.trim();
    if (text == _filled) return;
    _picked = null;
    _debounce?.cancel();
    if (text.length < 4) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(Duration(milliseconds: 700), () async {
      try {
        final found = await PlaceService.search(text);
        if (mounted && _address.text.trim() == text) {
          setState(() => _suggestions = found);
        }
      } catch (_) {}
    });
  }

  void _fill(Place place) {
    _filled = place.name.trim();
    _address.text = place.name;
    _picked = place.position;
    setState(() => _suggestions = []);
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickOnMap() async {
    // Mở trên navigator gốc để thanh điều hướng không che nút xác nhận
    final place = await Navigator.of(context, rootNavigator: true).push<Place>(
      MaterialPageRoute(builder: (_) => MapAddressPicker(initial: _picked)),
    );
    if (place != null && mounted) _fill(place);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _label.dispose();
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final existing = widget.address;
      if (existing == null) {
        await AddressService.create(
          label: _label.text,
          fullName: _name.text,
          phone: _phone.text,
          address: _address.text,
          isDefault: _isDefault,
        );
      } else {
        await AddressService.update(
          existing.id,
          label: _label.text,
          fullName: _name.text,
          phone: _phone.text,
          address: _address.text,
          isDefault: _isDefault,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorText(e))));
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, size: 20),
    filled: true,
    fillColor: context.colors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
  );

  @override
  Widget build(BuildContext context) {
    final editing = widget.address != null;
    // Địa chỉ mặc định đang sửa không thể tự bỏ mặc định (phải chọn cái khác)
    final lockDefault = widget.address?.isDefault ?? false;
    return Scaffold(
      backgroundColor: context.colors.page,
      appBar: AppBar(
        backgroundColor: context.colors.page,
        elevation: 0,
        centerTitle: true,
        title: Text(
          editing ? 'Sửa địa chỉ' : 'Thêm địa chỉ',
          style: GoogleFonts.montserrat(
            color: context.colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 116),
          children: [
            TextFormField(
              controller: _label,
              maxLength: 40,
              decoration: _decoration(
                'Nhãn (VD: Nhà, Công ty)',
                Icons.label_outline,
              ),
            ),
            const SizedBox(height: 4),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Họ và tên', Icons.person_outline),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _decoration('Số điện thoại', Icons.phone_outlined),
              validator: (v) {
                final phone = v?.trim() ?? '';
                if (phone.isEmpty) return 'Vui lòng nhập số điện thoại';
                if (phone.length < 9 || phone.length > 11) {
                  return 'Số điện thoại cần có từ 9 đến 11 chữ số';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: _decoration(
                'Địa chỉ nhận hàng',
                Icons.location_on_outlined,
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Vui lòng nhập địa chỉ'
                  : null,
            ),
            for (final place in _suggestions)
              ListTile(
                dense: true,
                leading: Icon(Icons.place_outlined, color: _pink),
                title: Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(fontSize: 12.5),
                ),
                onTap: () => _fill(place),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _pickOnMap,
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Chọn trên bản đồ'),
                style: TextButton.styleFrom(foregroundColor: _pink),
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: _pink,
              title: Text(
                'Đặt làm địa chỉ mặc định',
                style: GoogleFonts.montserrat(fontSize: 13),
              ),
              value: _isDefault,
              onChanged: lockDefault
                  ? null
                  : (value) => setState(() => _isDefault = value),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _pink,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Lưu địa chỉ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
