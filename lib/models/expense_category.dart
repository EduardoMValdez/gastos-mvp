class ExpenseCategory {
  final int? id;
  final String name;
  final int colorValue;
  const ExpenseCategory({this.id, required this.name, required this.colorValue});

  factory ExpenseCategory.fromMap(Map<String, Object?> m) => ExpenseCategory(
        id: m['id'] as int,
        name: m['name'] as String,
        colorValue: m['color'] as int,
      );
}