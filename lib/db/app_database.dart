import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/budget.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';
import '../services/crypto_service.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  final CryptoService _crypto = CryptoService.instance;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'gastos.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('CREATE TABLE categories(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE, color INTEGER NOT NULL)');
        await db.execute('CREATE TABLE budgets(id INTEGER PRIMARY KEY AUTOINCREMENT, category_id INTEGER NOT NULL UNIQUE, weekly_limit REAL NOT NULL, FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE)');
        await db.execute('CREATE TABLE expenses(id TEXT PRIMARY KEY, amount REAL NOT NULL, note TEXT, date INTEGER NOT NULL, category_id INTEGER NOT NULL, photo_path TEXT, synced INTEGER NOT NULL DEFAULT 0, FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE RESTRICT)');
        const seed = [
          ('Comida', 0xFFEF5350),
          ('Transporte', 0xFF42A5F5),
          ('Entretenimiento', 0xFFAB47BC),
          ('Salud', 0xFF66BB6A),
          ('Otros', 0xFF8D6E63),
        ];
        for (final (name, color) in seed) {
          final id = await db.insert('categories', {'name': name, 'color': color});
          await db.insert('budgets', {'category_id': id, 'weekly_limit': 1000.0});
        }
      },
    );
  }

  // ---------- Categorías y presupuestos ----------
  Future<List<ExpenseCategory>> categories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name');
    return rows.map(ExpenseCategory.fromMap).toList();
  }

  Future<int> categoryIdByName(String name) async {
    final db = await database;
    final r = await db.query('categories', where: 'name = ?', whereArgs: [name], limit: 1);
    if (r.isNotEmpty) return r.first['id'] as int;
    final id = await db.insert('categories', {'name': name, 'color': 0xFF9E9E9E});
    await db.insert('budgets', {'category_id': id, 'weekly_limit': 1000.0});
    return id;
  }

  Future<Map<int, Budget>> budgets() async {
    final db = await database;
    final rows = await db.query('budgets');
    return {for (final r in rows) r['category_id'] as int: Budget.fromMap(r)};
  }

  Future<void> setBudget(int categoryId, double limit) async {
    final db = await database;
    await db.insert(
      'budgets',
      {'category_id': categoryId, 'weekly_limit': limit},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- Gastos (CRUD) ----------
  Map<String, Object?> _toRow(Expense e) => {
        'id': e.id,
        'amount': e.amount,
        'note': _crypto.encrypt(e.note), // dato sensible cifrado
        'date': e.date.millisecondsSinceEpoch,
        'category_id': e.categoryId,
        'photo_path': e.photoPath,
        'synced': e.synced ? 1 : 0,
      };

  Expense _fromRow(Map<String, Object?> r) => Expense(
        id: r['id'] as String,
        amount: (r['amount'] as num).toDouble(),
        note: _crypto.decrypt((r['note'] as String?) ?? ''),
        date: DateTime.fromMillisecondsSinceEpoch(r['date'] as int),
        categoryId: r['category_id'] as int,
        photoPath: r['photo_path'] as String?,
        synced: (r['synced'] as int) == 1,
      );

  // Create
  Future<void> insertExpense(Expense e) async {
    final db = await database;
    await db.insert('expenses', _toRow(e), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Read
  Future<List<Expense>> expenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC');
    return rows.map(_fromRow).toList();
  }

  // Update
  Future<void> updateExpense(Expense e) async {
    final db = await database;
    await db.update('expenses', _toRow(e), where: 'id = ?', whereArgs: [e.id]);
  }

  // Delete
  Future<void> deleteExpense(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Consultas de apoyo (sync, alertas, gráficas) ----------
  Future<List<Expense>> unsynced() async {
    final db = await database;
    final rows = await db.query('expenses', where: 'synced = 0');
    return rows.map(_fromRow).toList();
  }

  Future<void> markSynced(List<String> ids) async {
    final db = await database;
    final batch = db.batch();
    for (final id in ids) {
      batch.update('expenses', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertIfAbsent(Expense e) async {
    final db = await database;
    await db.insert('expenses', _toRow(e), conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<double> spentThisWeek(int categoryId) async {
    final db = await database;
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final r = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) AS t FROM expenses WHERE category_id = ? AND date >= ?',
      [categoryId, monday.millisecondsSinceEpoch],
    );
    return (r.first['t'] as num).toDouble();
  }

  Future<Map<int, double>> monthTotals() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month);
    final rows = await db.rawQuery(
      'SELECT category_id, SUM(amount) AS t FROM expenses WHERE date >= ? GROUP BY category_id',
      [start.millisecondsSinceEpoch],
    );
    return {for (final r in rows) r['category_id'] as int: (r['t'] as num).toDouble()};
  }
}