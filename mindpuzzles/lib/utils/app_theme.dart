import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF42A5F5);
  static const primaryDark = Color(0xFF0D47A1);
  static const accent = Color(0xFF00BCD4);
  static const background = Color(0xFFF8FAFF);
  static const surface = Colors.white;
  static const success = Color(0xFF43A047);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFE53935);
  static const gold = Color(0xFFFFB300);

  static const sudokuColor = Color(0xFF1565C0);
  static const patchesColor = Color(0xFF6A1B9A);
  static const zipColor = Color(0xFF00695C);

  static BoxDecoration cardDecoration({Color? color, double radius = 16}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration gradientDecoration(List<Color> colors, {double radius = 16}) =>
      BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [BoxShadow(color: colors.first.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      );
}
