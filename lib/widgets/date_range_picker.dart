import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DateRangePicker extends StatefulWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Set<DateTime> unavailableDates;
  final ValueChanged<DateTimeRange>? onDateRangeSelected;

  const DateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    this.unavailableDates = const {},
    this.onDateRangeSelected,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late DateTime _currentMonth;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSelectingEndDate = false;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  bool _isUnavailable(DateTime date) {
    return widget.unavailableDates.any((d) =>
        d.year == date.year && d.month == date.month && d.day == date.day);
  }

  bool _isInRange(DateTime date) {
    if (_startDate == null || _endDate == null) return false;
    return date.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
        date.isBefore(_endDate!.add(const Duration(days: 1)));
  }

  bool _isStart(DateTime date) {
    if (_startDate == null) return false;
    return date.year == _startDate!.year &&
        date.month == _startDate!.month &&
        date.day == _startDate!.day;
  }

  bool _isEnd(DateTime date) {
    if (_endDate == null) return false;
    return date.year == _endDate!.year &&
        date.month == _endDate!.month &&
        date.day == _endDate!.day;
  }

  void _onDayTap(DateTime date) {
    if (_isUnavailable(date)) return;

    setState(() {
      if (!_isSelectingEndDate || _startDate == null) {
        _startDate = date;
        _endDate = null;
        _isSelectingEndDate = true;
      } else {
        if (date.isBefore(_startDate!)) {
          _startDate = date;
          _endDate = null;
        } else {
          // Check if any date in range is unavailable
          bool hasUnavailable = false;
          for (var d = _startDate!;
              d.isBefore(date.add(const Duration(days: 1)));
              d = d.add(const Duration(days: 1))) {
            if (_isUnavailable(d)) {
              hasUnavailable = true;
              break;
            }
          }

          if (hasUnavailable) {
            _startDate = date;
            _endDate = null;
          } else {
            _endDate = date;
            _isSelectingEndDate = false;
            widget.onDateRangeSelected?.call(
              DateTimeRange(start: _startDate!, end: _endDate!),
            );
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Month Navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textPrimary,
              ),
              Text(
                _getMonthName(_currentMonth.month) +
                    ' ${_currentMonth.year}',
                style: AppTextStyles.titleMedium,
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
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textPrimary,
              ),
            ],
          ),
        ),

        // Weekday Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
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
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        // Calendar Grid
        _buildCalendarGrid(),

        const SizedBox(height: 16),

        // Selection Info
        if (_startDate != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.date_range,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _endDate != null
                      ? '${_formatDate(_startDate!)} - ${_formatDate(_endDate!)}'
                      : 'Bitiş tarihi seçin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final days = <Widget>[];

    // Empty cells for days before the first day of month
    for (var i = 1; i < firstWeekday; i++) {
      days.add(const SizedBox(width: 40, height: 40));
    }

    // Days of the month
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = _isToday(date);
      final isPast = date.isBefore(DateTime.now().subtract(const Duration(days: 1)));
      final isUnavailable = _isUnavailable(date) || isPast;
      final isStart = _isStart(date);
      final isEnd = _isEnd(date);
      final isInRange = _isInRange(date);

      days.add(
        GestureDetector(
          onTap: isUnavailable ? null : () => _onDayTap(date),
          child: Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: (isStart || isEnd) ? AppColors.primaryGradient : null,
              color: isInRange && !isStart && !isEnd
                  ? AppColors.primary.withOpacity(0.15)
                  : isUnavailable
                      ? AppColors.surfaceVariant
                      : null,
              borderRadius: BorderRadius.circular(10),
              border: isToday && !isStart && !isEnd
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: (isStart || isEnd || isToday)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isStart || isEnd
                      ? Colors.white
                      : isUnavailable
                          ? AppColors.textLight
                          : AppColors.textPrimary,
                  decoration:
                      isUnavailable ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Wrap(
        children: days,
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month).substring(0, 3)}';
  }

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }
}
