import 'package:flutter/material.dart';

/// Reusable design tokens for colors, gradients, shadows and radii
/// Based on the Vargani Collection official brand identity:
/// Primary Purple (#3510B8), Royal Blue (#087BF5), Accent Orange (#FF7900)
class AppColors {
  // Brand Identity Core
  static const Color primaryPurple = Color(0xFF3510B8);
  static const Color royalBlue = Color(0xFF087BF5);
  static const Color accentOrange = Color(0xFFFF7900);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightLavender = Color(0xFFF5F4FA);
  static const Color textPrimary = Color(0xFF19152B);
  static const Color textSecondary = Color(0xFF77738A);

  // App Theme Primary Aliases (for backwards & semantic compatibility)
  static const Color primary = primaryPurple;
  static const Color primaryDark = Color(0xFF240A8A);
  static const Color primaryLight = Color(0xFFEBE6FC);
  static const Color secondary = royalBlue;
  static const Color secondaryLight = Color(0xFFE3F2FD);
  static const Color accent = accentOrange;

  // Background & Surface
  static const Color backgroundLight = lightLavender;
  static const Color surfaceLight = Colors.white;
  static const Color cardBorder = Color(0xFFE6E4F0);
  static const Color dividerColor = Color(0xFFEDEBF5);

  // Text Colors
  static const Color textPrimaryLight = textPrimary;
  static const Color textSecondaryLight = textSecondary;
  static const Color textMuted = Color(0xFFA19DB3);

  // Dark Theme
  static const Color backgroundDark = Color(0xFF0E0B1F);
  static const Color surfaceDark = Color(0xFF181432);
  static const Color surfaceDarkCard = Color(0xFF231E44);
  static const Color textPrimaryDark = Color(0xFFF8F7FC);
  static const Color textSecondaryDark = Color(0xFFAFAAC4);

  // Financial Status Indicators
  static const Color success = Color(0xFF10B981); // Paid / Approved / Positive
  static const Color successLight = Color(0xFFE8FDF5);
  static const Color warning = Color(0xFFF59E0B); // Pending / Awaiting
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);   // Due / Overdue / Rejected
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF087BF5);    // UPI / Bank / Process
  static const Color infoLight = Color(0xFFEFF6FF);

  // Brand Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPurple, royalBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF2F0DA8), Color(0xFF087BF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF7900), Color(0xFFFF9E42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleSoftGradient = LinearGradient(
    colors: [Color(0xFFF5F4FA), Color(0xFFEDE9FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Legacy alias for backwards compatibility
  static const LinearGradient saffronGradient = primaryGradient;
  static const LinearGradient cardGradient = heroCardGradient;
}

/// Reusable Box Shadows for Premium UI depth
class AppShadows {
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: const Color(0xFF19152B).withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get card => [
    BoxShadow(
      color: const Color(0xFF3510B8).withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get floating => [
    BoxShadow(
      color: const Color(0xFF3510B8).withOpacity(0.20),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get glowOrange => [
    BoxShadow(
      color: const Color(0xFFFF7900).withOpacity(0.28),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}

/// Reusable Corner Radii for smooth, consistent components
class AppRadii {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(20));
  static const BorderRadius xxl = BorderRadius.all(Radius.circular(28));
  static const BorderRadius full = BorderRadius.all(Radius.circular(999));
}
