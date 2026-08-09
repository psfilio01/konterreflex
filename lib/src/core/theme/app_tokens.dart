import 'package:flutter/material.dart';

abstract final class AppColors {
  static const background = Color(0xFFF8F7F2);
  static const surface = Color(0xFFFFFEFA);
  static const foreground = Color(0xFF202421);
  static const muted = Color(0xFF69736E);
  static const sage = Color(0xFF56776D);
  static const mist = Color(0xFFDCE8E2);
  static const lavender = Color(0xFFE7E1EF);
  static const sand = Color(0xFFF1E4CE);
  static const success = Color(0xFF3E735B);
}

abstract final class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

abstract final class AppRadii {
  static const medium = 16.0;
  static const large = 24.0;
  static const pill = 999.0;
}
