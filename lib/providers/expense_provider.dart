import 'package:flutter/foundation.dart';
import '../db/app_database.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/notification_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final AppDatabase _db = AppDatabase.instance;

  List<Expense> expenses = [];
  List<ExpenseCategory> categories = [];
  Map<int, Budget> budgets = {};
  Map<int, double> monthTotals = {};
  bool loading = false;
  String? error;

  ExpenseCategory? categoryOf(int id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _run(
    Future<void> Function() action, {
    String msg = 'No se pudo completar la operación',
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      debugPrint('ExpenseProvider: $e');
      error = msg;
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _reload() async {
    categories = await _db.categories();
    budgets = await _db.budgets();
    expenses = await _db.expenses();
    monthTotals = await _db.monthTotals();
  }

  Future<void> _checkBudget(int categoryId) async {
    final b = budgets[categoryId];
    if (b == null || b.weeklyLimit <= 0) return;
    final spent = await _db.spentThisWeek(categoryId);
    final percent = spent / b.weeklyLimit * 100;
    if (percent >= 80) {
      await NotificationService.showBudgetAlert(
        categoryOf(categoryId)?.name ?? 'Gastos',
        percent,
      );
    }
  }

  Future<void> load() => _run(_reload);

  Future<void> add(Expense e) => _run(() async {
        await _db.insertExpense(e);
        await _reload();
        await _checkBudget(e.categoryId);
      });

  Future<void> edit(Expense e) => _run(() async {
        await _db.updateExpense(e);
        await _reload();
        await _checkBudget(e.categoryId);
      });

  Future<void> remove(String id) {
    // Se quita de la lista al instante para que Dismissible no marque error.
    expenses = expenses.where((e) => e.id != id).toList();
    return _run(() async {
      await _db.deleteExpense(id);
      await _reload();
    });
  }

  Future<void> saveBudget(int categoryId, double limit) => _run(() async {
        await _db.setBudget(categoryId, limit);
        await _reload();
      });
}