import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../models/order_tracking.dart';
import '../services/order_service.dart';

const _pink = Color(0xFFFE3E6C);

// Nền bản đồ Esri World Street Map: giống Google Maps, tên đường tiếng Việt,
// không cần API key. Không dùng tile.openstreetmap.org vì bị chặn trên một số
// mạng ở Việt Nam; CARTO thì nay đã bắt buộc API key (chỉ trả ảnh báo lỗi).
// Lưu ý: Esri yêu cầu tài khoản ArcGIS khi dùng cho mục đích thương mại.
const _tileUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';

/// Bản đồ theo dõi đơn: cửa hàng, địa chỉ nhận và vị trí shipper.
///
/// Tự hỏi lại server mỗi 10 giây khi đang hiển thị; tạm dừng khi bị che
/// (sang tab khác, mở trang khác đè lên) để đỡ tốn pin và dữ liệu.
class OrderTrackingMap extends StatefulWidget {
  final int orderId;

  /// true: bản đồ chiếm cả màn hình, kéo/phóng to được
  final bool expanded;

  /// Gọi khi đơn không còn "đang giao" (VD shipper vừa bấm đã giao)
  final ValueChanged<String>? onStatusChanged;

  const OrderTrackingMap({
    super.key,
    required this.orderId,
    this.expanded = false,
    this.onStatusChanged,
  });

  @override
  State<OrderTrackingMap> createState() => _OrderTrackingMapState();
}

class _OrderTrackingMapState extends State<OrderTrackingMap> {
  static const _pollInterval = Duration(seconds: 10);

  final MapController _mapController = MapController();
  OrderTracking? _tracking;
  String? _error;
  Timer? _timer;
  bool _mapReady = false;
  // Người dùng tự kéo bản đồ thì thôi tự căn lại khi shipper di chuyển
  bool _userMoved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (TickerMode.valuesOf(context).enabled) {
      _timer ??= Timer.periodic(_pollInterval, (_) => _load());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final tracking = await OrderService.fetchTracking(widget.orderId);
      if (!mounted) return;
      setState(() {
        _tracking = tracking;
        _error = null;
      });
      if (tracking.status != 'shipping') {
        _timer?.cancel();
        widget.onStatusChanged?.call(tracking.status);
      }
      if (!_userMoved) _fitCamera();
    } catch (error) {
      // Lỗi tạm thời khi đã có dữ liệu thì giữ bản đồ cũ, lần sau thử lại
      if (mounted && _tracking == null) {
        setState(() => _error = 'Không tải được bản đồ');
      }
    }
  }

  // Mọi điểm cần nằm trong khung hình, gồm cả các khúc quanh của đường đi
  List<LatLng> get _points => [
    for (final point in [
      _tracking?.shop,
      _tracking?.destination,
      _tracking?.shipper,
      ...?_tracking?.route?.points,
    ])
      if (point != null) LatLng(point.lat, point.lng),
  ];

  CameraFit _cameraFit() => CameraFit.bounds(
    bounds: LatLngBounds.fromPoints(_points),
    padding: EdgeInsets.fromLTRB(48, widget.expanded ? 150 : 48, 48, 48),
    maxZoom: 16,
  );

  void _fitCamera() {
    if (!_mapReady || _points.isEmpty) return;
    _mapController.fitCamera(_cameraFit());
  }

  void _openFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              'Theo dõi đơn DH${widget.orderId}',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: OrderTrackingMap(
            orderId: widget.orderId,
            expanded: true,
            onStatusChanged: widget.onStatusChanged,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracking = _tracking;
    final height = widget.expanded ? null : 210.0;

    if (tracking == null || !tracking.hasAnyPoint) {
      return _frame(
        child: SizedBox(
          height: height ?? double.infinity,
          child: Center(
            child: tracking == null && _error == null
                ? const CircularProgressIndicator(color: _pink)
                : Text(
                    _error ?? 'Chưa xác định được vị trí trên bản đồ',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: const Color(0xFF777777),
                    ),
                  ),
          ),
        ),
      );
    }

    final map = _buildMap(tracking);
    if (widget.expanded) {
      return Stack(
        children: [
          Positioned.fill(child: map),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _InfoBanner(tracking: tracking),
          ),
          Positioned(
            right: 16,
            bottom: 32,
            child: FloatingActionButton.small(
              heroTag: null,
              tooltip: 'Căn giữa lại',
              backgroundColor: Colors.white,
              foregroundColor: _pink,
              onPressed: () {
                _userMoved = false;
                _fitCamera();
              },
              child: const Icon(Icons.center_focus_strong_rounded),
            ),
          ),
        ],
      );
    }

    return _frame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 10),
            child: Row(
              children: [
                Expanded(child: _InfoBanner(tracking: tracking, plain: true)),
                IconButton(
                  tooltip: 'Xem bản đồ lớn',
                  onPressed: _openFullScreen,
                  icon: const Icon(Icons.open_in_full_rounded, size: 20),
                ),
              ],
            ),
          ),
          SizedBox(height: height, child: map),
        ],
      ),
    );
  }

  Widget _frame({required Widget child}) => widget.expanded
      ? child
      : Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        );

  Widget _buildMap(OrderTracking tracking) {
    final shop = tracking.shop;
    final destination = tracking.destination;
    final shipper = tracking.shipper;
    LatLng at(MapPoint p) => LatLng(p.lat, p.lng);

    // Có đường theo phố thì vẽ nét liền như Grab; chưa có thì nét đứt thẳng
    // từ shipper (hoặc cửa hàng khi chưa có shipper) tới nơi nhận
    final route = tracking.route;
    final from = shipper ?? shop;
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCameraFit: _cameraFit(),
        onMapReady: () => _mapReady = true,
        onPositionChanged: (camera, hasGesture) {
          if (hasGesture) _userMoved = true;
        },
        // Thẻ nhỏ nằm trong trang cuộn: không cho kéo, bấm để mở bản đồ lớn
        onTap: widget.expanded ? null : (_, _) => _openFullScreen(),
        interactionOptions: InteractionOptions(
          flags: widget.expanded
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: _tileUrl,
          // Esri có ảnh tới mức 19; phóng to hơn thì phóng ảnh mức 19 lên
          maxNativeZoom: 19,
          // Màn hình dày điểm ảnh: tải ảnh mức cao hơn cho chữ sắc nét
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.example.ecommerce_a',
        ),
        if (route != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [for (final p in route.points) at(p)],
                color: _pink,
                strokeWidth: 5,
                borderColor: Colors.white,
                borderStrokeWidth: 2,
                strokeCap: StrokeCap.round,
                strokeJoin: StrokeJoin.round,
              ),
            ],
          )
        else if (from != null && destination != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [at(from), at(destination)],
                color: shipper != null ? _pink : const Color(0xFF9E9E9E),
                strokeWidth: 4,
                pattern: StrokePattern.dashed(segments: const [10, 8]),
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (shop != null)
              Marker(
                point: at(shop),
                width: 36,
                height: 36,
                child: const _RoundMarker(
                  icon: Icons.storefront_rounded,
                  color: Color(0xFF333333),
                ),
              ),
            if (destination != null)
              Marker(
                point: at(destination),
                width: 44,
                height: 44,
                // Mũi ghim chạm đúng vào điểm nhận hàng
                alignment: Alignment.topCenter,
                child: const Icon(
                  Icons.location_on_rounded,
                  color: _pink,
                  size: 44,
                  shadows: [Shadow(color: Colors.black26, blurRadius: 6)],
                ),
              ),
            if (shipper != null)
              Marker(
                point: at(shipper),
                width: 44,
                height: 44,
                child: const _RoundMarker(
                  icon: Icons.two_wheeler_rounded,
                  color: _pink,
                  size: 44,
                ),
              ),
          ],
        ),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('Esri, HERE, Garmin, USGS'),
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

