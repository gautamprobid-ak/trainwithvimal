import 'package:flutter/material.dart';

/// Colour tokens from the "Train With Vimal" design system (twv.css).
abstract final class AppColors {
  // Surfaces
  static const bg = Color(0xFFF5F5F3); // phone app background
  static const bgWeb = Color(0xFFF5F5F5);
  static const card = Color(0xFFFFFFFF);
  static const sub = Color(0xFFF1F1EE); // sub surface / tab track
  static const hover = Color(0xFFEEF3FE); // row hover / pressed
  static const line = Color(0xFFE6E6E1);
  static const line2 = Color(0xFFD4D4CE);

  // Text
  static const text = Color(0xFF171717);
  static const text2 = Color(0xFF3F3F46);
  static const muted = Color(0xFF6B6B70);

  // Accent
  static const accent = Color(0xFF2563EB);
  static const accentHover = Color(0xFF1D4ED8);
  static const accentText = Color(0xFF1D4ED8);
  static const accentSoft = Color(0xFFEAF0FE);

  // Status
  static const okBg = Color(0xFFE8F6EE);
  static const okText = Color(0xFF11663D);
  static const ok = Color(0xFF16A34A);
  static const warnBg = Color(0xFFFFF1E6);
  static const warnText = Color(0xFF9A3A10);
  static const warn = Color(0xFFEA580C);
  static const badBg = Color(0xFFFDECEC);
  static const badText = Color(0xFFA4231B);
  static const bad = Color(0xFFE5484D);
  static const infoBg = Color(0xFFEAF0FE);
  static const infoText = Color(0xFF1D4ED8);

  // Avatar
  static const avatarBg = Color(0xFFE0E7FF);
  static const avatarText = Color(0xFF3730A3);

  // Hero gradient (home option with blue hero)
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4FB8EE), Color(0xFF2F8FE6), Color(0xFF2563EB)],
    stops: [0, .55, 1],
  );

  // Soft card heros
  static const greenHero = LinearGradient(colors: [Color(0xFFEEF6EF), Color(0xFFF8FBF8)]);
  static const blueHero = LinearGradient(colors: [Color(0xFFEAF1FE), Color(0xFFF7FAFF)]);
  static const grayHero = LinearGradient(colors: [Color(0xFFF1F1EE), Color(0xFFFAFAF8)]);

  // Macros
  static const protein = Color(0xFF2563EB);
  static const carbs = Color(0xFFF59E0B);
  static const fat = Color(0xFFEC4899);
}

/// Tinted icon chips used in list rows (mb-ric blue / green / amber ...).
enum Tint {
  blue(Color(0xFFEAF2FE), Color(0xFF2563EB)),
  green(Color(0xFFE7F6EC), Color(0xFF15803D)),
  amber(Color(0xFFFEF3E2), Color(0xFFB45309)),
  pink(Color(0xFFFDECF3), Color(0xFFBE185D)),
  purple(Color(0xFFF1ECFD), Color(0xFF6D28D9)),
  teal(Color(0xFFE4F5F4), Color(0xFF0F766E)),
  orange(Color(0xFFFFF1EA), Color(0xFFFF7A45)),
  red(Color(0xFFFDECEC), Color(0xFFA4231B)),
  gray(Color(0xFFF1F1EE), Color(0xFF3F3F46));

  const Tint(this.bg, this.fg);
  final Color bg;
  final Color fg;
}

/// Avatar palette (av.c1 … c6).
enum AvatarColor {
  c1(Color(0xFFE0EAFF), Color(0xFF1E40AF)),
  c2(Color(0xFFE8F6EE), Color(0xFF11663D)),
  c3(Color(0xFFFFF1E6), Color(0xFF9A3A10)),
  c4(Color(0xFFF1EAFE), Color(0xFF5B21B6)),
  c5(Color(0xFFFDECF3), Color(0xFF9D174D)),
  c6(Color(0xFFE6F6F8), Color(0xFF0E6874)),
  indigo(Color(0xFFE0E7FF), Color(0xFF3730A3)),
  brand(Color(0xFFDCE6FB), Color(0xFF1D4ED8));

  const AvatarColor(this.bg, this.fg);
  final Color bg;
  final Color fg;

  /// Stable colour for a name, so the same person always gets the same avatar.
  static AvatarColor of(String key) => values[key.codeUnits.fold<int>(0, (a, b) => a + b) % 6];
}

/// Calendar / session kinds (k-ss strength session, k-qc quick call, k-rv review, k-bs body scan).
enum KindColor {
  session(Color(0xFFEDF7D6), Color(0xFF3F6212), Color(0xFF84CC16)),
  call(Color(0xFFE2EDFD), Color(0xFF1E40AF), Color(0xFF60A5FA)),
  review(Color(0xFFEEE8FD), Color(0xFF5B21B6), Color(0xFFA78BFA)),
  scan(Color(0xFFFDEEDC), Color(0xFF9A3412), Color(0xFFFB923C));

  const KindColor(this.bg, this.text, this.line);
  final Color bg;
  final Color text;
  final Color line;
}
