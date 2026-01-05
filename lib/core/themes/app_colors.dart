import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background colors
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF21262D);
  static const Color surfaceHover = Color(0xFF30363D);

  // Border colors
  static const Color border = Color(0xFF30363D);
  static const Color borderLight = Color(0xFF21262D);

  // Accent colors
  static const Color primary = Color(0xFF58A6FF);
  static const Color primaryHover = Color(0xFF79C0FF);
  static const Color secondary = Color(0xFF238636);
  static const Color secondaryHover = Color(0xFF2EA043);

  // Status colors
  static const Color success = Color(0xFF238636);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Text colors
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);
  static const Color textLink = Color(0xFF58A6FF);

  // Git colors
  static const Color gitAdded = Color(0xFF3FB950);
  static const Color gitModified = Color(0xFFD29922);
  static const Color gitDeleted = Color(0xFFF85149);
  static const Color gitUntracked = Color(0xFF8B949E);

  // Syntax highlighting colors
  static const Color syntaxKeyword = Color(0xFFFF7B72);
  static const Color syntaxString = Color(0xFFA5D6FF);
  static const Color syntaxNumber = Color(0xFF79C0FF);
  static const Color syntaxComment = Color(0xFF8B949E);
  static const Color syntaxFunction = Color(0xFFD2A8FF);
  static const Color syntaxVariable = Color(0xFFFFA657);
  static const Color syntaxType = Color(0xFF7EE787);
  static const Color syntaxOperator = Color(0xFFFF7B72);

  // Terminal colors
  static const Color terminalBg = Color(0xFF0D1117);
  static const Color terminalFg = Color(0xFFE6EDF3);
  static const Color terminalCursor = Color(0xFF58A6FF);

  // Editor colors
  static const Color lineNumberBg = Color(0xFF0D1117);
  static const Color lineNumberFg = Color(0xFF6E7681);
  static const Color currentLineBg = Color(0xFF161B22);
  static const Color selectionBg = Color(0xFF264F78);
  static const Color matchBg = Color(0xFF9E6A03);

  // Tab colors
  static const Color tabActive = Color(0xFF0D1117);
  static const Color tabInactive = Color(0xFF161B22);
  static const Color tabBorder = Color(0xFF30363D);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF58A6FF), Color(0xFF79C0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFD2A8FF), Color(0xFFFF7B72)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
