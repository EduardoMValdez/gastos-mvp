import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/format.dart';
import '../utils/validators.dart';

class ExpenseFormScreen extends StatefulWidget {
  final Expense? expense; // null = nuevo gasto
  const ExpenseFormScreen({super.key, this.expense});
  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _note;
  int? _categoryId;
  late DateTime _date;
  String? _photoPath;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amount = TextEditingController(text: e?.amount.toString() ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _categoryId = e?.categoryId;
    _date = e?.date ?? DateTime.now();
    _photoPath = e?.photoPath;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<ExpenseProvider>();
    final e = Expense(
      id: widget.expense?.id ?? const Uuid().v4(),
      amount: Validators.parseAmount(_amount.text)!,
      note: _note.text.trim(),
      date: _date,
      categoryId: _categoryId!,
      photoPath: _photoPath,
    );
    if (widget.expense == null) {
      await provider.add(e);
    } else {
      await provider.edit(e);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(widget.expense == null ? 'Nuevo gasto' : 'Editar gasto')),
      body: Form(
        key: _formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Monto', prefixText: '\$ '),
            validator: Validators.amount,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Categoría'),
            items: [
              for (final c in provider.categories)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
            validator: (v) => v == null ? 'Elige una categoría' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _note,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'Nota (opcional)'),
            validator: Validators.note,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(dateFmt.format(_date)),
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: provider.loading ? null : _save,
            child: const Text('Guardar'),
          ),
        ]),
      ),
    );
  }
}