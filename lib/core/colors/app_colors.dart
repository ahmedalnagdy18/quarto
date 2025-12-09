import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ======= BLACK & GRAY SCALE COLORS =======

  // Backgrounds
  static Color bgDark = const Color(0xFF0F0F0F); // near black
  static Color bgCard = const Color(0xFF1A1A1A); // dark gray
  static Color bgCardLight = const Color(0xFF252525); // medium dark gray
  static Color bgHover = const Color(0xFF333333); // hover gray

  // Text Colors
  static Color textPrimary = const Color(0xFFFFFFFF); // white
  static Color textSecondary = const Color(0xFFCCCCCC); // light gray
  static Color textTertiary = const Color(0xFF999999); // medium gray
  static Color textDim = const Color(0xFF666666); // dim gray

  // Status Colors (in gray scale)
  static Color statusFree = const Color(0xFF4CAF50); // green for free rooms
  static Color statusOccupied = const Color(
    0xFFF44336,
  ); // red for occupied rooms

  // Borders & Dividers
  static Color borderColor = const Color(0xFF2A2A2A); // dark border
  static Color borderLight = const Color(0xFF3A3A3A); // light border

  // Accent Colors (gray scale accents)
  static Color accentPrimary = const Color(0xFF424242); // dark gray accent
  static Color accentSecondary = const Color(0xFF616161); // medium gray accent

  // Special Elements
  static Color incomeHighlight = const Color(
    0xFFFFD700,
  ); // gold for income (أصفر ذهبي)
  static Color timerColor = const Color(0xFF9E9E9E); // gray for timers

  // Sidebar/Topbar (in gray)
  static Color sidebarColor = const Color(0xFF121212); // dark gray
  static Color sidebarAccent = const Color(0xFF1E1E1E); // slightly lighter

  //buttons
  static Color primaryBlue = const Color(0xFF3B82F6); // bright blue
}
