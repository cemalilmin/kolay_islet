import 'package:flutter/material.dart';
import 'dart:io';
import '../models/dress_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';

class DressCard extends StatefulWidget {
  final DressModel dress;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;
  final bool showFavoriteButton;

  const DressCard({
    super.key,
    required this.dress,
    this.onTap,
    this.onFavoritePressed,
    this.showFavoriteButton = true,
  });

  @override
  State<DressCard> createState() => _DressCardState();
}

class _DressCardState extends State<DressCard> with SingleTickerProviderStateMixin {
  late AnimationController _favoriteController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _favoriteController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _favoriteController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _favoriteController.dispose();
    super.dispose();
  }

  void _handleFavorite() {
    _favoriteController.forward().then((_) {
      _favoriteController.reverse();
    });
    widget.onFavoritePressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: 'dress_${widget.dress.id}',
        child: Container(
          decoration: AppDecorations.card,
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Section
              Flexible(
                child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Main Image
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        image: widget.dress.images.isNotEmpty
                            ? DecorationImage(
                                image: widget.dress.images.first.startsWith('/')
                                    ? FileImage(File(widget.dress.images.first))
                                    : NetworkImage(widget.dress.images.first) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.dress.images.isEmpty
                          ? const Center(
                              child: Icon(
                                Icons.checkroom,
                                size: 48,
                                color: AppColors.textLight,
                              ),
                            )
                          : null,
                    ),
                    
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.5),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                    // Favorite Button
                    if (widget.showFavoriteButton)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: GestureDetector(
                          onTap: _handleFavorite,
                          child: AnimatedBuilder(
                            animation: _scaleAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: AppDecorations.softShadow,
                                  ),
                                  child: Icon(
                                    widget.dress.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: widget.dress.isFavorite
                                        ? AppColors.error
                                        : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    
                    // Price Badge
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: AppDecorations.glassmorphism,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₺${widget.dress.pricePerDay.toInt()}',
                              style: AppTextStyles.priceSmall.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              ' /gün',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Rating Badge
                    if (widget.dress.rating > 0)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.secondary,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.dress.rating.toStringAsFixed(1),
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Stock Badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: widget.dress.stockCount > 0
                              ? AppColors.success.withOpacity(0.9)
                              : Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.dress.stockCount > 0
                                  ? Icons.inventory_2
                                  : Icons.block,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.dress.stockCount > 0
                                  ? '${widget.dress.stockCount} adet'
                                  : 'Stokta Yok',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ),
              
              // Info Section
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.dress.title,
                      style: AppTextStyles.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.dress.designer,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.dress.style,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
