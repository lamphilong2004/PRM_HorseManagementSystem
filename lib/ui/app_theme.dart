import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────
// THEME EXTENSIONS FOR DYNAMIC DARK/LIGHT MODE
// ──────────────────────────────────────────────────────────

class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.bg,
    required this.bg2,
    required this.surface,
    required this.surface2,
    required this.surface3,
    required this.text,
    required this.text2,
    required this.muted,
    required this.border,
    required this.border2,
    required this.primary,
    required this.primaryDark,
    required this.primaryDarker,
    required this.primaryLight,
    required this.primaryRing,
    required this.accent,
    required this.accentLight,
    required this.danger,
    required this.dangerLight,
    required this.warning,
    required this.warningLight,
    required this.success,
    required this.successLight,
    required this.info,
    required this.infoLight,
    required this.purple,
    required this.purpleLight,
    required this.orange,
    required this.orangeLight,
  });

  final Color bg;
  final Color bg2;
  final Color surface;
  final Color surface2;
  final Color surface3;
  final Color text;
  final Color text2;
  final Color muted;
  final Color border;
  final Color border2;
  
  final Color primary;
  final Color primaryDark;
  final Color primaryDarker;
  final Color primaryLight;
  final Color primaryRing;

  final Color accent;
  final Color accentLight;

  final Color danger;
  final Color dangerLight;
  final Color warning;
  final Color warningLight;
  final Color success;
  final Color successLight;
  final Color info;
  final Color infoLight;
  final Color purple;
  final Color purpleLight;
  final Color orange;
  final Color orangeLight;

  @override
  ThemeExtension<AppColorsExtension> copyWith() => this;

  @override
  ThemeExtension<AppColorsExtension> lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      bg: Color.lerp(bg, other.bg, t)!,
      bg2: Color.lerp(bg2, other.bg2, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      surface3: Color.lerp(surface3, other.surface3, t)!,
      text: Color.lerp(text, other.text, t)!,
      text2: Color.lerp(text2, other.text2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      border2: Color.lerp(border2, other.border2, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryDarker: Color.lerp(primaryDarker, other.primaryDarker, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      primaryRing: Color.lerp(primaryRing, other.primaryRing, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentLight: Color.lerp(accentLight, other.accentLight, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerLight: Color.lerp(dangerLight, other.dangerLight, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningLight: Color.lerp(warningLight, other.warningLight, t)!,
      success: Color.lerp(success, other.success, t)!,
      successLight: Color.lerp(successLight, other.successLight, t)!,
      info: Color.lerp(info, other.info, t)!,
      infoLight: Color.lerp(infoLight, other.infoLight, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      purpleLight: Color.lerp(purpleLight, other.purpleLight, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      orangeLight: Color.lerp(orangeLight, other.orangeLight, t)!,
    );
  }
}

class AppTypographyExtension extends ThemeExtension<AppTypographyExtension> {
  const AppTypographyExtension({
    required this.h1,
    required this.h2,
    required this.h3,
    required this.body,
    required this.bodyMuted,
    required this.label,
    required this.caption,
    required this.captionUpper,
    required this.navLink,
    required this.statValue,
    required this.fontFamily,
  });

  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle body;
  final TextStyle bodyMuted;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle captionUpper;
  final TextStyle navLink;
  final TextStyle statValue;
  final String fontFamily;

  @override
  ThemeExtension<AppTypographyExtension> copyWith() => this;

  @override
  ThemeExtension<AppTypographyExtension> lerp(ThemeExtension<AppTypographyExtension>? other, double t) => this;
}

class AppRadiusExtension extends ThemeExtension<AppRadiusExtension> {
  const AppRadiusExtension({
    required this.sm,
    required this.base,
    required this.md,
    required this.lg,
    required this.full,
  });

  final BorderRadius sm;
  final BorderRadius base;
  final BorderRadius md;
  final BorderRadius lg;
  final BorderRadius full;

  @override
  ThemeExtension<AppRadiusExtension> copyWith() => this;

  @override
  ThemeExtension<AppRadiusExtension> lerp(ThemeExtension<AppRadiusExtension>? other, double t) => this;
}

// ──────────────────────────────────────────────────────────
// BUILD THEME DATA
// ──────────────────────────────────────────────────────────

const _radius = AppRadiusExtension(
  sm: BorderRadius.all(Radius.circular(6)),
  base: BorderRadius.all(Radius.circular(12)),
  md: BorderRadius.all(Radius.circular(16)),
  lg: BorderRadius.all(Radius.circular(20)),
  full: BorderRadius.all(Radius.circular(999)),
);

// Role avatars (static as they don't change by theme mode)
class AppRoleColors {
  static const avatarAdmin     = [Color(0xFFA78BFA), Color(0xFF8B5CF6)]; // Sáng hơn
  static const avatarOwner     = [Color(0xFF34D399), Color(0xFF10B981)]; // Sáng hơn
  static const avatarJockey    = [Color(0xFFFBBF24), Color(0xFFF59E0B)]; // Vàng cam sáng hơn
  static const avatarReferee   = [Color(0xFF60A5FA), Color(0xFF3B82F6)]; // Xanh dương sáng hơn
  static const avatarSpectator = [Color(0xFF94A3B8), Color(0xFF64748B)]; // Xám bạc sáng hơn
  static const avatarDefault   = [Color(0xFF818CF8), Color(0xFF6366F1)]; // Sáng hơn
}

// Dark Mode Colors
const _colorsDark = AppColorsExtension(
  bg: Color(0xFF04100C),
  bg2: Color(0xFF060E18),
  surface: Color(0xFF101928),
  surface2: Color(0xFF1A2436),
  surface3: Color(0xFF233044),
  text: Color(0xFFFFFFFF),
  text2: Color(0xFFF8FAFC),
  muted: Color(0xB8FFFFFF),
  border: Color(0x24FFFFFF),
  border2: Color(0x3DFFFFFF),
  primary: Color(0xFF10B981),
  primaryDark: Color(0xFF059669),
  primaryDarker: Color(0xFF047857),
  primaryLight: Color(0x2610B981),
  primaryRing: Color(0x4010B981),
  accent: Color(0xFFF59E0B),
  accentLight: Color(0x26F59E0B),
  danger: Color(0xFFEF4444),
  dangerLight: Color(0x26EF4444),
  warning: Color(0xFFF59E0B),
  warningLight: Color(0x26F59E0B),
  success: Color(0xFF10B981),
  successLight: Color(0x2610B981),
  info: Color(0xFF3B82F6),
  infoLight: Color(0x263B82F6),
  purple: Color(0xFF8B5CF6),
  purpleLight: Color(0x268B5CF6),
  orange: Color(0xFFF97316),
  orangeLight: Color(0x26F97316),
);

// Light Mode Colors
const _colorsLight = AppColorsExtension(
  bg: Color(0xFFF8FAFC),
  bg2: Color(0xFFFFFFFF),
  surface: Color(0xFFFFFFFF),
  surface2: Color(0xFFF1F5F9),
  surface3: Color(0xFFE2E8F0),
  text: Color(0xFF0F172A),
  text2: Color(0xFF334155),
  muted: Color(0xFF64748B),
  border: Color(0xFFE2E8F0),
  border2: Color(0xFFCBD5E1),
  primary: Color(0xFF10B981),
  primaryDark: Color(0xFF059669),
  primaryDarker: Color(0xFF047857),
  primaryLight: Color(0x2610B981),
  primaryRing: Color(0x4010B981),
  accent: Color(0xFFF59E0B),
  accentLight: Color(0x26F59E0B),
  danger: Color(0xFFEF4444),
  dangerLight: Color(0x26EF4444),
  warning: Color(0xFFF59E0B),
  warningLight: Color(0x26F59E0B),
  success: Color(0xFF10B981),
  successLight: Color(0x2610B981),
  info: Color(0xFF3B82F6),
  infoLight: Color(0x263B82F6),
  purple: Color(0xFF8B5CF6),
  purpleLight: Color(0x268B5CF6),
  orange: Color(0xFFF97316),
  orangeLight: Color(0x26F97316),
);

AppTypographyExtension _buildTypography(AppColorsExtension colors) {
  final String fontFamily = GoogleFonts.inter().fontFamily ?? 'Inter';
  
  return AppTypographyExtension(
    h1: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.7, color: colors.text, height: 1.2),
    h2: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: colors.text, height: 1.3),
    h3: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w700, color: colors.text, height: 1.4),
    body: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: colors.text2, height: 1.5),
    bodyMuted: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: colors.muted, height: 1.5),
    label: TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w600, color: colors.text2, height: 1.4),
    caption: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: colors.muted, letterSpacing: 0.4, height: 1.3),
    captionUpper: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: colors.muted, letterSpacing: 0.8, height: 1.3),
    navLink: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: colors.text2, height: 1.4),
    statValue: TextStyle(fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.84, color: colors.text, height: 1.0),
    fontFamily: fontFamily,
  );
}

