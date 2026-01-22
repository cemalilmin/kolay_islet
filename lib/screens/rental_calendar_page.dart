import 'package:flutter/material.dart';
import '../services/data_service.dart';
import '../models/dress_model.dart';
import '../models/booking_model.dart';
import '../theme/app_colors.dart';

// Represents what type of block a day has
enum DayBlockType {
  available,      // Green - available for rental
  rental,         // Red - actual rental day
  shippingBefore, // Navy Blue - shipping/preparation before rental
  shippingAfter,  // Navy Blue - return shipping after rental
  cleaning,       // Orange - cleaning/maintenance day
}

class RentalCalendarPage extends StatefulWidget {
  final DressModel product;

  const RentalCalendarPage({super.key, required this.product});

  @override
  State<RentalCalendarPage> createState() => _RentalCalendarPageState();
}

class _RentalCalendarPageState extends State<RentalCalendarPage> {
  final DataService data = DataService();
  DateTime? selectedDate;
  
  // Configuration for buffer days
  static const int shippingDaysBefore = 1; // 1 day before for preparation/shipping
  static const int shippingDaysAfter = 1;  // 1 day after for return shipping
  static const int cleaningDays = 1;       // 1 day for cleaning

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiralama Günü Seç'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showLegend,
          ),
        ],
      ),
      body: Column(
        children: [
          // Legend bar
          _buildLegendBar(),
          
          // Calendar
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 4, // bu ay + 3 ay
              itemBuilder: (context, index) {
                final month = DateTime(now.year, now.month + index);
                return _buildMonth(month);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: selectedDate == null ? null : _onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('KAYDET', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildLegendBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.red.shade400, 'Kirada'),
          _buildLegendItem(const Color(0xFF1E3A5F), 'Kargo'),
          _buildLegendItem(Colors.orange.shade400, 'Yıkama'),
          _buildLegendItem(Colors.grey.shade300, 'Müsait'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Takvim Renkleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegendRow(Colors.red.shade400, 'Kirada', 'Ürün müşteride'),
            const SizedBox(height: 12),
            _buildLegendRow(const Color(0xFF1E3A5F), 'Kargo', 'Hazırlık veya iade gönderisi'),
            const SizedBox(height: 12),
            _buildLegendRow(Colors.orange.shade400, 'Yıkama', 'Temizlik/bakım günü'),
            const SizedBox(height: 12),
            _buildLegendRow(Colors.grey.shade300, 'Müsait', 'Kiralamaya uygun'),
            const SizedBox(height: 16),
            const Text(
              '💡 İpucu: Bloklu bir güne uzun basarak açabilirsiniz.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(Color color, String title, String desc) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }

  void _onSave() {
    final daysLeft = selectedDate!.difference(DateTime.now()).inDays;

    if (daysLeft <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Kiralamaya 2 gün veya daha az kaldı'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    Navigator.pop(context, selectedDate);
  }

  // Get block type for a specific day
  DayBlockType _getBlockType(DateTime day, List<BookingModel> bookings) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    
    for (final booking in bookings) {
      if (booking.status == BookingStatus.returned || 
          booking.status == BookingStatus.cancelled) continue;
      
      final rentalStart = DateTime(booking.startDate.year, booking.startDate.month, booking.startDate.day);
      final rentalEnd = DateTime(booking.endDate.year, booking.endDate.month, booking.endDate.day);
      
      // Check if it's a rental day
      if (_isInRange(normalizedDay, rentalStart, rentalEnd)) {
        return DayBlockType.rental;
      }
      
      // Check if it's a shipping day before
      final shippingBeforeStart = rentalStart.subtract(Duration(days: shippingDaysBefore));
      if (_isInRange(normalizedDay, shippingBeforeStart, rentalStart.subtract(const Duration(days: 1)))) {
        return DayBlockType.shippingBefore;
      }
      
      // Check if it's a shipping day after (return)
      final shippingAfterEnd = rentalEnd.add(Duration(days: shippingDaysAfter));
      if (_isInRange(normalizedDay, rentalEnd.add(const Duration(days: 1)), shippingAfterEnd)) {
        return DayBlockType.shippingAfter;
      }
      
      // Check if it's a cleaning day
      final cleaningEnd = shippingAfterEnd.add(Duration(days: cleaningDays));
      if (_isInRange(normalizedDay, shippingAfterEnd.add(const Duration(days: 1)), cleaningEnd)) {
        return DayBlockType.cleaning;
      }
    }
    
    return DayBlockType.available;
  }

  bool _isInRange(DateTime day, DateTime start, DateTime end) {
    return (day.isAfter(start) || day.isAtSameMomentAs(start)) &&
           (day.isBefore(end) || day.isAtSameMomentAs(end));
  }

  Color _getColorForBlockType(DayBlockType type) {
    switch (type) {
      case DayBlockType.available:
        return Colors.grey.shade200;
      case DayBlockType.rental:
        return Colors.red.shade400;
      case DayBlockType.shippingBefore:
      case DayBlockType.shippingAfter:
        return const Color(0xFF1E3A5F); // Navy blue
      case DayBlockType.cleaning:
        return Colors.orange.shade400;
    }
  }

  String _getBlockTypeLabel(DayBlockType type) {
    switch (type) {
      case DayBlockType.available:
        return 'Müsait';
      case DayBlockType.rental:
        return 'Kirada (Müşteride)';
      case DayBlockType.shippingBefore:
        return 'Kargo (Gönderim)';
      case DayBlockType.shippingAfter:
        return 'Kargo (İade)';
      case DayBlockType.cleaning:
        return 'Yıkama/Temizlik';
    }
  }

  Widget _buildMonth(DateTime month) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final bookings = data.getActiveBookingsForProduct(widget.product.id);
    final firstDayOfWeek = DateTime(month.year, month.month, 1).weekday;
    
    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${turkishMonths[month.month - 1]} ${month.year}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // Weekday headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']
              .map((d) => SizedBox(
                    width: 40,
                    child: Text(d, textAlign: TextAlign.center, 
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 4),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: daysInMonth + firstDayOfWeek - 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemBuilder: (context, index) {
            // Empty cells for alignment
            if (index < firstDayOfWeek - 1) {
              return const SizedBox();
            }
            
            final dayNum = index - firstDayOfWeek + 2;
            final day = DateTime(month.year, month.month, dayNum);
            final isToday = _sameDay(day, DateTime.now());
            final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
            final blockType = _getBlockType(day, bookings);
            final isBlocked = blockType != DayBlockType.available;
            final isSelected = selectedDate != null && _sameDay(day, selectedDate!);

            Color bg;
            if (isPast) {
              bg = Colors.grey.shade100;
            } else if (isSelected) {
              bg = Colors.green;
            } else {
              bg = _getColorForBlockType(blockType);
            }

            final textColor = (isBlocked || isSelected) && !isPast 
                ? Colors.white 
                : (isPast ? Colors.grey.shade400 : Colors.black);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: (isPast || isBlocked)
                  ? null
                  : () {
                      setState(() {
                        selectedDate = day;
                      });
                    },
              onLongPress: isBlocked && !isPast
                  ? () => _showUnlockDateDialog(day, blockType, bookings)
                  : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(8),
                  border: isToday
                      ? Border.all(color: Colors.black, width: 2)
                      : null,
                ),
                child: Text(
                  '$dayNum',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showUnlockDateDialog(DateTime date, DayBlockType blockType, List<BookingModel> bookings) {
    // Find the booking that caused this block
    BookingModel? blockingBooking;
    
    for (final booking in bookings) {
      if (booking.status == BookingStatus.returned || 
          booking.status == BookingStatus.cancelled) continue;
          
      final rentalStart = DateTime(booking.startDate.year, booking.startDate.month, booking.startDate.day);
      final rentalEnd = DateTime(booking.endDate.year, booking.endDate.month, booking.endDate.day);
      final cleaningEnd = rentalEnd.add(Duration(days: shippingDaysAfter + cleaningDays));
      final shippingBeforeStart = rentalStart.subtract(Duration(days: shippingDaysBefore));
      
      if (_isInRange(date, shippingBeforeStart, cleaningEnd)) {
        blockingBooking = booking;
        break;
      }
    }

    const turkishMonths = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final dateStr = '${date.day} ${turkishMonths[date.month - 1]} ${date.year}';
    final blockLabel = _getBlockTypeLabel(blockType);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColorForBlockType(blockType).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.lock_open, color: _getColorForBlockType(blockType)),
            ),
            const SizedBox(width: 10),
            const Text('Tarihi Aç'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$dateStr tarihini açmak istiyor musunuz?',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getColorForBlockType(blockType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _getColorForBlockType(blockType).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: _getColorForBlockType(blockType), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bu tarih şu kategoride:',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          blockLabel,
                          style: TextStyle(
                            color: _getColorForBlockType(blockType),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (blockingBooking != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Müşteri: ${blockingBooking.notes ?? "Belirtilmemiş"}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Bu işlem ilgili rezervasyonu silecektir!',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (blockingBooking != null) {
                final success = await data.deleteBooking(blockingBooking.id);
                if (success && mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$dateStr ve ilişkili günler açıldı'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: Text('Tarihi Aç', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
