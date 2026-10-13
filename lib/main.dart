import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'splash_screen.dart'; // Import file màn hình splash vừa tạo

import 'package:google_fonts/google_fonts.dart';

void main() {
  // Giấy phép SIL OFL của font Montserrat đóng gói trong app
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.montserratTextTheme(), // Áp dụng Montserrat cho toàn bộ App
      ),
      home: SplashScreen(),
    );
  }
}
