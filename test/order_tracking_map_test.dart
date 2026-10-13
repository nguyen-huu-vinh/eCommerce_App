import 'dart:convert';
import 'dart:io';

import 'package:ecommerce_a/widgets/order_tracking_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Đoạn đầu và cuối của một đường OSRM thật (shipper ở 10.7869 -> nơi nhận)
const _route = {
  'points': [
    [10.787094, 106.701085],
    [10.787215, 106.700954],
    [10.787696, 106.70043],
    [10.7775, 106.7004],
    [10.7769, 106.7009],
  ],
  'distance_m': 2099,
  'duration_s': 180,
};

/// Dựng bản đồ với một server giả; [respond] trả về JSON theo trạng thái đơn
Future<void> _pumpMap(
  WidgetTester tester, {
  required Map<String, dynamic> Function() respond,
  required void Function() onTrackingCall,
  required List<String> statusChanges,
  required Future<void> Function() body,
}) async {
  FlutterSecureStorage.setMockInitialValues({'access_token': 'tok'});
  // Môi trường test không có thư mục cache thật cho ảnh bản đồ
  final cacheDir = Directory.systemTemp.createTempSync('map_cache');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => cacheDir.path,
      );
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final client = MockClient((req) async {
    if (req.url.path.endsWith('/tracking')) {
      onTrackingCall();
      expect(req.headers['Authorization'], 'Bearer tok');
      return http.Response(
        jsonEncode(respond()),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }
    return http.Response('', 404);
  });

  await http.runWithClient(() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              OrderTrackingMap(orderId: 5, onStatusChanged: statusChanges.add),
            ],
          ),
        ),
      ),
    );
    await _settle(tester);
    await body();
    await tester.pumpWidget(const SizedBox());
  }, () => client);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(); // camera đã căn được vẽ ở khung hình kế tiếp
}

Map<String, dynamic> _tracking(String status, {bool withRoute = true}) => {
  'order_id': 5,
  'status': status,
  'shop': {'lat': 10.7724, 'lng': 106.6981, 'name': 'Stylish'},
  'destination': {'lat': 10.7769, 'lng': 106.7009, 'address': 'Q1'},
  'shipper': status == 'shipping'
      ? {
          'lat': 10.7869,
          'lng': 106.7009,
          'updated_at': DateTime.now().toUtc().toIso8601String().replaceAll(
            'Z',
            '',
          ),
        }
      : null,
  'route': status == 'shipping' && withRoute ? _route : null,
};

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('draws the road route with distance and ETA, then stops polling '
      'after delivery', (tester) async {
    var calls = 0;
    var status = 'shipping';
    final changes = <String>[];
    await _pumpMap(
      tester,
      respond: () => _tracking(status),
      onTrackingCall: () => calls++,
      statusChanges: changes,
      body: () async {
        // Quãng đường và thời gian theo đường phố, không phải đường chim bay
        expect(
          find.text('Shipper còn 2,1 km · khoảng 3 phút nữa'),
          findsOneWidget,
        );
        expect(find.text('vừa cập nhật'), findsOneWidget);

        final layer = tester.widget<PolylineLayer>(find.byType(PolylineLayer));
        final line = layer.polylines.single;
        expect(line.points, hasLength(5), reason: 'follows every route point');
        expect(line.pattern, const StrokePattern.solid());

        // Điểm shipper, ghim nơi nhận và cửa hàng đều có trên bản đồ
        expect(find.byIcon(Icons.two_wheeler_rounded), findsNWidgets(2));
        expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
        expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
        expect(calls, 1);

        // Nền bản đồ là Esri (CARTO nay trả ảnh "API KEY REQUIRED")
        final tiles = tester.widget<TileLayer>(find.byType(TileLayer));
        expect(tiles.urlTemplate, contains('server.arcgisonline.com'));
        expect(tiles.urlTemplate, endsWith('/tile/{z}/{y}/{x}'));

        status = 'completed';
        await tester.pump(const Duration(seconds: 10));
        await _settle(tester);
        expect(calls, 2);
        expect(changes, ['completed']);

        await tester.pump(const Duration(seconds: 30));
        expect(calls, 2, reason: 'polling stops once not shipping');
      },
    );
  });

  testWidgets('falls back to a dashed straight line without a route', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      respond: () => _tracking('shipping', withRoute: false),
      onTrackingCall: () {},
      statusChanges: [],
      body: () async {
        // 10.7869 -> 10.7769 cùng kinh độ ~ 1,1 km đường chim bay
        expect(find.text('Shipper cách bạn khoảng 1,1 km'), findsOneWidget);
        final line = tester
            .widget<PolylineLayer>(find.byType(PolylineLayer))
            .polylines
            .single;
        expect(line.points, hasLength(2));
        expect(line.pattern, isNot(const StrokePattern.solid()));
      },
    );
  });
}
