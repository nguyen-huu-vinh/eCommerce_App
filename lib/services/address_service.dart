import '../models/address.dart';
import 'api_client.dart';

class AddressService {
  static Future<List<SavedAddress>> list() async {
    final json = await apiCall('GET', '/addresses') as List;
    return json
        .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> _body({
    String? label,
    required String fullName,
    required String phone,
    required String address,
    required bool isDefault,
  }) => {
    if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
    'full_name': fullName.trim(),
    'phone': phone.trim(),
    'address': address.trim(),
    'is_default': isDefault,
  };

  static Future<SavedAddress> create({
    String? label,
    required String fullName,
    required String phone,
    required String address,
    bool isDefault = false,
  }) async => SavedAddress.fromJson(
    await apiCall(
          'POST',
          '/addresses',
          body: _body(
            label: label,
            fullName: fullName,
            phone: phone,
            address: address,
            isDefault: isDefault,
          ),
        )
        as Map<String, dynamic>,
  );

  static Future<void> update(
    int id, {
    String? label,
    required String fullName,
    required String phone,
    required String address,
    required bool isDefault,
  }) => apiCall(
    'PUT',
    '/addresses/$id',
    body: _body(
      label: label,
      fullName: fullName,
      phone: phone,
      address: address,
      isDefault: isDefault,
    ),
  );

  static Future<void> setDefault(int id) =>
      apiCall('POST', '/addresses/$id/default');

  static Future<void> delete(int id) => apiCall('DELETE', '/addresses/$id');
}
