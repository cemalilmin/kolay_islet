import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_decorations.dart';
import '../services/data_service.dart';

class RentalCalendarScreen extends StatefulWidget {
  const RentalCalendarScreen({super.key});

  @override
  State<RentalCalendarScreen> createState() => _RentalCalendarScreenState();
}

class _RentalCalendarScreenState extends State<RentalCalendarScreen> {
  final DataService _dataService = DataService();
  late DateTime _currentMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Text(
                'Kiralama Takvimi',
                style: AppTextStyles.headlineMedium,
              ),
            ),

            const SizedBox(height: 20),

            // Month Navigation
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: AppDecorations.card,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month - 1,
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                      color: AppColors.textPrimary,
                    ),
                    Text(
                      '${_getMonthName(_currentMonth.month)} ${_currentMonth.year}',
                      style: AppTextStyles.titleLarge,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _currentMonth = DateTime(
                            _currentMonth.year,
                            _currentMonth.month + 1,
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_right_rounded),
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Weekday Headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
                    .map((day) => SizedBox(
                          width: 40,
                          child: Center(
                            child: Text(
                              day,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Calendar Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildCalendarGrid(),
            ),

            const SizedBox(height: 24),

            // Selected Date Info
            if (_selectedDate != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '${_selectedDate!.day} ${_getMonthName(_selectedDate!.month)} - Kiralamalar',
                  style: AppTextStyles.titleMedium,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _buildRentalsForDate(_selectedDate!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final days = <Widget>[];

    // Empty cells
    for (var i = 1; i < firstWeekday; i++) {
      days.add(const SizedBox(width: 40, height: 44));
    }

    // Days
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = _isToday(date);
      final isSelected = _isSelected(date);
      final rentalCount = _getRentalCountForDate(date);

      days.add(
        GestureDetector(
          onTap: () => setState(() => _selectedDate = date),
          child: Container(
            width: 40,
            height: 44,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: isSelected ? const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]) : null,
              color: isToday && !isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: (isSelected || isToday)
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : isToday
                            ? AppColors.primary
                            : AppColors.textPrimary,
                  ),
                ),
                if (rentalCount > 0 && !isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(children: days);
  }

  Widget _buildRentalsForDate(DateTime date) {
    final rentals = _dataService.bookings.where((b) =>
        date.isAfter(b.startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(b.endDate.add(const Duration(days: 1)))).toList();

    if (rentals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available_rounded,
              size: 48,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 12),
            Text(
              'Bu tarihte kiralama yok',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
      itemCount: rentals.length,
      itemBuilder: (context, index) {
        final rental = rentals[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: AppDecorations.card,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  rental.dressImage,
                  width: 50,
                  height: 65,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 50,
                    height: 65,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.checkroom, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rental.dressTitle,
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Beden: ${rental.selectedSize}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₺${rental.totalPrice.toInt()}',
                style: AppTextStyles.titleSmall.copyWith(
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _isSelected(DateTime date) {
    if (_selectedDate == null) return false;
    return date.year == _selectedDate!.year &&
        date.month == _selectedDate!.month &&
        date.day == _selectedDate!.day;
  }

  int _getRentalCountForDate(DateTime date) {
    return _dataService.bookings.where((b) =>
        date.isAfter(b.startDate.subtract(const Duration(days: 1))) &&
        date.isBefore(b.endDate.add(const Duration(days: 1)))).length;
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }
}
