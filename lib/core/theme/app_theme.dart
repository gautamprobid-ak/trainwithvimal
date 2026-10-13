import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Radii from the design system.
abstract final class AppRadius {
  static const badge = 6.0;
  static const control = 8.0; // web buttons, inputs, chips, rows
  static const menu = 12.0;
  static const button = 12.0; // phone buttons (ca-btn)
  static const card = 14.0; // phone cards (ca-card)
  static const modal = 16.0;
  static const sheet = 20.0;
}

abstract final class AppSpace {
  static const page = 16.0;
  static const gap = 12.0;
}

/// Type scale — Plus Jakarta Sans.
abstract final class AppText {
  static TextStyle get _base => GoogleFonts.plusJakartaSans(color: AppColors.text);

  static TextStyle get pageTitle => _base.copyWith(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -.3, height: 1.2);
  static TextStyle get sectionTitle => _base.copyWith(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -.2);
  static TextStyle get heroTitle => _base.copyWith(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.2);
  static TextStyle get cardTitle => _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700);
  static TextStyle get body => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.45);
  static TextStyle get bodyBold => _base.copyWith(fontSize: 14, fontWeight: FontWeight.w700);
  static TextStyle get secondary => _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.muted);
  static TextStyle get caption => _base.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.muted);
  static TextStyle get overline =>
      _base.copyWith(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: .6, color: AppColors.muted);
  static TextStyle get bigNumber => _base.copyWith(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.5);
}

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        primary: AppColors.accent,
        surface: AppColors.card,
        error: AppColors.bad,
      ),
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: InkSparkle.splashFactory,
    );
    final text = base.textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    );
    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button));
    return base.copyWith(
      textTheme: text,
      dividerColor: AppColors.line,
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1, space: 1),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: AppColors.text,
        centerTitle: false,
        titleTextStyle: AppText.cardTitle.copyWith(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 44),
          shape: controlShape,
          textStyle: AppText.bodyBold.copyWith(fontSize: 14.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.text,
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: AppColors.line),
          shape: controlShape,
          textStyle: AppText.bodyBold.copyWith(fontSize: 14.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accentText,
          textStyle: AppText.bodyBold.copyWith(fontSize: 13.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        hintStyle: AppText.body.copyWith(color: AppColors.muted),
        labelStyle: AppText.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: const BorderSide(color: AppColors.bad),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: AppColors.line2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.modal)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        contentTextStyle: AppText.body.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.line2),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: AppColors.line2, width: 1.5),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.sub,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => AppText.caption.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: s.contains(WidgetState.selected) ? AppColors.accent : AppColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(size: 23, color: s.contains(WidgetState.selected) ? AppColors.accent : AppColors.muted),
        ),
      ),
    );
  }
}
