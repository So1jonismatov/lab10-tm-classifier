import 'package:flutter/material.dart';

class AppSpacing {
  const AppSpacing._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const radius = 16.0;
  static const radiusSmall = 8.0;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF0F766E),
    brightness: Brightness.light,
  );
  const shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radius)),
  );
  final pressed = WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.pressed)) return scheme.onSurface.withValues(alpha: 0.14);
    if (states.contains(WidgetState.hovered)) return scheme.onSurface.withValues(alpha: 0.08);
    return null;
  });
  const buttonPadding = EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md);

  final base = ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Roboto');
  final text = base.textTheme.copyWith(
    headlineMedium: base.textTheme.headlineMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w700),
    titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
    titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 14),
    labelLarge: base.textTheme.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
  );

  return base.copyWith(
    textTheme: text,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(shape),
        padding: const WidgetStatePropertyAll(buttonPadding),
        overlayColor: pressed,
        textStyle: WidgetStatePropertyAll(text.labelLarge),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        shape: const WidgetStatePropertyAll(shape),
        padding: const WidgetStatePropertyAll(buttonPadding),
        overlayColor: pressed,
        side: WidgetStatePropertyAll(BorderSide(color: scheme.outline)),
        textStyle: WidgetStatePropertyAll(text.labelLarge),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(overlayColor: pressed, textStyle: WidgetStatePropertyAll(text.labelLarge)),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: shape.copyWith(side: BorderSide(color: scheme.outlineVariant)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: scheme.secondaryContainer,
      labelStyle: text.labelLarge?.copyWith(color: scheme.onSecondaryContainer),
      side: BorderSide.none,
      shape: const StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(AppSpacing.radius)),
        borderSide: BorderSide(color: scheme.outline),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainer,
      indicatorColor: scheme.secondaryContainer,
      labelTextStyle: WidgetStatePropertyAll(text.labelMedium),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusSmall)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.surfaceContainerHighest,
    ),
    dialogTheme: DialogThemeData(shape: shape),
  );
}
