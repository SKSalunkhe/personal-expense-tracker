import 'package:flutter/material.dart';

class AppColors {
  // ── Legacy / kept for compatibility ──
  static const Color beige = Color(0xFFD8A47F);
  static const Color orange = Color(0xFFFF7A45);
  static const Color pinkRed = Color(0xFFEC4899);   // now hot-pink
  static const Color deepRose = Color(0xFFDB2777);  // deep pink
  static const Color teal = Color(0xFFC084FC);       // repurposed → light purple
  static const Color background = Color(0xFF0D0A1A);
  static const Color cardBackground = Color(0xFF18122B);
  static const Color textDark = Color(0xFFE2D9F3);

  // ── Dark Background Layers ──
  static const Color darkBg = Color(0xFF0A0712);      // very deep purple-black
  static const Color darkCard = Color(0xFF140E25);    // dark purple card
  static const Color darkInput = Color(0xFF1B1330);   // input bg
  static const Color darkBorder = Color(0xFF2E1F4A);  // purple-tinted border
  static const Color darkSurface = Color(0xFF200A40);

  // ── Primary Accent: Purple → Pink gradient ──
  static const Color purple = Color(0xFF8B5CF6);       // medium violet-purple
  static const Color purpleLight = Color(0xFFC084FC);  // soft lavender
  static const Color purpleFaint = Color(0x268B5CF6);
  static const Color cyan = Color(0xFFEC4899);         // hot pink (replaces cyan)
  static const Color cyanLight = Color(0xFFF9A8D4);    // light pink

  // ── Gradient Definitions ──
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],   // Purple → Hot Pink
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1C1035), Color(0xFF140E25)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF1E0A40), Color(0xFF30083A)],   // deep purple → deep magenta
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient expenseGradient = LinearGradient(
    colors: [Color(0xFF2D0A5C), Color(0xFF4A0A38)],   // dark purple → dark pink
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],   // purple → pink (savings)
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient roseGradient = LinearGradient(
    colors: [Color(0xFFDB2777), Color(0xFF9333EA)],   // deep pink → purple
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Text Colors ──
  static const Color textWhite = Color(0xFFF5F0FF);   // warm white with purple tint
  static const Color textGrey = Color(0xFF9B8EC4);    // purple-grey
  static const Color textMuted = Color(0xFFB8A9DC);   // soft lavender
  static const Color textDimmed = Color(0xFF4D3D7A);  // dim purple
}