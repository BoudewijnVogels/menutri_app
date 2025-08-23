import 'package:flutter/material.dart';

class AppColors {
  // Primary colors from user specification (Brown theme)
  static const Color darkBrown = Color(0xFF1D140C);
  static const Color mediumBrown = Color(0xFFAA8474);
  static const Color lightBrown = Color(0xFFDFD3CE);
  static const Color white = Color(0xFFFFFFFF);

  // Theme aliases for consistency
  static const Color primary = mediumBrown;
  static const Color secondary = lightBrown;
  static const Color surface = white;
  static const Color background = white;
  static const Color onPrimary = white;
  static const Color onSecondary = darkBrown;
  static const Color onSurface = darkBrown;
  static const Color onBackground = darkBrown;
  static const Color outline = Color(0xFFE5E7EB); // ✅ toegevoegd (grijs randje)

  // Text colors
  static const Color textPrimary = darkBrown;
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = white;

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Calorie margin badge colors (from blueprint)
  static const Color calorieMarginLow = Color(0xFFB0BEC5); // ≤5% - Grey
  static const Color calorieMarginMedium = Color(0xFFFFCA28); // 5-10% - Amber
  static const Color calorieMarginHigh = Color(0xFFFF7043); // 10-15% - Orange
  static const Color calorieMarginVeryHigh = Color(0xFFD32F2F); // >15% - Red

  // Additional UI colors
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF6B7280);
  static const Color lightGrey = Color(0xFFF3F4F6);
  static const Color darkGrey = Color(0xFF374151);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color dividerColor = Color(0xFFE5E7EB);

  // Status badge colors
  static const Color statusActive = Color(0xFF10B981);
  static const Color statusInactive = Color(0xFF6B7280);
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusDraft = Color(0xFF8B5CF6);
  static const Color statusScheduled = Color(0xFF3B82F6);
  static const Color statusPaused = Color(0xFFFF7043);
  static const Color statusCompleted = Color(0xFF6B7280);
  static const Color statusExpired = Color(0xFFEF4444);

  // Role colors for team management
  static const Color roleOwner = Color(0xFF7C3AED);
  static const Color roleAdmin = Color(0xFFDC2626);
  static const Color roleManager = Color(0xFF059669);
  static const Color roleStaff = Color(0xFF2563EB);
  static const Color roleViewer = Color(0xFF6B7280);

  // Notification type colors
  static const Color notificationReview = Color(0xFF3B82F6);
  static const Color notificationOrder = Color(0xFF10B981);
  static const Color notificationTeam = Color(0xFF8B5CF6);
  static const Color notificationSystem = Color(0xFF6B7280);
  static const Color notificationPromotion = Color(0xFFFF7043);
  static const Color notificationAnalytics = Color(0xFF06B6D4);
  static const Color notificationMenu = Color(0xFFF59E0B);
  static const Color notificationSecurity = Color(0xFFEF4444);
  static const Color notificationMarketing = Color(0xFFEC4899);
  static const Color notificationSupport = Color(0xFF84CC16);

  // Chart colors for analytics
  static const List<Color> chartColors = [
    Color(0xFFAA8474), // Primary brown
    Color(0xFF3B82F6), // Blue
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF84CC16), // Lime
    Color(0xFFF97316), // Orange
  ];

  // Gradient colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBrown, mediumBrown],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBrown, white],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  static const LinearGradient warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const LinearGradient errorGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );

  // Shadow colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);

  // Overlay colors
  static const Color overlayLight = Color(0x1AFFFFFF);
  static const Color overlayMedium = Color(0x33FFFFFF);
  static const Color overlayDark = Color(0x4DFFFFFF);

  // Helper methods for dynamic colors
  static Color getCalorieMarginColor(double percentage) {
    if (percentage <= 5) return calorieMarginLow;
    if (percentage <= 10) return calorieMarginMedium;
    if (percentage <= 15) return calorieMarginHigh;
    return calorieMarginVeryHigh;
  }

  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return roleOwner;
      case 'admin':
        return roleAdmin;
      case 'manager':
        return roleManager;
      case 'staff':
        return roleStaff;
      case 'viewer':
        return roleViewer;
      default:
        return grey;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return statusActive;
      case 'inactive':
        return statusInactive;
      case 'pending':
        return statusPending;
      case 'draft':
        return statusDraft;
      case 'scheduled':
        return statusScheduled;
      case 'paused':
        return statusPaused;
      case 'completed':
        return statusCompleted;
      case 'expired':
        return statusExpired;
      default:
        return grey;
    }
  }

  static Color getNotificationTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'review':
      case 'reviews':
        return notificationReview;
      case 'order':
      case 'orders':
        return notificationOrder;
      case 'team':
        return notificationTeam;
      case 'system':
        return notificationSystem;
      case 'promotion':
      case 'promotions':
        return notificationPromotion;
      case 'analytics':
        return notificationAnalytics;
      case 'menu':
      case 'menus':
        return notificationMenu;
      case 'security':
        return notificationSecurity;
      case 'marketing':
        return notificationMarketing;
      case 'support':
        return notificationSupport;
      default:
        return grey;
    }
  }

// ✅ Hulpfunctie ter vervanging van withOpacity (deprecated)
// Gebruik: AppColors.withAlphaFraction(Colors.black, 0.1)
  static Color withAlphaFraction(Color color, double fraction) {
    final clamped = fraction.clamp(0.0, 1.0);
    return color.withValues(alpha: clamped * 255.0);
  }
}
