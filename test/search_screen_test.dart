import 'dart:convert';

import 'package:ecommerce_a/search_screen.dart';
import 'package:ecommerce_a/services/product_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final _products = [
  {
    'id': 1,
    'name': 'Áo thun trắng',
    'price': 200000,
    'discount_price': 150000,
    'image_url': 'x',
    'category': 'Mens',
  },
  {
    'id': 2,
    'name': 'Váy hoa',
    'price': 500000,
    'image_url': 'x',
    'category': 'Womens',
  },
  {
    'id': 3,
    'name': 'Áo khoác',
    'price': 300000,
    'discount_price': 90000,
    'image_url': 'x',
    'category': 'Mens',
  },
  {
    'id': 4,
    'name': 'Son môi',
    'price': 120000,
    'image_url': 'x',
    'category': 'Beauty',
  },
];

/// Tên sản phẩm theo đúng thứ tự đang hiện trên lưới
List<String> _shownNames(WidgetTester tester) {
  final names = _products.map((p) => p['name'] as String).toSet();
  final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data);
  return [
    for (final t in texts)
      if (names.contains(t)) t!,
  ];
}

Future<void> _pump(WidgetTester tester, {SearchRequests? requests}) async {
  tester.view.physicalSize = const Size(400, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  ProductService.clearCache();
  final client = MockClient(
    (req) async => http.Response(
      jsonEncode(_products),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    ),
  );
  await http.runWithClient(() async {
    await tester.pumpWidget(
      MaterialApp(home: SearchScreen(requests: requests)),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }, () => client);
}

Future<void> _pickSort(WidgetTester tester, String label) async {
  await tester.tap(find.text('Sắp xếp'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('sorts by sale price, discount and name', (tester) async {
    await _pump(tester);
    expect(find.text('Tất cả sản phẩm (4)'), findsOneWidget);

    await _pickSort(tester, 'Giá thấp đến cao');
    // Giá bán thật: Áo khoác 90k, Son 120k, Áo thun 150k, Váy 500k
    expect(_shownNames(tester), [
      'Áo khoác',
      'Son môi',
      'Áo thun trắng',
      'Váy hoa',
    ]);
    expect(
      find.text('Giá thấp đến cao'),
      findsOneWidget,
      reason: 'toolbar shows choice',
    );

    await tester.tap(find.text('Giá thấp đến cao'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giảm giá nhiều nhất'));
    await tester.pumpAndSettle();
    expect(_shownNames(tester).take(2), ['Áo khoác', 'Áo thun trắng']);

    await tester.tap(find.text('Giảm giá nhiều nhất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tên A → Z'));
    await tester.pumpAndSettle();
    // So sánh không dấu: "ao khoac" < "ao thun" < "son" < "vay"
    expect(_shownNames(tester), [
      'Áo khoác',
      'Áo thun trắng',
      'Son môi',
      'Váy hoa',
    ]);
  });

  testWidgets('filters by category and sale, combined with search', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.text('Lọc'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Mens'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(find.text('Lọc (1)'), findsOneWidget);
    expect(_shownNames(tester).toSet(), {'Áo thun trắng', 'Áo khoác'});
    expect(find.text('2 kết quả'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ao thun');
    await tester.pump();
    expect(_shownNames(tester), ['Áo thun trắng']);

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Lọc (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa lọc'));
    await tester.tap(find.text('Chỉ sản phẩm đang giảm giá'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(_shownNames(tester).toSet(), {'Áo thun trắng', 'Áo khoác'});

    await tester.tap(find.text('Lọc (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilterChip, 'Beauty'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Áp dụng'));
    await tester.pumpAndSettle();
    expect(find.text('Không có sản phẩm nào khớp bộ lọc'), findsOneWidget);
  });

  testWidgets('home requests open the sort and filter sheets', (tester) async {
    final requests = SearchRequests();
    await _pump(tester, requests: requests);

    requests.send(SearchAction.sort);
    await tester.pumpAndSettle();
    expect(find.text('Sắp xếp theo'), findsOneWidget);
    await tester.tapAt(const Offset(200, 20)); // đóng bảng
    await tester.pumpAndSettle();

    requests.send(SearchAction.filter);
    await tester.pumpAndSettle();
    expect(find.text('Lọc sản phẩm'), findsOneWidget);
    await tester.tapAt(const Offset(200, 20));
    await tester.pumpAndSettle();

    requests.send(SearchAction.focus);
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.focusNode!.hasFocus, isTrue);
  });
}
