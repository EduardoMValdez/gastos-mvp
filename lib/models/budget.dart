class Budget {
  final int? id;
  final int categoryId;
  final double weeklyLimit;
  const Budget({this.id, required this.categoryId, required this.weeklyLimit});

  factory Budget.fromMap(Map<String, Object?> m) => Budget(
        id: m['id'] as int,
        categoryId: m['category_id'] as int,
        weeklyLimit: (m['weekly_limit'] as num).toDouble(),
      );
}