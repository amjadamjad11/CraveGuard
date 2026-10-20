import 'package:flutter/material.dart';

class AppColors {
  // Primary palette
  static const darkNavy = Color(0xFF0A1628);
  static const deepNavy = Color(0xFF121E36);
  static const navy = Color(0xFF1A2744);
  static const navyLight = Color(0xFF243352);

  // Accent
  static const deepTeal = Color(0xFF0D7377);
  static const teal = Color(0xFF14919B);
  static const tealLight = Color(0xFF1BA8B3);
  static const mintGreen = Color(0xFF45DFB1);
  static const mintLight = Color(0xFF7AECD0);

  // Neutrals
  static const warmWhite = Color(0xFFF7F7F2);
  static const softWhite = Color(0xFFE8E8E3);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey800 = Color(0xFF424242);

  // Semantic
  static const amber = Color(0xFFFFB347);
  static const softAmber = Color(0xFFFFC97E);
  static const coral = Color(0xFFFF6B6B);
  static const softCoral = Color(0xFFFF8E8E);
  static const lavender = Color(0xFF9B8FD4);
  static const success = Color(0xFF45DFB1);
  static const warning = Color(0xFFFFB347);
  static const error = Color(0xFFFF6B6B);

  // Surface (dark)
  static const surfaceDark = Color(0xFF0F1A2E);
  static const cardDark = Color(0xFF162040);
  static const cardDarkElevated = Color(0xFF1C2A50);

  // Surface (light)
  static const surfaceLight = Color(0xFFF7F7F2);
  static const cardLight = Colors.white;

  // Text (dark theme)
  static const textPrimaryDark = Color(0xFFF0F0EB);
  static const textSecondaryDark = Color(0xFFAAB2C0);
  static const textTertiaryDark = Color(0xFF6B7585);

  // Text (light theme)
  static const textPrimaryLight = Color(0xFF1A1A2E);
  static const textSecondaryLight = Color(0xFF5A5A6E);
  static const textTertiaryLight = Color(0xFF9E9E9E);

  // Gradients
  static const tealGradient = LinearGradient(
    colors: [deepTeal, teal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const mintGradient = LinearGradient(
    colors: [teal, mintGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const navyGradient = LinearGradient(
    colors: [darkNavy, deepNavy],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const coralGradient = LinearGradient(
    colors: [coral, softCoral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