ThemeData buildAppTheme({bool isDark = true}) {
  final colors = isDark ? _colorsDark : _colorsLight;
  final typography = _buildTypography(colors);
  final fontFamily = GoogleFonts.inter().fontFamily;

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    fontFamily: fontFamily,
    extensions: [colors, typography, _radius],

    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: colors.primary,
      onPrimary: Colors.white,
      secondary: colors.surface2,
      onSecondary: colors.text2,
      surface: colors.bg,
      onSurface: colors.text,
      error: colors.danger,
      onError: Colors.white,
    ),

    scaffoldBackgroundColor: colors.bg,

    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? const Color(0xD904100C) : const Color(0xD9F8FAFC),
      foregroundColor: colors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: typography.h3.copyWith(fontSize: 17, letterSpacing: -0.2),
      iconTheme: IconThemeData(color: colors.text2, size: 22),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isDark ? const Color(0xF004100C) : const Color(0xF0F8FAFC),
      selectedItemColor: colors.primary,
      unselectedItemColor: colors.muted,
      selectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      unselectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: isDark ? const Color(0xB30D1626) : Colors.white,
      elevation: isDark ? 0 : 2,
      shadowColor: isDark ? Colors.transparent : const Color(0x1A0A0F1E),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: _radius.lg,
        side: BorderSide(color: colors.border, width: 1),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 1,
      space: 0,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0x0AFFFFFF) : colors.surface2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      hintStyle: typography.bodyMuted,
      labelStyle: typography.label,
      border: OutlineInputBorder(
        borderRadius: _radius.base,
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: _radius.base,
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: _radius.base,
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: _radius.base,
        borderSide: BorderSide(color: colors.danger),
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1),
        shape: RoundedRectangleBorder(borderRadius: _radius.base),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.text2,
        side: BorderSide(color: colors.border),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        textStyle: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: _radius.base),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        textStyle: TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor: colors.surface2,
      labelStyle: TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w600, color: colors.text2),
      side: BorderSide(color: colors.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    ),

    listTileTheme: ListTileThemeData(
      iconColor: colors.muted,
      textColor: colors.text2,
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    ),

    textTheme: TextTheme(
      displayLarge:  typography.h1,
      displayMedium: typography.h2,
      displaySmall:  typography.h3,
      bodyLarge:     typography.body,
      bodyMedium:    typography.bodyMuted,
      labelLarge:    typography.label,
      labelMedium:   typography.caption,
      labelSmall:    typography.captionUpper,
    ),

    iconTheme: IconThemeData(color: colors.muted, size: 20),
    primaryIconTheme: IconThemeData(color: colors.primary, size: 20),
  );
}

// Helper extension to access theme easily
extension BuildContextTheme on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
  AppTypographyExtension get typography => Theme.of(this).extension<AppTypographyExtension>()!;
  AppRadiusExtension get radii => Theme.of(this).extension<AppRadiusExtension>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
