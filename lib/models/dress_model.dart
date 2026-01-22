class DressModel {
  final String id;
  final String title;
  final String designer;
  final List<String> images;
  final double pricePerDay;
  final double originalPrice;
  final double salePrice; // Satış fiyatı
  final List<String> availableSizes;
  final String color;
  final String colorHex;
  final String style; // Gece, Kokteyl, Düğün, Nişan, Mezuniyet
  final double rating;
  final int reviewCount;
  final String description;
  final List<String> tags;
  bool isFavorite;
  final List<DateTime> bookedDates;
  final String category;
  final String categoryId; // Product category for business management
  final int stockCount; // Stok adedi

  DressModel({
    required this.id,
    required this.title,
    required this.designer,
    required this.images,
    required this.pricePerDay,
    required this.originalPrice,
    this.salePrice = 0,
    required this.availableSizes,
    required this.color,
    this.colorHex = '#000000',
    required this.style,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.description = '',
    this.tags = const [],
    this.isFavorite = false,
    this.bookedDates = const [],
    this.category = 'Genel',
    this.categoryId = 'abiye',
    this.stockCount = 1,
  });

  // Calculate discount percentage
  int get discountPercentage {
    if (originalPrice <= 0) return 0;
    return ((1 - (pricePerDay / originalPrice)) * 100).round();
  }

  // Check if a date range is available
  bool isAvailable(DateTime start, DateTime end) {
    for (var date = start; date.isBefore(end.add(const Duration(days: 1))); date = date.add(const Duration(days: 1))) {
      if (bookedDates.any((bookedDate) => 
        bookedDate.year == date.year && 
        bookedDate.month == date.month && 
        bookedDate.day == date.day
      )) {
        return false;
      }
    }
    return true;
  }

  DressModel copyWith({
    String? id,
    String? title,
    String? designer,
    List<String>? images,
    double? pricePerDay,
    double? originalPrice,
    double? salePrice,
    List<String>? availableSizes,
    String? color,
    String? colorHex,
    String? style,
    double? rating,
    int? reviewCount,
    String? description,
    List<String>? tags,
    bool? isFavorite,
    List<DateTime>? bookedDates,
    String? category,
    String? categoryId,
    int? stockCount,
  }) {
    return DressModel(
      id: id ?? this.id,
      title: title ?? this.title,
      designer: designer ?? this.designer,
      images: images ?? this.images,
      pricePerDay: pricePerDay ?? this.pricePerDay,
      originalPrice: originalPrice ?? this.originalPrice,
      salePrice: salePrice ?? this.salePrice,
      availableSizes: availableSizes ?? this.availableSizes,
      color: color ?? this.color,
      colorHex: colorHex ?? this.colorHex,
      style: style ?? this.style,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      bookedDates: bookedDates ?? this.bookedDates,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      stockCount: stockCount ?? this.stockCount,
    );
  }
}
