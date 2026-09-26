import 'package:flutter/material.dart';

import '../../shared/models/requisition_model.dart';

class AppColors {
  static const brand = Color(0xFF17418F); // PPE SMART navy (logo)
  static const safetyAmber = Color(0xFFF5A300);
  static const brandGreen = Color(0xFF1FA67A); // PPE SMART green (logo)
  static const success = Color(0xFF1E8E3E);
  static const warning = Color(0xFFE37400);
  static const danger = Color(0xFFC5221F);
  static const info = Color(0xFF1A73E8);
  static const neutral = Color(0xFF5F6368);
  static const special = Color(0xFF8E24AA);

  static Color status(RequisitionStatus status) => switch (status) {
        RequisitionStatus.pending => info,
        RequisitionStatus.special => special,
        RequisitionStatus.approved => brand,
        RequisitionStatus.onHold => warning,
        RequisitionStatus.ready => success,
        RequisitionStatus.completed => neutral,
        RequisitionStatus.rejected => danger,
        RequisitionStatus.cancelled => neutral,
      };
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.brand, secondary: AppColors.safetyAmber, brightness: brightness);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    return base.copyWith(
      // Noto Sans Thai / Myanmar fallback comes from the platform; keep default font family.
      scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFF5F7FA) : scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: brightness == Brightness.light ? Colors.white : scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: brightness == Brightness.light ? Colors.white : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6))),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light ? Colors.white : scheme.surfaceContainerHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      ),
      chipTheme: base.chipTheme.copyWith(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: brightness == Brightness.light ? Colors.white : scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