/// Dòng trạng thái: shipper còn cách bao xa, cập nhật lúc nào
class _InfoBanner extends StatelessWidget {
  final OrderTracking tracking;
  final bool plain;

  const _InfoBanner({required this.tracking, this.plain = false});

  static String _metersText(num meters) {
    if (meters < 1000) return '${(meters / 10).round() * 10} m';
    return '${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  static String _distanceText(MapPoint a, MapPoint b) => _metersText(
    const Distance().as(
      LengthUnit.Meter,
      LatLng(a.lat, a.lng),
      LatLng(b.lat, b.lng),
    ),
  );

  static String _etaText(int seconds) {
    final minutes = (seconds / 60).ceil();
    if (minutes <= 1) return 'sắp tới';
    if (minutes < 60) return 'khoảng $minutes phút nữa';
    return 'khoảng ${minutes ~/ 60} giờ ${minutes % 60} phút nữa';
  }

  static String _agoText(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'vừa cập nhật';
    if (diff.inMinutes < 60) return 'cập nhật ${diff.inMinutes} phút trước';
    String two(int v) => v.toString().padLeft(2, '0');
    return 'cập nhật lúc ${two(time.hour)}:${two(time.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final shipper = tracking.shipper;
    final destination = tracking.destination;
    final updatedAt = tracking.shipperUpdatedAt;

    final route = tracking.route;
    final String title;
    String? subtitle;
    if (shipper != null && route != null) {
      title =
          'Shipper còn ${_metersText(route.distanceMeters)} · '
          '${_etaText(route.durationSeconds)}';
      subtitle = updatedAt == null ? null : _agoText(updatedAt);
    } else if (shipper != null && destination != null) {
      title = 'Shipper cách bạn khoảng ${_distanceText(shipper, destination)}';
      subtitle = updatedAt == null ? null : _agoText(updatedAt);
    } else if (shipper != null) {
      title = 'Shipper đang trên đường giao';
      subtitle = updatedAt == null ? null : _agoText(updatedAt);
    } else {
      title = 'Đang chờ shipper bật định vị';
      subtitle = 'Vị trí sẽ hiện khi shipper bắt đầu giao';
    }

    final content = Row(
      children: [
        const Icon(Icons.two_wheeler_rounded, color: _pink, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF222222),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: const Color(0xFF777777),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (plain) return content;
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(12),
      child: Padding(padding: const EdgeInsets.all(14), child: content),
    );
  }
}

class _RoundMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const _RoundMarker({required this.icon, required this.color, this.size = 36});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
    ),
    child: Icon(icon, color: Colors.white, size: size * 0.5),
  );
}
