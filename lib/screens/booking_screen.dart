import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:ui';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../models/dress_model.dart';
import '../services/data_service.dart';

class BookingScreen extends StatefulWidget {
  final DressModel dress;
  final String selectedSize;
  final DateTimeRange dateRange;

  const BookingScreen({
    super.key,
    required this.dress,
    required this.selectedSize,
    required this.dateRange,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final DataService _dataService = DataService();
  bool _isProcessing = false;
  bool _isComplete = false;

  int get _rentalDays {
    return widget.dateRange.end.difference(widget.dateRange.start).inDays + 1;
  }

  double get _subtotal {
    return widget.dress.pricePerDay * _rentalDays;
  }

  double get _serviceFee {
    return _subtotal * 0.1; // 10% service fee
  }

  double get _deposit {
    return 500; // Fixed deposit
  }

  double get _total {
    return _subtotal + _serviceFee;
  }

  void _handleConfirm() async {
    // Check stock availability
    if (!_dataService.isProductAvailable(
      widget.dress.id,
      widget.dateRange.start,
      widget.dateRange.end,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bu tarihler için stok mevcut değil'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    
    // Create booking
    _dataService.createBooking(
      dressId: widget.dress.id,
      dressTitle: widget.dress.title,
      dressImage: widget.dress.images.isNotEmpty ? widget.dress.images.first : '',
      selectedSize: widget.selectedSize,
      startDate: widget.dateRange.start,
      endDate: widget.dateRange.end,
      pricePerDay: widget.dress.pricePerDay,
      totalPrice: _total,
      depositAmount: _deposit,
    );
    
    // Simulate processing delay
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _isProcessing = false;
      _isComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isComplete) {
      return _buildSuccessScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rezervasyon',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dress Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card,
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.dress.images.isNotEmpty
                            ? _buildDressImage(widget.dress.images.first)
                            : Container(
                                width: 80,
                                height: 100,
                                color: AppColors.surfaceVariant,
                                child: const Icon(Icons.checkroom),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.dress.title,
                              style: AppTextStyles.titleMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.dress.designer,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Beden: ${widget.selectedSize}',
                                    style: AppTextStyles.labelSmall,
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

                const SizedBox(height: 24),

                // Date Details
                Text('Tarih Bilgileri', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card,
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Teslim Alma',
                        _formatDate(widget.dateRange.start),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.event_available,
                        'İade',
                        _formatDate(widget.dateRange.end),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.access_time,
                        'Süre',
                        '$_rentalDays gün',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Delivery Address
                Text('Teslimat Adresi', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ev Adresi',
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              'Kadıköy, İstanbul',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Değiştir',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Price Breakdown
                Text('Fiyat Detayı', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card,
                  child: Column(
                    children: [
                      _buildPriceRow(
                        '₺${widget.dress.pricePerDay.toInt()} x $_rentalDays gün',
                        '₺${_subtotal.toInt()}',
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow(
                        'Hizmet bedeli',
                        '₺${_serviceFee.toInt()}',
                      ),
                      const SizedBox(height: 12),
                      _buildPriceRow(
                        'Depozito (iade edilir)',
                        '₺${_deposit.toInt()}',
                        isDeposit: true,
                      ),
                      const Divider(height: 24),
                      _buildPriceRow(
                        'Toplam',
                        '₺${_total.toInt()}',
                        isTotal: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Payment Method
                Text('Ödeme Yöntemi', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AppDecorations.card,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.credit_card,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '**** **** **** 4242',
                              style: AppTextStyles.titleSmall,
                            ),
                            Text(
                              'Kredi Kartı',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'Değiştir',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom padding
                const SizedBox(height: 120),
              ],
            ),
          ),

          // Bottom Confirm Button
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
                      top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: _isProcessing ? null : _handleConfirm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: _isProcessing
                            ? null
                            : const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                        color: _isProcessing ? AppColors.textLight : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _isProcessing
                            ? null
                            : AppDecorations.primaryGlow,
                      ),
                      child: Center(
                        child: _isProcessing
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                'Rezervasyonu Onayla',
                                style: AppTextStyles.button.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                  shape: BoxShape.circle,
                  boxShadow: AppDecorations.primaryGlow,
                ),
                child: const Icon(
                  Icons.check,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Rezervasyon Tamamlandı!',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.dress.title} için rezervasyonunuz onaylandı. Detaylar e-posta adresinize gönderildi.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: AppDecorations.primaryGlow,
                  ),
                  child: Center(
                    child: Text(
                      'Ana Sayfaya Dön',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFDC2626), size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: AppTextStyles.titleSmall,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String price, {
    bool isTotal = false,
    bool isDeposit = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTextStyles.titleMedium
              : AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
        ),
        Text(
          price,
          style: isTotal
              ? AppTextStyles.price.copyWith(color: const Color(0xFFDC2626))
              : isDeposit
                  ? AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    )
                  : AppTextStyles.titleSmall,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
  }

  Widget _buildDressImage(String imagePath) {
    final isLocalFile = imagePath.startsWith('/');
    
    if (isLocalFile) {
      return Image.file(
        File(imagePath),
        width: 80,
        height: 100,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 80,
            height: 100,
            color: AppColors.surfaceVariant,
            child: const Icon(Icons.broken_image_outlined),
          );
        },
      );
    }
    
    return Image.network(
      imagePath,
      width: 80,
      height: 100,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 80,
          height: 100,
          color: AppColors.surfaceVariant,
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}
