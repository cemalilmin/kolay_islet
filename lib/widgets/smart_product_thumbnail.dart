import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// SmartProductThumbnail - Simple and reliable product image widget
/// 
/// Uses standard Image.network for maximum compatibility
class SmartProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double borderRadius;
  final bool showBorder;
  final IconData fallbackIcon;
  
  const SmartProductThumbnail({
    super.key,
    this.imageUrl,
    this.size = 60,
    this.borderRadius = 12,
    this.showBorder = true,
    this.fallbackIcon = Icons.dry_cleaning,
  });
  
  /// Small thumbnail (40x40) for compact lists
  const SmartProductThumbnail.small({
    super.key,
    this.imageUrl,
    this.showBorder = true,
    this.fallbackIcon = Icons.dry_cleaning,
  }) : size = 40, borderRadius = 8;
  
  /// Medium thumbnail (60x60) for standard lists
  const SmartProductThumbnail.medium({
    super.key,
    this.imageUrl,
    this.showBorder = true,
    this.fallbackIcon = Icons.dry_cleaning,
  }) : size = 60, borderRadius = 12;
  
  /// Large thumbnail (80x80) for detail views
  const SmartProductThumbnail.large({
    super.key,
    this.imageUrl,
    this.showBorder = true,
    this.fallbackIcon = Icons.dry_cleaning,
  }) : size = 80, borderRadius = 14;
  
  /// Extra large thumbnail (120x120) for hero sections
  const SmartProductThumbnail.xlarge({
    super.key,
    this.imageUrl,
    this.showBorder = true,
    this.fallbackIcon = Icons.dry_cleaning,
  }) : size = 120, borderRadius = 16;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: AppColors.surfaceVariant,
        border: showBorder 
            ? Border.all(color: Colors.grey.shade200, width: 1)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1),
        child: _buildImage(),
      ),
    );
  }
  
  Widget _buildImage() {
    // No image URL - show elegant placeholder
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }
    
    // Has image URL - show network image
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: size,
      height: size,
      cacheWidth: 200,
      cacheHeight: 200,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingIndicator();
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.textLight),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          fallbackIcon,
          color: AppColors.textLight,
          size: size * 0.45,
        ),
      ),
    );
  }
}

/// Circular product thumbnail variant
class SmartProductThumbnailCircle extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showBorder;
  final IconData fallbackIcon;
  
  const SmartProductThumbnailCircle({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.showBorder = true,
    this.fallbackIcon = Icons.dry_cleaning,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceVariant,
        border: showBorder 
            ? Border.all(color: Colors.grey.shade200, width: 1)
            : null,
      ),
      child: ClipOval(
        child: _buildImage(),
      ),
    );
  }
  
  Widget _buildImage() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }
    
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      width: size,
      height: size,
      cacheWidth: 200,
      cacheHeight: 200,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(color: AppColors.surfaceVariant);
      },
      errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: Icon(
          fallbackIcon,
          color: AppColors.textLight,
          size: size * 0.45,
        ),
      ),
    );
  }
}
