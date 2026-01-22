import 'package:flutter/material.dart';

/// Premium Color Palette - Elegant Minimalism
/// High-end banking/luxury e-commerce aesthetic
class AppColors {
  // ============== PRIMARY PALETTE ==============
  
  // Primary - Slate Blue/Charcoal (Professional & Sharp)
  static const Color primary = Color(0xFF1E293B);
  static const Color primaryLight = Color(0xFF334155);
  static const Color primaryDark = Color(0xFF0F172A);
  
  // Secondary - Muted Gold (Bridal/Fashion context)
  static const Color secondary = Color(0xFFC0A062);
  static const Color secondaryLight = Color(0xFFD4AF37);
  
  // ============== BACKGROUNDS ==============
  
  static const Color background = Color(0xFFF8F9FA);     // Soft Grey/White
  static const Color surface = Color(0xFFFFFFFF);         // Pure White
  static const Color surfaceVariant = Color(0xFFF1F5F9); // Light Grey Fill
  
  // ============== TEXT COLORS ==============
  
  static const Color textPrimary = Color(0xFF0F172A);     // Darkest Slate - Headings
  static const Color textSecondary = Color(0xFF334155);   // Slate Grey - Body
  static const Color textTertiary = Color(0xFF64748B);    // Muted - Hints
  static const Color textLight = Color(0xFF94A3B8);       // Very Light
  
  // ============== BORDERS ==============
  
  static const Color border = Color(0xFFE2E8F0);          // Light Grey Border
  static const Color borderFocused = Color(0xFF1E293B);   // Primary when focused
  
  // ============== STATUS COLORS ==============
  
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  
  // ============== CHART COLORS ==============
  
  static const Color chartKiralama = Color(0xFF8B5CF6); // Purple
  static const Color chartSatis = Color(0xFF06B6D4);    // Cyan
  static const Color chartGider = Color(0xFF94A3B8);    // Slate Grey
  
  // ============== GRADIENTS ==============
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFC0A062), Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============== PREMIUM SHADOWS ==============
  
  static List<BoxShadow> get premiumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
  
  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: primary.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}
