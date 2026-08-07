// Sistema de diseño Wisetrack One (light + dark).

import 'package:flutter/material.dart';

// Colores de marca (iguales en claro/oscuro)
const kTeal       = Color(0xFF008896);
const kTealBright = Color(0xFF0AB4B0);
const kTeal600    = Color(0xFF0A8A95);
const kPetrol     = Color(0xFF0A5A62);
const kPetrolDark = Color(0xFF073E45);
const kGreen      = Color(0xFF51B05A);
const kOrange     = Color(0xFFF08A3C);
const kRed        = Color(0xFFF34235);

// Paleta de superficies/texto (cambia por modo).
// Incluye los "soft" y el panel, que deben oscurecer en modo oscuro.
class WtColors {
  final Color bg, surface, surface2, neutral, divider;
  final Color ink, ink2, gray, grayLight, line, lineStrong;
  final Color tealSoft, orangeSoft, redSoft, greenSoft;
  final Color panel, disabled;
  const WtColors({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.neutral,
    required this.divider,
    required this.ink,
    required this.ink2,
    required this.gray,
    required this.grayLight,
    required this.line,
    required this.lineStrong,
    required this.tealSoft,
    required this.orangeSoft,
    required this.redSoft,
    required this.greenSoft,
    required this.panel,
    required this.disabled,
  });
}

const _light = WtColors(
  bg: Color(0xFFF4F8F8),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF9FCFC),
  neutral: Color(0xFFEDF3F3),
  divider: Color(0xFFF0F5F5),
  ink: Color(0xFF15211F),
  ink2: Color(0xFF364643),
  gray: Color(0xFF6B7B7C),
  grayLight: Color(0xFF9DABAB),
  line: Color(0xFFE4ECEC),
  lineStrong: Color(0xFFCBD8D8),
  tealSoft: Color(0xFFE2F1F1),
  orangeSoft: Color(0xFFFDE7D4),
  redSoft: Color(0xFFFDEAE8),
  greenSoft: Color(0xFFEAF6EB),
  panel: Color(0xFF052E33),
  disabled: Color(0xFFDCE6E6),
);

const _dark = WtColors(
  bg: Color(0xFF0E1514),
  surface: Color(0xFF17211F),
  surface2: Color(0xFF1B2523),
  neutral: Color(0xFF1E2826),
  divider: Color(0xFF202B29),
  ink: Color(0xFFEFF5F4),
  ink2: Color(0xFFC6D2D0),
  gray: Color(0xFF93A2A2),
  grayLight: Color(0xFF647473),
  line: Color(0xFF25302E),
  lineStrong: Color(0xFF35423F),
  tealSoft: Color(0xFF10312F),
  orangeSoft: Color(0xFF3A2A18),
  redSoft: Color(0xFF3A1E1C),
  greenSoft: Color(0xFF16301A),
  panel: Color(0xFF0B1918),
  disabled: Color(0xFF2A3533),
);

/// Paleta activa (se fija en main antes de construir el árbol).
WtColors wt = _light;
void setWtBrightness(Brightness b) =>
    wt = (b == Brightness.dark) ? _dark : _light;

// Sombras
const kShadowXs = [
  BoxShadow(color: Color(0x0F083236), blurRadius: 2, offset: Offset(0, 1)),
];
const kShadowCard = [
  BoxShadow(color: Color(0x14083C40), blurRadius: 16, offset: Offset(0, 4)),
];
const kShadowBtn = [
  BoxShadow(color: Color(0x4D0A5A62), blurRadius: 16, offset: Offset(0, 6)),
];
const kShadowModal = [
  BoxShadow(color: Color(0x4705282C), blurRadius: 50, offset: Offset(0, 18)),
];

/// ThemeData basado en la paleta WtColors.
ThemeData wtTheme(WtColors c, Brightness b) => ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: c.bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kTeal,
        primary: kPetrol,
        secondary: kTeal,
        surface: c.surface,
        error: kRed,
        brightness: b,
      ),
      fontFamily: 'Poppins',
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: c.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: kPetrol,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 15),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.grayLight),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: kTeal, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.tealSoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color:
                s.contains(WidgetState.selected) ? kPetrol : c.grayLight,
          ),
        ),
      ),
    );
