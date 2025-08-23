import 'package:flutter/material.dart';

class AppColors {
  // Primary colors from user specification
  static const Color darkBrown = Color(0xFF1D140C);
  static const Color mediumBrown = Color(0xFFAA8474);
  static const Color lightBrown = Color(0xFFDFD3CE);
  static const Color white = Color(0xFFFFFFFF);
  
  // Additional colors for UI elements
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBrown, mediumBrown],
  );
  
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBrown, white],
  );
}

