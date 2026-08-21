import 'package:flutter/material.dart';

ThemeData getTheme(bool isDark) {
  const Color darkNavy = Color(0xFF1E293B);
  const Color bluePrimary = Color(0xFF3B82F6);
  const Color greenSuccess = Color(0xFF10B981);
  const Color redDanger = Color(0xFFEF4444);
  const Color bgColor = Color(0xFFEEF2F5);
  const Color surfaceColor = Colors.white;
  const Color textPrimary = Color(0xFF1E293B);

  return ThemeData(
    useMaterial3: true,
    brightness: isDark ? Brightness.dark : Brightness.light,
    primaryColor: bluePrimary,
    scaffoldBackgroundColor: isDark ? darkNavy : bgColor,
    colorScheme: ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: bluePrimary,
      onPrimary: Colors.white,
      secondary: greenSuccess,
      onSecondary: Colors.white,
      surface: isDark ? const Color(0xFF334155) : surfaceColor,
      onSurface: isDark ? Colors.white : textPrimary,
      error: redDanger,
      onError: Colors.white,
    ),
    cardColor: isDark ? const Color(0xFF334155) : surfaceColor,
    dividerColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
    appBarTheme: AppBarTheme(
      backgroundColor: darkNavy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      titleTextStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      toolbarHeight: 44,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: bluePrimary,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: isDark ? darkNavy : surfaceColor,
      selectedItemColor: bluePrimary,
      unselectedItemColor: Colors.grey,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(fontFamily: 'Cairo', fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary),
      displayMedium: TextStyle(fontFamily: 'Cairo', fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
      headlineLarge: TextStyle(fontFamily: 'Cairo', fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      headlineMedium: TextStyle(fontFamily: 'Cairo', fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: TextStyle(fontFamily: 'Cairo', fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: TextStyle(fontFamily: 'Cairo', fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      bodyLarge: TextStyle(fontFamily: 'Cairo', fontSize: 14, color: textPrimary),
      bodyMedium: TextStyle(fontFamily: 'Cairo', fontSize: 13, color: textPrimary),
      bodySmall: TextStyle(fontFamily: 'Cairo', fontSize: 11, color: Color(0xFF64748B)),
      labelLarge: TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: bluePrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: redDanger),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontFamily: 'Cairo', fontSize: 12),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontFamily: 'Cairo', fontSize: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bluePrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
        textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13, fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: bluePrimary,
        side: const BorderSide(color: Color(0xFFCBD5E1)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: bluePrimary,
        textStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
      selectedColor: bluePrimary,
      labelStyle: TextStyle(color: isDark ? Colors.white : textPrimary, fontFamily: 'Cairo', fontSize: 11),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: isDark ? const Color(0xFF334155) : surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF334155) : surfaceColor,
      elevation: 1,
      shadowColor: Colors.black.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: isDark ? const Color(0xFF334155) : surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: isDark ? const Color(0xFF334155) : surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkNavy,
      contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Cairo', fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
      space: 1,
    ),
  );
}
