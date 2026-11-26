import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../db/app_database.dart';
import '../models/expense.dart';

class SyncService {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final AppDatabase _db = AppDatabase.instance;

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _fs.collection('users').doc(uid).collection('expenses');
  }

  /// Sube lo pendiente. El timeout evita quedarse esperando sin internet.
  Future<void> push() async {
    final pending = await _db.unsynced();
    if (pending.isEmpty) return;
    final names = {for (final c in await _db.categories()) c.id!: c.name};
    final batch = _fs.batch();
    for (final e in pending) {
      batch.set(_col.doc(e.id), {
        'amount': e.amount,
        'note': e.note,
        'date': Timestamp.fromDate(e.date),
        'category': names[e.categoryId] ?? 'Otros',
      });
    }
    await batch.commit().timeout(const Duration(seconds: 10));
    await _db.markSynced(pending.map((e) => e.id).toList());
  }

  /// Descarga los gastos que no existan localmente (la foto del ticket queda solo en el dispositivo).
  Future<void> pull() async {
    final snap = await _col
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 10));
    for (final doc in snap.docs) {
      final d = doc.data();
      final catId = await _db.categoryIdByName((d['category'] as String?) ?? 'Otros');
      await _db.insertIfAbsent(Expense(
        id: doc.id,
        amount: (d['amount'] as num).toDouble(),
        note: (d['note'] as String?) ?? '',
        date: (d['date'] as Timestamp).toDate(),
        categoryId: catId,
        synced: true,
      ));
    }
  }

  Future<void> deleteRemote(String id) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      await _col.doc(id).delete().timeout(const Duration(seconds: 10));
    } catch (_) {
      // Mejor esfuerzo; un MVP no mantiene cola de borrados.
    }
  }
}