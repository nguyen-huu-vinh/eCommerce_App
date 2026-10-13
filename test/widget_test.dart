import 'package:ecommerce_a/utils/currency.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatVnd groups thousands with dots', () {
    expect(formatVnd(0), '0 ₫');
    expect(formatVnd(999), '999 ₫');
    expect(formatVnd(1000), '1.000 ₫');
    expect(formatVnd(1250000), '1.250.000 ₫');
    expect(formatVnd(149999.6), '150.000 ₫');
  });

  testWidgets('every Montserrat weight used by the app is bundled', (
    tester,
  ) async {
    // google_fonts tìm file tên "Montserrat-<Biến thể>.ttf" trong assets;
    // thiếu file thì nó âm thầm tải qua mạng, nên phải kiểm tra trực tiếp
    final assets = (await AssetManifest.loadFromAssetBundle(rootBundle))
        .listAssets();
    for (final variant in [
      'Light',
      'Regular',
      'Medium',
      'SemiBold',
      'Bold',
      'ExtraBold',
    ]) {
      final path = 'assets/google_fonts/Montserrat-$variant.ttf';
      expect(assets, contains(path));
      final data = await tester.runAsync(() => rootBundle.load(path));
      expect(data!.lengthInBytes, greaterThan(10000), reason: path);
    }
  });
}
