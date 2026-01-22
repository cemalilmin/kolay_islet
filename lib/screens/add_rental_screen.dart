import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../services/data_service.dart';
import '../models/dress_model.dart';

class AddRentalScreen extends StatefulWidget {
  const AddRentalScreen({super.key});

  @override
  State<AddRentalScreen> createState() => _AddRentalScreenState();
}

class _AddRentalScreenState extends State<AddRentalScreen> {
  final DataService _dataService = DataService();
  DressModel? _selectedDress;
  String? _selectedSize;
  DateTime? _selectedDate;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Yeni Kiralama',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Select Dress
                Text('Ürün Seç', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _showDressPicker,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppDecorations.card,
                    child: _selectedDress == null
                        ? Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.checkroom_rounded,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                'Ürün seçin...',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  _selectedDress!.images.first,
                                  width: 50,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 50,
                                    height: 60,
                                    color: AppColors.surfaceVariant,
                                    child: const Icon(Icons.checkroom),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedDress!.title,
                                      style: AppTextStyles.titleSmall,
                                    ),
                                    Text(
                                      _selectedDress!.designer,
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => setState(() {
                                  _selectedDress = null;
                                  _selectedSize = null;
                                }),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // Size Selection
                if (_selectedDress != null) ...[
                  Text('Beden', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: _selectedDress!.availableSizes.map((size) {
                      final isSelected = _selectedSize == size;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedSize = size),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]) : null,
                            color: isSelected ? null : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? null
                                : Border.all(color: AppColors.textLight.withOpacity(0.3)),
                          ),
                          child: Text(
                            size,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // Single Date Selection (günlük kiralama)
                Text('Kiralama Tarihi', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
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
                            Icons.calendar_today_rounded,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _selectedDate == null
                              ? Text(
                                  'Tarih seçin...',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDateFull(_selectedDate!),
                                      style: AppTextStyles.titleSmall,
                                    ),
                                    Text(
                                      '1 günlük kiralama',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Price
                Text('Fiyat', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppDecorations.card,
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.titleMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixText: '₺ ',
                      prefixStyle: AppTextStyles.titleMedium.copyWith(
                        color: const Color(0xFFDC2626),
                      ),
                      hintText: 'Günlük fiyat',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Note
                Text('Not (opsiyonel)', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AppDecorations.card,
                  child: TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Müşteri adı, iletişim bilgisi...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confirm Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border(
                      top: BorderSide(color: Colors.grey.withOpacity(0.2)),
                    ),
                  ),
                  child: GestureDetector(
                    onTap: _canSave ? _saveRental : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: _canSave ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]) : null,
                        color: _canSave ? null : AppColors.textLight,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: _canSave ? AppDecorations.primaryGlow : null,
                      ),
                      child: Center(
                        child: Text(
                          'Kiralama Kaydet',
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

  bool get _canSave =>
      _selectedDress != null &&
      _selectedSize != null &&
      _selectedDate != null &&
      _priceController.text.isNotEmpty;

  void _showDressPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ürün Seç', style: AppTextStyles.titleLarge),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _dataService.dresses.length,
                itemBuilder: (context, index) {
                  final dress = _dataService.dresses[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        dress.images.first,
                        width: 50,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 50,
                          height: 60,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.checkroom),
                        ),
                      ),
                    ),
                    title: Text(dress.title, style: AppTextStyles.titleSmall),
                    subtitle: Text(
                      '₺${dress.pricePerDay.toInt()}/gün',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedDress = dress;
                        _selectedSize = null;
                        _priceController.text = dress.pricePerDay.toInt().toString();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedDate = result;
      });
    }
  }

  void _saveRental() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Kiralama başarıyla kaydedildi!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context);
  }

  String _formatDateFull(DateTime date) {
    const days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}, ${days[date.weekday - 1]}';
  }
}
