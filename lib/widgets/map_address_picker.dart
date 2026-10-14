import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../services/place_service.dart';

const _pink = Color(0xFFFE3E6C);
const _tileUrl =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
// Hà Nội: điểm bắt đầu khi chưa biết người dùng ở đâu
const _fallbackCenter = LatLng(21.0285, 105.8542);

/// Màn chọn vị trí: kéo bản đồ cho ghim nằm đúng chỗ, địa chỉ tự cập nhật.
/// Trả về [Place] khi người dùng xác nhận.
class MapAddressPicker extends StatefulWidget {
  final LatLng? initial;

  const MapAddressPicker({super.key, this.initial});

  @override
  State<MapAddressPicker> createState() => _MapAddressPickerState();
}

class _MapAddressPickerState extends State<MapAddressPicker> {
  late LatLng _center = widget.initial ?? _fallbackCenter;
  String? _address;
  bool _loading = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _lookup();
  }

  Future<void> _lookup() async {
    final id = ++_request;
    setState(() => _loading = true);
    String? address;
    try {
      address = await PlaceService.reverse(_center);
    } catch (_) {}
    // Người dùng đã kéo tiếp: bỏ kết quả cũ
    if (!mounted || id != _request) return;
    setState(() {
      _address = address;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chọn vị trí giao hàng',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initial == null ? 12 : 17,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
                if (hasGesture) {
                  // Tìm lại sau khi ngừng kéo
                  final id = ++_request;
                  setState(() => _loading = true);
                  Future.delayed(const Duration(milliseconds: 700), () {
                    if (mounted && id == _request) _lookup();
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: _tileUrl,
                maxNativeZoom: 19,
                userAgentPackageName: 'com.example.ecommerce_a',
              ),
            ],
          ),
          // Ghim cố định giữa màn hình; đầu nhọn của ghim chỉ đúng tâm bản đồ
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_on, color: _pink, size: 48),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loading
                          ? 'Đang tìm địa chỉ...'
                          : (_address ?? 'Không xác định được địa chỉ ở đây'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _pink,
                        ),
                        onPressed: _loading || _address == null
                            ? null
                            : () => Navigator.pop(
                                context,
                                Place(_address!, _center),
                              ),
                        child: const Text('Xác nhận vị trí này'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
