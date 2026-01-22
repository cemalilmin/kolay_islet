enum TransactionType { gelir, gider }

class TransactionModel {
  final String title;
  final int amount;
  final DateTime date;
  final TransactionType type;

  const TransactionModel({
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
  });
}
