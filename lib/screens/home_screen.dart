import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../services/auth_service.dart';
import '../utils/format.dart';
import 'expense_form_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<ExpenseProvider>();
      await p.load();
      await p.sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final total = p.monthTotals.values.fold<double>(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis gastos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: 'Sincronizar',
            onPressed: p.sync,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpenseFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(children: [
        if (p.loading) const LinearProgressIndicator(),
        if (p.error != null)
          MaterialBanner(
            content: Text(p.error!),
            actions: [TextButton(onPressed: p.load, child: const Text('Reintentar'))],
          ),
        Card(
          margin: const EdgeInsets.all(12),
          child: ListTile(
            title: const Text('Gastado este mes'),
            trailing: Text(money.format(total),
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        Expanded(
          child: p.expenses.isEmpty && !p.loading
              ? const Center(child: Text('Aún no hay gastos. Toca + para agregar uno.'))
              : ListView.builder(
                  itemCount: p.expenses.length,
                  itemBuilder: (_, i) {
                    final e = p.expenses[i];
                    final cat = p.categoryOf(e.categoryId);
                    return Dismissible(
                      key: ValueKey(e.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) => p.remove(e.id),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(cat?.colorValue ?? 0xFF9E9E9E),
                          child: const Icon(Icons.receipt_long, color: Colors.white),
                        ),
                        title: Text(money.format(e.amount)),
                        subtitle: Text(
                          '${cat?.name ?? 'Otros'} · ${dateFmt.format(e.date)}'
                          '${e.note.isEmpty ? '' : '\n${e.note}'}',
                        ),
                        isThreeLine: e.note.isNotEmpty,
                        trailing: e.photoPath != null
                            ? const Icon(Icons.photo_camera, size: 18)
                            : null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: e)),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}