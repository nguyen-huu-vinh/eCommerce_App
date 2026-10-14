import 'dart:convert';
import 'dart:io';

import 'package:ecommerce_a/models/product.dart';
import 'package:ecommerce_a/product_detail_screen.dart';
import 'package:ecommerce_a/services/cart_controller.dart';
import 'package:ecommerce_a/services/product_service.dart';
import 'package:ecommerce_a/widgets/cart_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _shoe = Product(
  id: 1,
  name: 'Giày',
  price: 100000,
  imageUrl: 'x',
  sizes: ['38', '39'],
  stock: 2,
);

Map<String, dynamic> _json(Product p) => p.toJson();

Future<CartController> _openDetail(WidgetTester tester, Product product) async {
  FlutterSecureStorage.setMockInitialValues({});
  // Ảnh sản phẩm được lưu xuống thư mục cache; môi trường test không có sẵn
  final cacheDir = Directory.systemTemp.createTempSync('img_cache');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => cacheDir.path,
      );
  tester.view.physicalSize = const Size(400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ProductService.clearCache();
  final cart = CartController();
  final client = MockClient(
    (req) async => http.Response(
      jsonEncode(
        req.url.path == '/products' ? [_json(product)] : _json(product),
      ),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  );
  await http.runWithClient(() async {
    // Bỏ trang cũ (nếu có) để trang chi tiết được dựng mới hoàn toàn
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: CartScope(
          controller: cart,
          onOpenCart: () {},
          child: ProductDetailScreen(
            productId: product.id,
            initialProduct: product,
          ),
        ),
      ),
    );
    // Sản phẩm truyền sẵn vào nên giao diện hiện ngay; pump để chạy hết
    // các tác vụ (request giả) trong thời gian giả lập của test
    await tester.pump();
    await tester.pump();
  }, () => client);
  return cart;
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('cart never exceeds stock, counting every size together', () {
    FlutterSecureStorage.setMockInitialValues({});
    final cart = CartController();
    expect(cart.add(_shoe, '38'), isTrue);
    expect(cart.add(_shoe, '39'), isTrue);
    expect(cart.add(_shoe, '38'), isFalse, reason: 'only 2 in stock');
    expect(cart.itemCount, 2);

    final line = cart.items.first;
    cart.setQuantity(line, 5);
    expect(cart.itemCount, 2, reason: 'cannot raise past stock');
    cart.setQuantity(line, 0);
    expect(cart.itemCount, 1, reason: 'decreasing still works');
    expect(cart.canAddMore(_shoe), isTrue);

    const unlimited = Product(id: 2, name: 'Áo', price: 1, imageUrl: 'x');
    for (var i = 0; i < 50; i++) {
      expect(cart.add(unlimited, 'M'), isTrue);
    }
  });

  testWidgets('out-of-stock product shows a notice and cannot be added', (
    tester,
  ) async {
    final cart = await _openDetail(
      tester,
      const Product(
        id: 3,
        name: 'Hết',
        price: 1,
        imageUrl: 'x',
        sizes: ['M'],
        stock: 0,
      ),
    );
    expect(find.text('Hết hàng'), findsOneWidget);
    await tester.tap(find.text('Go to cart'));
    await tester.pump();
    expect(find.text('Sản phẩm này đã hết hàng'), findsOneWidget);
    expect(cart.itemCount, 0);
  });

  testWidgets('low stock warns; products without sizes hide the picker', (
    tester,
  ) async {
    await _openDetail(tester, _shoe);
    expect(find.text('Chỉ còn 2 sản phẩm'), findsOneWidget);
    expect(find.text('Size: 38'), findsOneWidget);
    expect(find.text('39'), findsOneWidget);

    await _openDetail(
      tester,
      const Product(id: 4, name: 'Son', price: 1, imageUrl: 'x', sizes: []),
    );
    expect(find.textContaining('Size:'), findsNothing);
    expect(
      find.textContaining('Chỉ còn'),
      findsNothing,
      reason: 'unlimited stock',
    );
  });
}
