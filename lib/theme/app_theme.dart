import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

/// Màu thương hiệu, giống nhau ở cả hai chế độ.
const Color brandPink = Color(0xFFFE3E6C);

/// Bảng màu theo chế độ sáng/tối. Dùng qua `context.colors.xxx` để màn hình
/// tự đổi màu khi người dùng chuyển giao diện.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color bg; // nền màn hình
  final Color page; // nền trang có các thẻ nổi lên trên
  final Color surface; // thẻ, hộp thoại, ô nhập
  final Color surfaceAlt; // nền xám nhạt (ô tìm kiếm, chip)
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;

  const AppColors({
    required this.bg,
    required this.page,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
  });

  static const light = AppColors(
    bg: Colors.white,
    page: Color(0xFFF8F8F8),
    surface: Colors.white,
    surfaceAlt: Color(0xFFF8F8F8),
    textPrimary: Color(0xFF222222),
    textSecondary: Color(0xFF777777),
    textMuted: Color(0xFFA8A8A9),
    border: Color(0xFFE6E6E6),
  );

  static const dark = AppColors(
    bg: Color(0xFF0F0F10),
    page: Color(0xFF0F0F10),
    surface: Color(0xFF1C1C1E),
    surfaceAlt: Color(0xFF2C2C2E),
    textPrimary: Color(0xFFF2F2F7),
    textSecondary: Color(0xFFAEAEB2),
    textMuted: Color(0xFF7C7C80),
    border: Color(0xFF38383A),
  );

  @override
  AppColors copyWith({
    Color? bg,
    Color? page,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
  }) => AppColors(
    bg: bg ?? this.bg,
    page: page ?? this.page,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textMuted: textMuted ?? this.textMuted,
    border: border ?? this.border,
  );

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      page: Color.lerp(page, other.page, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  /// Bảng màu của giao diện hiện tại. Thiếu (VD trong test dùng MaterialApp
  /// trần) thì lấy bảng màu mặc định theo độ sáng.
  AppColors get colors {
    final theme = Theme.of(this);
    return theme.extension<AppColors>() ??
        (theme.brightness == Brightness.dark
            ? AppColors.dark
            : AppColors.light);
  }
}

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final c = dark ? AppColors.dark : AppColors.light;
  final base = ThemeData(brightness: brightness);
  return ThemeData(
    brightness: brightness,
    scaffoldBackgroundColor: c.page,
    canvasColor: c.bg,
    cardColor: c.surface,
    dividerColor: c.border,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: brandPink,
          brightness: brightness,
        ).copyWith(
          primary: brandPink,
          surface: c.surface,
          onSurface: c.textPrimary,
        ),
    // Áp dụng Montserrat cho toàn bộ app, màu chữ theo chế độ
    textTheme: GoogleFonts.montserratTextTheme(base.textTheme)
        .apply(bodyColor: c.textPrimary, displayColor: c.textPrimary),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.textPrimary,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
    ),
    iconTheme: IconThemeData(color: c.textPrimary),
    // Ô nhập sáng viền hồng khi đang gõ, con trỏ và vùng chọn cùng màu thương hiệu
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: brandPink, width: 1.5),
      ),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: brandPink,
      selectionHandleColor: brandPink,
      selectionColor: brandPink.withValues(alpha: 0.25),
    ),
    // Chuyển trang kiểu trượt mượt của iOS trên cả hai hệ điều hành
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF3A3A3C) : const Color(0xFF2B2B2D),
      contentTextStyle: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    extensions: [c],
  );
}

/// Chế độ giao diện người dùng chọn, lưu lại để lần mở app sau giữ nguyên.
class ThemeController {
  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.system);

  static Future<void> load() async {
    try {
      mode.value = switch (await _storage.read(key: _key)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Không đọc được thì theo giao diện của hệ thống
    }
  }

  static Future<void> set(ThemeMode value) async {
    mode.value = value;
    try {
      await _storage.write(key: _key, value: value.name);
    } catch (_) {}
  }
}
