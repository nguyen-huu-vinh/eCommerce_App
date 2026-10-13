import 'dart:convert';
import 'dart:typed_data';

import 'package:ecommerce_a/profile_screen.dart';
import 'package:ecommerce_a/services/auth_service.dart';
import 'package:ecommerce_a/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({'access_token': 'tok'});
    AuthService.avatarUrl.value = null;
  });

  test(
    'uploadAvatar sends a multipart image and updates the shared url',
    () async {
      late http.BaseRequest sent;
      late String body;
      final client = MockClient((req) async {
        sent = req;
        body = latin1.decode(req.bodyBytes);
        return _json({'avatar_url': '/avatars/abc'});
      });
      await http.runWithClient(() async {
        await AuthService.uploadAvatar(
          Uint8List.fromList([0xff, 0xd8, 0xff, 1, 2, 3]),
          'me.jpg',
        );
      }, () => client);

      expect(sent.method, 'POST');
      expect(sent.url.path, '/me/avatar');
      expect(sent.headers['Authorization'], 'Bearer tok');
      expect(sent.headers['content-type'], startsWith('multipart/form-data'));
      expect(body, contains('name="file"; filename="me.jpg"'));
      expect(AuthService.avatarUrl.value, '$baseUrl/avatars/abc');
    },
  );

  test(
    'upload errors surface the server message; delete and logout clear',
    () async {
      AuthService.avatarUrl.value = '$baseUrl/avatars/old';
      final client = MockClient((req) async {
        if (req.method == 'POST') {
          return _json({'detail': 'Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP'}, 400);
        }
        return _json({'avatar_url': null});
      });
      await http.runWithClient(() async {
        await expectLater(
          AuthService.uploadAvatar(Uint8List.fromList([1, 2, 3]), 'x.gif'),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Chỉ hỗ trợ ảnh JPG, PNG hoặc WEBP',
            ),
          ),
        );
        expect(AuthService.avatarUrl.value, '$baseUrl/avatars/old');

        await AuthService.deleteAvatar();
        expect(AuthService.avatarUrl.value, isNull);
      }, () => client);

      AuthService.avatarUrl.value = '$baseUrl/avatars/x';
      await AuthService.logout();
      expect(AuthService.avatarUrl.value, isNull);
    },
  );

  testWidgets('UserAvatar follows the shared avatar url', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: UserAvatar(size: 40))),
    );
    expect(find.byIcon(Icons.person), findsOneWidget);

    AuthService.avatarUrl.value = '$baseUrl/avatars/abc';
    await tester.pump();
    expect(find.byIcon(Icons.person), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('profile avatar opens camera, gallery and delete options', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var deleted = false;
    final client = MockClient((req) async {
      if (req.url.path == '/me') {
        return _json({
          'id': 3,
          'email': 'a@b.com',
          'full_name': 'Vinh',
          'is_admin': false,
          'avatar_url': deleted ? null : '/avatars/abc',
        });
      }
      if (req.method == 'DELETE' && req.url.path == '/me/avatar') {
        deleted = true;
        return _json({'avatar_url': null});
      }
      return http.Response('', 404);
    });

    await http.runWithClient(() async {
      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(AuthService.avatarUrl.value, '$baseUrl/avatars/abc');

      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Chụp ảnh'), findsOneWidget);
      expect(find.text('Chọn từ thư viện'), findsOneWidget);
      expect(find.text('Xóa ảnh đại diện'), findsOneWidget);

      await tester.tap(find.text('Xóa ảnh đại diện'));
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
      expect(AuthService.avatarUrl.value, isNull);
      expect(find.text('Đã xóa ảnh đại diện'), findsOneWidget);

      // Không còn ảnh thì không hiện lựa chọn xóa
      await tester.tap(find.byIcon(Icons.photo_camera_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Xóa ảnh đại diện'), findsNothing);
    }, () => client);
  });
}
