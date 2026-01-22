import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/dress_model.dart';
import '../models/review_model.dart';
import '../services/data_service.dart';
import '../widgets/image_carousel.dart';
import '../widgets/size_selector.dart';
import '../widgets/date_range_picker.dart';
import '../widgets/review_card.dart';
import 'booking_screen.dart';

class DressDetailScreen extends StatefulWidget {
  final DressModel dress;

  const DressDetailScreen({super.key, required this.dress});

  @override
  State<DressDetailScreen> createState() => _DressDetailScreenState();
}

class _DressDetailScreenState extends State<DressDetailScreen> {
  final DataService _dataService = DataService();
  String? _selectedSize;
  DateTimeRange? _selectedDateRange;
  bool _showCalendar = false;
  late List<ReviewModel> _reviews;

  @override
  void initState() {
    super.initState();
    _reviews = _dataService.getReviewsForDress(widget.dress.id);
  }

  double get _totalPrice {
    if (_selectedDateRange == null) return widget.dress.pricePerDay;
    final days = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
    return widget.dress.pricePerDay * days;
  }

  int get _rentalDays {
    if (_selectedDateRange == null) return 1;
    return _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main Content
          CustomScrollView(
            slivers: [
              // Image Carousel
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Hero(
                      tag: 'dress_${widget.dress.id}',
                      child: ImageCarousel(
                        images: widget.dress.images,
                        height: MediaQuery.of(context).size.height * 0.5,
                        enableZoom: true,
                      ),
                    ),
                    // Back Button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: _buildCircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.pop(context),
                      ),
                    ),
                    // Share & Favorite Buttons
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      right: 16,
                      child: Row(
                        children: [
                          _buildCircleButton(
                            icon: Icons.share_outlined,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _buildCircleButton(
                            icon: widget.dress.isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: widget.dress.isFavorite
                                ? AppColors.error
                                : null,
                            onTap: () {
                              setState(() {
                                _dataService.toggleFavorite(widget.dress.id);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  transform: Matrix4.translationValues(0, -24, 0),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title & Rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.dress.title,
                                    style: AppTextStyles.headlineMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.dress.designer,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.secondary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.dress.rating.toStringAsFixed(1),
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    ' (${widget.dress.reviewCount})',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.dress.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                tag,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Price Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: AppDecorations.card,
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₺${widget.dress.pricePerDay.toInt()}',
                                    style: AppTextStyles.price.copyWith(
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                  Text(
                                    '/ gün',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              if (widget.dress.discountPercentage > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '%${widget.dress.discountPercentage} indirim',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Satış Fiyatı',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.textLight,
                                    ),
                                  ),
                                  Text(
                                    '₺${widget.dress.originalPrice.toInt()}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.textSecondary,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Size Selection
                        Text(
                          'Beden Seçin',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizeSelector(
                          sizes: widget.dress.availableSizes,
                          selectedSize: _selectedSize,
                          onSizeSelected: (size) {
                            setState(() => _selectedSize = size);
                          },
                        ),

                        const SizedBox(height: 24),

                        // Date Selection
                        Text(
                          'Tarih Seçin',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() => _showCalendar = !_showCalendar);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppDecorations.card,
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_month,
                                  color: const Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _selectedDateRange != null
                                        ? '${_formatDate(_selectedDateRange!.start)} - ${_formatDate(_selectedDateRange!.end)}'
                                        : 'Tarih aralığı seçin',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: _selectedDateRange != null
                                          ? AppColors.textPrimary
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Icon(
                                  _showCalendar
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                  color: AppColors.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (_showCalendar) ...[
                          const SizedBox(height: 16),
                          Container(
                            decoration: AppDecorations.card,
                            padding: const EdgeInsets.all(16),
                            child: DateRangePicker(
                              startDate: _selectedDateRange?.start,
                              endDate: _selectedDateRange?.end,
                              unavailableDates: _dataService.getBookedDatesForProduct(widget.dress.id),
                              onDateRangeSelected: (range) {
                                setState(() {
                                  _selectedDateRange = range;
                                  _showCalendar = false;
                                });
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Description
                        Text(
                          'Açıklama',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.dress.description,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Reviews
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Değerlendirmeler',
                              style: AppTextStyles.titleMedium,
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Tümünü Gör',
                                style: AppTextStyles.labelMedium.copyWith(
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ..._reviews.take(2).map(
                              (review) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ReviewCard(review: review),
                              ),
                            ),

                        // Bottom padding for floating button
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating Bottom Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Toplam',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₺${_totalPrice.toInt()}',
                                  style: AppTextStyles.price.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  ' / $_rentalDays gün',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: GestureDetector(
                          onTap: _canBook() ? _handleBook : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: _canBook()
                                  ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)])
                                  : null,
                              color: _canBook() ? null : AppColors.textLight,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: _canBook()
                                  ? AppDecorations.primaryGlow
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Kirala',
                                style: AppTextStyles.button.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: AppDecorations.softShadow,
        ),
        child: Icon(
          icon,
          color: color ?? AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }

  bool _canBook() {
    return _selectedSize != null && _selectedDateRange != null;
  }

  void _handleBook() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          dress: widget.dress,
          selectedSize: _selectedSize!,
          dateRange: _selectedDateRange!,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }
}
