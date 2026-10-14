class SavedAddress {
  final int id;
  final String? label;
  final String fullName;
  final String phone;
  final String address;
  final bool isDefault;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.fullName,
    required this.phone,
    required this.address,
    required this.isDefault,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as int,
    label: json['label'] as String?,
    fullName: json['full_name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    address: json['address'] as String? ?? '',
    isDefault: json['is_default'] as bool? ?? false,
  );
}
