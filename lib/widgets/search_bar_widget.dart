import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bouncing_button.dart'; // Import BouncingButton dùng chung

class SearchBarWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onMicTap;

  const SearchBarWidget({
    super.key,
    this.controller,
    this.onChanged,
    this.onMicTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Color(0xFFBBBBBB), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF1F1F1F),
              ),
              decoration: InputDecoration(
                hintText: 'Search any Product..',
                hintStyle: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFFBBBBBB),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          BouncingButton(
            onTap: onMicTap ?? () {},
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.mic_none_outlined,
                color: Color(0xFFBBBBBB),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
