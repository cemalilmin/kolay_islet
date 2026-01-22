import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SizeSelector extends StatelessWidget {
  final List<String> sizes;
  final String? selectedSize;
  final ValueChanged<String>? onSizeSelected;
  final Set<String> unavailableSizes;

  const SizeSelector({
    super.key,
    required this.sizes,
    this.selectedSize,
    this.onSizeSelected,
    this.unavailableSizes = const {},
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sizes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final size = sizes[index];
          final isSelected = selectedSize == size;
          final isUnavailable = unavailableSizes.contains(size);

          return GestureDetector(
            onTap: isUnavailable ? null : () => onSizeSelected?.call(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected
                    ? null
                    : isUnavailable
                        ? AppColors.surfaceVariant
                        : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isUnavailable
                            ? Colors.transparent
                            : AppColors.textLight,
                        width: 1.5,
                      ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    size,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: isSelected
                          ? Colors.white
                          : isUnavailable
                              ? AppColors.textLight
                              : AppColors.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  if (isUnavailable)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StrikethroughPainter(),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StrikethroughPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textLight
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(8, size.height - 8),
      Offset(size.width - 8, 8),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
