import 'package:flutter/material.dart';

import 'splash_screen.dart'; // Import file màn hình splash vừa tạo

import 'package:google_fonts/google_fonts.dart';

void main() {
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
