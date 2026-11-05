import 'package:flutter/material.dart';

class AppColors {
  // Primary Festival / Traditional Saffron / Gold theme
  static const Color primary = Color(0xFFFF5722); // Deep Saffron / Kesari
  static const Color primaryDark = Color(0xFFE64A19);
  static const Color primaryLight = Color(0xFFFFCCBC);
  static const Color secondary = Color(0xFFFFA000); // Amber / Gold
  static const Color accent = Color(0xFF2E7D32); // Traditional Green / Shubh

  // Neutral Colors
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Colors.white;
  static const Color textPrimaryLight = Color(0xFF1E293B);
  static const Color textSecondaryLight = Color(0xFF64748B);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceDarkCard = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);

  // Financial Indicators
  static const Color success = Color(0xFF10B981); // Paid / Approved / Positive
  static const Color warning = Color(0xFFF59E0B); // Pending / Awaiting
  static const Color error = Color(0xFFEF4444);   // Due / Rejected / Overdue
  static const Color info = Color(0xFF3B82F6);    // Bank / UPI / Info

  // Gradients
  static const LinearGradient saffronGradient = LinearGradient(
    colors: [Color(0xFFFF5722), Color(0xFFFF8A65)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

