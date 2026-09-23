import 'package:flutter/material.dart';

/// Mirrors the CSS custom properties from the original Streamlit app's
/// style_light.css / dark.css, so the Flutter app keeps the same violet
/// identity in both modes.
class AppColors extends ThemeExtension<AppColors> {
  final Color indigo50;
  final Color indigo100;
  final Color indigo200;
  final Color indigo400;
  final Color indigo600;
  final Color indigo800;
  final Color surface;
  final Color white; // "card surface" equivalent from the CSS --white var
  final Color border;
  final Color textMain;
  final Color textMuted;
  final Color textHint;
  final Color cardBg;
  final Color cardHover;
  final Color successBg;
  final Color successTx;
  final Color warningBg;
  final Color warningTx;
  final Color dangerBg;
  final Color dangerTx;
  final Color infoBg;
  final Color infoTx;

  const AppColors({
    required this.indigo50,
    required this.indigo100,
    required this.indigo200,
    required this.indigo400,
    required this.indigo600,
    required this.indigo800,
    required this.surface,
    required this.white,
    required this.border,
    required this.textMain,
    required this.textMuted,
    required this.textHint,
    required this.cardBg,
    required this.cardHover,
    required this.successBg,
    required this.successTx,
    required this.warningBg,
    required this.warningTx,
    required this.dangerBg,
    required this.dangerTx,
    required this.infoBg,
    required this.infoTx,
  });

  static const light = AppColors(
    indigo50: Color(0xFFEEEDFE),
    indigo100: Color(0xFFCECBF6),
    indigo200: Color(0xFFAFA9EC),
    indigo400: Color(0xFF7F77DD),
    indigo600: Color(0xFF534AB7),
    indigo800: Color(0xFF3C3489),
    surface: Color(0xFFF5F4FE),
    white: Color(0xFFFFFFFF),
    border: Color(0xFFE2E0F8),
    textMain: Color(0xFF1E1B4B),
    textMuted: Color(0xFF6B67A8),
    textHint: Color(0xFFAFA9EC),
    cardBg: Color(0xFFFFFFFF),
    cardHover: Color(0xFFF5F4FE),
    successBg: Color(0xFFEAF3DE),
    successTx: Color(0xFF3B6D11),
    warningBg: Color(0xFFFAEEDA),
    warningTx: Color(0xFF854F0B),
    dangerBg: Color(0xFFFCEBEB),
    dangerTx: Color(0xFFA32D2D),
    infoBg: Color(0xFFE6F1FB),
    infoTx: Color(0xFF185FA5),
  );

  static const dark = AppColors(
    indigo50: Color(0xFF19172B),
    indigo100: Color(0xFF211F3A),
    indigo200: Color(0xFF302D52),
    indigo400: Color(0xFF9189F3),
    indigo600: Color(0xFF746BE5),
    indigo800: Color(0xFFC7C2FF),
    surface: Color(0xFF0D0D14),
    white: Color(0xFF13131D),
    border: Color(0xFF252536),
    textMain: Color(0xFFF0F0FF),
    textMuted: Color(0xFFB7B7D0),
    textHint: Color(0xFF85859F),
    cardBg: Color(0xFF181822),
    cardHover: Color(0xFF20202C),
    successBg: Color(0xFF162A1D),
    successTx: Color(0xFF80D88B),
    warningBg: Color(0xFF2C220F),
    warningTx: Color(0xFFE5B94E),
    dangerBg: Color(0xFF301616),
    dangerTx: Color(0xFFF08080),
    infoBg: Color(0xFF102536),
    infoTx: Color(0xFF68B5F2),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      indigo50: Color.lerp(indigo50, other.indigo50, t)!,
      indigo100: Color.lerp(indigo100, other.indigo100, t)!,
      indigo200: Color.lerp(indigo200, other.indigo200, t)!,
      indigo400: Color.lerp(indigo400, other.indigo400, t)!,
      indigo600: Color.lerp(indigo600, other.indigo600, t)!,
      indigo800: Color.lerp(indigo800, other.indigo800, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      white: Color.lerp(white, other.white, t)!,
      border: Color.lerp(border, other.border, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      successBg: Color.lerp(successBg, other.successBg, t)!,
      successTx: Color.lerp(successTx, other.successTx, t)!,
      warningBg: Color.lerp(warningBg, other.warningBg, t)!,
      warningTx: Color.lerp(warningTx, other.warningTx, t)!,
      dangerBg: Color.lerp(dangerBg, other.dangerBg, t)!,
      dangerTx: Color.lerp(dangerTx, other.dangerTx, t)!,
      infoBg: Color.lerp(infoBg, other.infoBg, t)!,
      infoTx: Color.lerp(infoTx, other.infoTx, t)!,
    );
  }
}

extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
