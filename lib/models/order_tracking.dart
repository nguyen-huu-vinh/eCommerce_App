/// Một điểm trên bản đồ theo dõi đơn
class MapPoint {
  final double lat;
  final double lng;
  final String? label;

  const MapPoint({required this.lat, required this.lng, this.label});

  static MapPoint? fromJson(dynamic json, {String? labelKey}) {
    if (json is! Map<String, dynamic>) return null;
    return MapPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      label: labelKey == null ? null : json[labelKey] as String?,
    );
  }
}

/// Dữ liệu bản đồ của một đơn (GET /orders/{id}/tracking)
class OrderTracking {
  final String status;
  final MapPoint? shop;
  final MapPoint? destination;
  final MapPoint? shipper;
  final DateTime? shipperUpdatedAt;

  const OrderTracking({
    required this.status,
    this.shop,
    this.destination,
    this.shipper,
    this.shipperUpdatedAt,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    final shipper = json['shipper'] as Map<String, dynamic>?;
    final updatedAt = shipper?['updated_at'] as String?;
    return OrderTracking(
      status: json['status'] as String,
      shop: MapPoint.fromJson(json['shop'], labelKey: 'name'),
      destination: MapPoint.fromJson(json['destination'], labelKey: 'address'),
      shipper: MapPoint.fromJson(shipper),
      // Backend lưu giờ UTC nhưng không kèm múi giờ
      shipperUpdatedAt: updatedAt == null
          ? null
          : DateTime.parse(
              updatedAt.endsWith('Z') ? updatedAt : '${updatedAt}Z',
            ).toLocal(),
    );
  }

  bool get hasAnyPoint =>
      shop != null || destination != null || shipper != null;
}
