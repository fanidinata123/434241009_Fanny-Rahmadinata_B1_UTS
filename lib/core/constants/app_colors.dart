import 'package:flutter/material.dart';

const _primary      = Color(0xFF7B68D0);
const _primaryLight = Color(0xFFA89FDE);

// Background lebih gelap dan hangat
const _bgMain  = Color(0xFFEED5E8); // pink muda agak gelap
const _bgBlue  = Color(0xFFD5E2F5); // biru muda agak gelap
const _bgCard  = Color(0xFFE8D0E5); // card: pink-lavender
const _border  = Color(0xFFC8B0D8); // border lebih visible

class AppColors {
  static const Color primary      = _primary;
  static const Color primaryLight = _primaryLight;
  static const Color secondary    = Color(0xFF2A9D8F);
  static const Color accent       = Color(0xFFE76F51);

  static const Color backgroundPink = _bgMain;
  static const Color backgroundBlue = _bgBlue;
  static const Color cardColor      = _bgCard;
  static const Color borderColor    = _border;

  static const Color statusOpen       = Color(0xFF378ADD);
  static const Color statusInProgress = Color(0xFFEF9F27);
  static const Color statusResolved   = Color(0xFF1D9E75);
  static const Color statusClosed     = Color(0xFF888780);

  static const Color priorityLow      = Color(0xFF639922);
  static const Color priorityMedium   = Color(0xFFBA7517);
  static const Color priorityHigh     = Color(0xFFD85A30);
  static const Color priorityCritical = Color(0xFFE24B4A);

  // ── LIGHT THEME ──────────────────────────────────────────
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: _primary,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDDD8F5),
      onPrimaryContainer: const Color(0xFF3D2C5E),
      secondary: const Color(0xFF2A9D8F),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFC8E8E0),
      onSecondaryContainer: const Color(0xFF0F3D38),
      error: const Color(0xFFE24B4A),
      onError: Colors.white,
      errorContainer: const Color(0xFFF5D8D8),
      onErrorContainer: const Color(0xFF7A1F1F),
      surface: _bgBlue,
      onSurface: const Color(0xFF2E1E4A),
      surfaceContainerHighest: _bgCard,
      outline: _border,
      outlineVariant: const Color(0xFFD8C0E0),
    ),
    scaffoldBackgroundColor: _bgMain,
    appBarTheme: const AppBarTheme(
      backgroundColor: _bgMain,
      foregroundColor: Color(0xFF2E1E4A),
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _bgCard,
      indicatorColor: const Color(0xFFD8D0F0),
      shadowColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primary);
        }
        return const TextStyle(fontSize: 11, color: Color(0xFF8A7090));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _primary, size: 22);
        }
        return const IconThemeData(color: Color(0xFF8A7090), size: 22);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: _bgCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _border, width: 0.8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _bgBlue,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border, width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE24B4A)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE24B4A), width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF9A80A8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primary,
        side: const BorderSide(color: _primary, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _bgBlue,
      selectedColor: const Color(0xFFD8D0F0),
      labelStyle: const TextStyle(fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border, width: 0.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: _border, thickness: 0.5),
    listTileTheme: const ListTileThemeData(iconColor: _primary),
  );

  // ── DARK THEME ───────────────────────────────────────────
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: _primaryLight,
      onPrimary: const Color(0xFF1A1030),
      primaryContainer: const Color(0xFF3D3080),
      onPrimaryContainer: const Color(0xFFEDE8FB),
      secondary: const Color(0xFF4ECDC4),
      onSecondary: const Color(0xFF0A2020),
      secondaryContainer: const Color(0xFF1A3030),
      onSecondaryContainer: const Color(0xFFB8EEE8),
      error: const Color(0xFFF09595),
      onError: const Color(0xFF500000),
      errorContainer: const Color(0xFF791F1F),
      onErrorContainer: const Color(0xFFF7C1C1),
      surface: const Color(0xFF2A2035),
      onSurface: const Color(0xFFF0E8F8),
      surfaceContainerHighest: const Color(0xFF352845),
      outline: const Color(0xFF6A5880),
      outlineVariant: const Color(0xFF4A3860),
    ),
    scaffoldBackgroundColor: const Color(0xFF221830),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2A2035),
      foregroundColor: Color(0xFFF0E8F8),
      elevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF2A2035),
      indicatorColor: const Color(0xFF3D3080),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _primaryLight);
        }
        return const TextStyle(fontSize: 11, color: Color(0xFF8A7898));
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _primaryLight, size: 22);
        }
        return const IconThemeData(color: Color(0xFF8A7898), size: 22);
      }),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF352845),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFF4A3860), width: 0.8),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF3A2C4A),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6A5880), width: 0.8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF09595)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF09595), width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF7A6888)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: const Color(0xFF1A1030),
        minimumSize: const Size(double.infinity, 50),
        padding: const EdgeInsets.symmetric(vertical: 14),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryLight,
        side: const BorderSide(color: _primaryLight, width: 1.2),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _primaryLight,
        foregroundColor: const Color(0xFF1A1030),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF352845),
      selectedColor: const Color(0xFF3D3080),
      labelStyle: const TextStyle(fontSize: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF6A5880), width: 0.5),
      ),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFF4A3860), thickness: 0.5),
    listTileTheme: const ListTileThemeData(iconColor: _primaryLight),
  );
}