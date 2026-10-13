import 'dart:convert';
import 'dart:io';

import 'package:ecommerce_a/widgets/order_tracking_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('tracking map shows distance, polls, stops after delivery', (
    tester,
  ) async {
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

    var trackingCalls = 0;
    var status = 'shipping';
    final changes = <String>[];
    final client = MockClient((req) async {
      if (req.url.path.endsWith('/tracking')) {
        trackingCalls++;
        expect(req.headers['Authorization'], 'Bearer tok');
        return http.Response(
          jsonEncode({
            'order_id': 5,
            'status': status,
            'shop': {'lat': 10.7724, 'lng': 106.6981, 'name': 'Stylish'},
            'destination': {'lat': 10.7769, 'lng': 106.7009, 'address': 'Q1'},
            'shipper': status == 'shipping'
                ? {
                    'lat': 10.7869,
                    'lng': 106.7009,
                    'updated_at': DateTime.now()
                        .toUtc()
                        .toIso8601String()
                        .replaceAll('Z', ''),
                  }
                : null,
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      return http.Response('', 404); // tile ảnh bản đồ
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                OrderTrackingMap(orderId: 5, onStatusChanged: changes.add),
              ],
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(); // camera đã căn được vẽ ở khung hình kế tiếp

      // 10.7869 -> 10.7769 cùng kinh độ ~ 1,1 km
      expect(
        find.textContaining('Shipper cách bạn khoảng 1,1 km'),
        findsOneWidget,
      );
      expect(find.text('vừa cập nhật'), findsOneWidget);
      // Dòng chữ + điểm shipper trên bản đồ
      expect(find.byIcon(Icons.two_wheeler_rounded), findsNWidgets(2));
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsOneWidget);
      expect(trackingCalls, 1);

      status = 'completed';
      await tester.pump(const Duration(seconds: 10));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      expect(trackingCalls, 2);
      expect(changes, ['completed']);

      await tester.pump(const Duration(seconds: 30));
      expect(trackingCalls, 2, reason: 'polling stops once not shipping');
      await tester.pumpWidget(const SizedBox());
    }, () => client);
  });
}
