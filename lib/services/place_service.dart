import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Một địa điểm tìm được từ OpenStreetMap.
class Place {
  final String name;
  final LatLng position;

  const Place(this.name, this.position);
}

/// Gợi ý địa chỉ và đổi toạ độ ra địa chỉ bằng OpenStreetMap Nominatim.
/// Nominatim yêu cầu User-Agent riêng và tối đa 1 yêu cầu mỗi giây, nên
/// nơi gọi phải chờ người dùng ngừng gõ rồi mới tìm.
class PlaceService {
  static const _headers = {
    'User-Agent': 'StylishShop/1.0 (address autocomplete)',
    'Accept-Language': 'vi',
  };

  static Future<List<Place>> search(String query) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'countrycodes': 'vn',
      'limit': '5',
    });
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return [];
    final list = jsonDecode(utf8.decode(response.bodyBytes)) as List;
    return [
      for (final item in list)
        Place(
          item['display_name'] as String,
          LatLng(
            double.parse(item['lat'] as String),
            double.parse(item['lon'] as String),
          ),
        ),
    ];
  }

  /// Địa chỉ tại một điểm trên bản đồ; null nếu không tìm được.
  static Future<String?> reverse(LatLng point) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': '${point.latitude}',
      'lon': '${point.longitude}',
      'format': 'jsonv2',
    });
    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    return data is Map ? data['display_name'] as String? : null;
  }
}
