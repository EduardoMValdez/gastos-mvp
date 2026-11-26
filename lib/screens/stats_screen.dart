import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../utils/format.dart';
import '../utils/validators.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ExpenseProvider>();
    final sections = <PieChartSectionData>[
      for (final c in p.categories)
        if ((p.monthTotals[c.id] ?? 0) > 0)
          PieChartSectionData(
            value: p.monthTotals[c.id]!,
            color: Color(c.colorValue),
            title: c.name,
            radius: 80,
            titleStyle: const TextStyle(fontSize: 11, color: Colors.white),
          ),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas y presupuesto')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Gasto del mes por categoría',
            style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(
          height: 220,
          child: sections.isEmpty
              ? const Center(child: Text('Sin datos este mes'))
              : PieChart(PieChartData(sections: sections, sectionsSpace: 2)),
        ),
        const Divider(),
        const Text('Presupuesto semanal (toca para editar)',
            style: TextStyle(fontWeight: FontWeight.bold)),
        for (final c in p.categories)
          ListTile(
            title: Text(c.name),
            trailing: Text(money.format(p.budgets[c.id]?.weeklyLimit ?? 0)),
            onTap: () => _editBudget(
              context,
              c.id!,
              p.budgets[c.id]?.weeklyLimit ?? 0,
              c.name,
            ),
          ),
      ]),
    );
  }

  Future<void> _editBudget(
    BuildContext context,
    int categoryId,
    double current,
    String name,
  ) async {
    final ctrl = TextEditingController(text: current.toStringAsFixed(0));
    final provider = context.read<ExpenseProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('Presupuesto semanal: $name'),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '\$ '),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Guardar')),
        ],
      ),
    );
    final v = Validators.parseAmount(ctrl.text);
    if (ok == true && v != null && v > 0 && v <= 1000000) {
      await provider.saveBudget(categoryId, v);
    }
  }
}