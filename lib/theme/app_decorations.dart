import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDecorations {
  // BORDER RADIUS VALUES
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 28.0;
  
  // SHADOWS
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 30,
      offset: const Offset(0, 12),
    ),
  ];
  
  static List<BoxShadow> get primaryGlow => [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  // CARD DECORATIONS
  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: softShadow,
  );
  
  static BoxDecoration get cardElevated => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: mediumShadow,
  );
  
  // GLASSMORPHISM
  static BoxDecoration get glassmorphism => BoxDecoration(
    color: Colors.white.withOpacity(0.75),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: Colors.white.withOpacity(0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
  
  static BoxDecoration get glassmorphismDark => BoxDecoration(
    color: Colors.black.withOpacity(0.3),
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1,
    ),
  );
  
  // BUTTONS
  static BoxDecoration get primaryButton => BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(radiusMedium),
    boxShadow: primaryGlow,
  );
  
  static BoxDecoration get secondaryButton => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(color: AppColors.primary, width: 2),
  );
  
  // INPUT FIELDS
  static BoxDecoration get inputField => BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(
      color: Colors.transparent,
      width: 2,
    ),
  );
  
  static BoxDecoration get inputFieldFocused => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radiusMedium),
    border: Border.all(
      color: AppColors.primary,
      width: 2,
    ),
  );
  
  // CHIPS & TAGS
  static BoxDecoration get chip => BoxDecoration(
    color: AppColors.secondary.withOpacity(0.5),
    borderRadius: BorderRadius.circular(radiusSmall),
  );
  
  static BoxDecoration get chipSelected => BoxDecoration(
    gradient: AppColors.primaryGradient,
    borderRadius: BorderRadius.circular(radiusSmall),
  );
  
  // IMAGE CONTAINERS
  static BoxDecoration get imageContainer => BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(radiusLarge),
  );
  
  static BoxDecoration imageContainerWithBorder(Color borderColor) => BoxDecoration(
    color: AppColors.surfaceVariant,
    borderRadius: BorderRadius.circular(radiusLarge),
    border: Border.all(color: borderColor, width: 3),
  );
}
