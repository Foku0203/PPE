import 'package:flutter/material.dart';

import '../../shared/models/requisition_model.dart';

class AppColors {
  static const ink = Color(0xFF0E1B3D); // deep navy: hero cards, primary buttons, active nav pill
  static const inkLight = Color(0xFF1F3A73); // hero gradient end
  static const sky = Color(0xFFDCE8FB); // soft blue: overview cards, icon wells
  static const skyLight = Color(0xFFEEF4FD);
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

  /// The palette is tuned for light surfaces; lift it in dark mode so navy/grey/red text stays legible.
  static Color readable(BuildContext context, Color color) =>
      Theme.of(context).brightness == Brightness.dark ? Color.lerp(color, Colors.white, 0.45)! : color;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  /// Soft navy-tinted shadow used instead of card borders.
  static List<BoxShadow> softShadow(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const []
      : const [BoxShadow(color: Color(0x120E1B3D), blurRadius: 24, offset: Offset(0, 8))];

  static ThemeData _build(Brightness brightness) {
    final light = brightness == Brightness.light;
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.brand, secondary: AppColors.safetyAmber, brightness: brightness).copyWith(
      primary: light ? AppColors.ink : const Color(0xFFB4C9F5),
      onPrimary: light ? Colors.white : AppColors.ink,
      primaryContainer: light ? AppColors.sky : const Color(0xFF243556),
      onPrimaryContainer: light ? AppColors.ink : AppColors.sky,
      secondaryContainer: light ? AppColors.sky : const Color(0xFF243556),
      onSecondaryContainer: light ? AppColors.ink : AppColors.sky,
      surface: light ? const Color(0xFFF3F5F9) : const Color(0xFF0B1120),
      onSurface: light ? const Color(0xFF111827) : const Color(0xFFE6EAF2),
      onSurfaceVariant: light ? const Color(0xFF667085) : const Color(0xFF9AA4B8),
      surfaceContainerLowest: light ? Colors.white : const Color(0xFF0E1526),
      surfaceContainerLow: light ? const Color(0xFFF8FAFD) : const Color(0xFF121A2B),
      surfaceContainer: light ? const Color(0xFFEEF2F8) : const Color(0xFF162034),
      surfaceContainerHigh: light ? const Color(0xFFE8EDF5) : const Color(0xFF1B263C),
      surfaceContainerHighest: light ? const Color(0xFFE2E8F1) : const Color(0xFF223049),
      outline: light ? const Color(0xFF98A2B3) : const Color(0xFF5B6781),
      outlineVariant: light ? const Color(0xFFE4E9F1) : const Color(0xFF26324A),
    );
    final cardColor = light ? Colors.white : const Color(0xFF151E31);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    final text = base.textTheme;
    final rounded16 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
    return base.copyWith(
      // Noto Sans Thai / Myanmar fallback comes from the platform; keep default font family.
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        headlineSmall: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        bodySmall: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface, fontSize: 21),
      ),
      cardTheme: CardThemeData(
        elevation: light ? 3 : 0,
        shadowColor: const Color(0x2A0E1B3D),
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: light ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
        ),
      ),
      listTileTheme: ListTileThemeData(iconColor: scheme.onSurfaceVariant, shape: rounded16),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        prefixIconColor: scheme.onSurfaceVariant,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: scheme.primary, width: 1.6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: rounded16,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(64, 52), shape: rounded16, side: BorderSide(color: scheme.outlineVariant)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: rounded16,
        elevation: 2,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
        backgroundColor: cardColor,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(backgroundColor: cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cardColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: cardColor,
        indicatorColor: scheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, shape: rounded16),
    );
  }
}
