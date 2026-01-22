class RentalPeriodModel {
  final DateTime start;
  final DateTime end;

  const RentalPeriodModel({
    required this.start,
    required this.end,
  });

  bool contains(DateTime date) {
    return !date.isBefore(start) && !date.isAfter(end);
  }
}
