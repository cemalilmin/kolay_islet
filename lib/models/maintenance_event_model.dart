/// Model for maintenance/repair events that block product availability
class MaintenanceEvent {
  final String id;
  final String productId;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final DateTime createdAt;

  MaintenanceEvent({
    required this.id,
    required this.productId,
    required this.startDate,
    required this.endDate,
    this.description,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Factory constructor from Supabase JSON
  factory MaintenanceEvent.fromJson(Map<String, dynamic> json) {
    return MaintenanceEvent(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      description: json['description'] as String?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase insert
  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'description': description,
    };
  }

  /// Check if a date falls within this maintenance period
  bool overlapsWith(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return !normalizedDate.isBefore(startDate) && !normalizedDate.isAfter(endDate);
  }

  /// Check if a date range overlaps with this maintenance period
  bool overlapsWithRange(DateTime start, DateTime end) {
    return !end.isBefore(startDate) && !start.isAfter(endDate);
  }

  MaintenanceEvent copyWith({
    String? id,
    String? productId,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    DateTime? createdAt,
  }) {
    return MaintenanceEvent(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
