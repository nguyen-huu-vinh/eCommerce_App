import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/Shoppingbag.png',
          height: 280,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.local_shipping_outlined,
            size: 180,
            color: Color(0xFFF83758),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          'Get Your Order',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Amet minim mollit non deserunt ullamco est sit aliqua dolor do amet sint. Velit officia consequat duis enim velit mollit.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
