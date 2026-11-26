class Expense {
  final String id;
  final double amount;
  final String note;
  final DateTime date;
  final int categoryId;
  final String? photoPath;
  final bool synced;
  const Expense({
    required this.id,
    required this.amount,
    this.note = '',
    required this.date,
    required this.categoryId,
    this.photoPath,
    this.synced = false,
  });
}