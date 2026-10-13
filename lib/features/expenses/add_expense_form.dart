import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'expenses_providers.dart';
import '../dashboard/dashboard_providers.dart';

class AddExpenseForm extends ConsumerStatefulWidget {
  const AddExpenseForm({super.key});

  @override
  ConsumerState<AddExpenseForm> createState() => _AddExpenseFormState();
}

class _AddExpenseFormState extends ConsumerState<AddExpenseForm> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _categoryId;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _descriptionController.text.isEmpty || _categoryId == null) {
      setState(() => _error = 'Fill in amount, description, and category.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(expensesRepositoryProvider).addExpense(
            amount: amount,
            description: _descriptionController.text,
            categoryId: _categoryId!,
            date: DateTime.now(),
          );
      ref.invalidate(expensesProvider);
      ref.invalidate(dashboardSummaryProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      // A failed save stays visible as an explicit, retriable error — never dismissed as if it
      // had worked (see this plan's Review Focus item 5).
      setState(() => _error = 'Could not save this expense — check your connection and try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(controller: _amountController, decoration: const InputDecoration(labelText: 'Amount (AUD)'), keyboardType: TextInputType.number),
          TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description')),
          categoriesAsync.when(
            loading: () => const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
            error: (_, __) => const Text('Could not load categories.'),
            data: (categories) => DropdownButton<String>(
              value: _categoryId,
              hint: const Text('Category'),
              items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting ? const CircularProgressIndicator() : const Text('Add expense'),
          ),
        ],
      ),
    );
  }
}
