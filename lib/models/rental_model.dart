class RentalModel {
  final String productName;
  final DateTime date;
  final int price;

  RentalModel({
    required this.productName,
    required this.date,
    required this.price,
  });

  int get daysLeft {
    return date.difference(DateTime.now()).inDays;
  }
}
