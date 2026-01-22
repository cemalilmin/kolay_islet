enum BookingStatus {
  pending,
  confirmed,
  inProgress,
  completed,   // Payment done, product still with customer
  returned,    // Product returned to store
  cancelled,
}

class BookingModel {
  final String id;
  final String dressId;
  final String dressTitle;
  final String dressImage;
  final String selectedSize;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePerDay;
  final double totalPrice;
  final double depositAmount;
  final BookingStatus status;
  final DateTime createdAt;
  final String? deliveryAddress;
  final String? notes;
  final bool isShipping; // true = şehir dışı, false = normal kiralama
  final int? shippingBufferDays; // Custom buffer days for this booking (null = use settings default)

  BookingModel({
    required this.id,
    required this.dressId,
    required this.dressTitle,
    required this.dressImage,
    required this.selectedSize,
    required this.startDate,
    required this.endDate,
    required this.pricePerDay,
    required this.totalPrice,
    this.depositAmount = 0,
    this.status = BookingStatus.pending,
    required this.createdAt,
    this.deliveryAddress,
    this.notes,
    this.isShipping = false,
    this.shippingBufferDays,
  });

  int get rentalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  String get statusText {
    switch (status) {
      case BookingStatus.pending:
        return 'Onay Bekliyor';
      case BookingStatus.confirmed:
        return 'Onaylandı';
      case BookingStatus.inProgress:
        return 'Kiralamada';
      case BookingStatus.completed:
        return 'Ödeme Tamam';
      case BookingStatus.returned:
        return 'Teslim Alındı';
      case BookingStatus.cancelled:
        return 'İptal Edildi';
    }
  }

  String get formattedDateRange {
    final startStr = '${startDate.day}/${startDate.month}/${startDate.year}';
    final endStr = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$startStr - $endStr';
  }

  BookingModel copyWith({
    String? id,
    String? dressId,
    String? dressTitle,
    String? dressImage,
    String? selectedSize,
    DateTime? startDate,
    DateTime? endDate,
    double? pricePerDay,
    double? totalPrice,
    double? depositAmount,
    BookingStatus? status,
    DateTime? createdAt,
    String? deliveryAddress,
    String? notes,
    bool? isShipping,
    int? shippingBufferDays,
  }) {
    return BookingModel(
      id: id ?? this.id,
      dressId: dressId ?? this.dressId,
      dressTitle: dressTitle ?? this.dressTitle,
      dressImage: dressImage ?? this.dressImage,
      selectedSize: selectedSize ?? this.selectedSize,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      totalPrice: totalPrice ?? this.totalPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      notes: notes ?? this.notes,
      isShipping: isShipping ?? this.isShipping,
      shippingBufferDays: shippingBufferDays ?? this.shippingBufferDays,
    );
  }
}
