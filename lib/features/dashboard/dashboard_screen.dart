import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_providers.dart';
import '../auth/auth_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final cycleAsync = ref.watch(activeCycleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: summaryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // A 401 here is already handled globally (Task 7's onUnauthorized clears the token and
        // invalidates authStateProvider, which swaps _RootGate to the login screen on its own) —
        // this generic message only ever briefly shows during that swap, or for a real
        // non-auth failure (e.g. a network error).
        error: (_, __) => const Center(child: Text('Something went wrong loading your dashboard.')),
        data: (summary) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total spent this month', style: Theme.of(context).textTheme.titleMedium),
              Text('\$${summary.totalSpentThisMonth.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Text('Financial health', style: Theme.of(context).textTheme.titleMedium),
              Text(
                summary.healthScore.hasScore ? '${summary.healthScore.value}' : '—',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              cycleAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (cycle) => cycle == null ? const _StartCycleForm() : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StartCycleForm extends ConsumerStatefulWidget {
  const _StartCycleForm();

  @override
  ConsumerState<_StartCycleForm> createState() => _StartCycleFormState();
}

class _StartCycleFormState extends ConsumerState<_StartCycleForm> {
  final _amountController = TextEditingController();
  DateTime? _endDate;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || _endDate == null) {
      setState(() => _error = 'Enter a starting amount and an end date.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/api/cycles', data: {
        'startingAmount': amount,
        'endDate': _endDate!.toIso8601String(),
      });
      ref.invalidate(activeCycleProvider);
      ref.invalidate(dashboardSummaryProvider);
    } catch (_) {
      setState(() => _error = 'Could not start the cycle — try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Start a money cycle to see your safe-to-spend balance.'),
        TextField(
          controller: _amountController,
          decoration: const InputDecoration(labelText: 'Starting amount (AUD)'),
          keyboardType: TextInputType.number,
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 400)),
              initialDate: DateTime.now().add(const Duration(days: 14)),
            );
            if (picked != null) setState(() => _endDate = picked);
          },
          child: Text(_endDate == null ? 'Pick an end date' : _endDate!.toIso8601String().split('T').first),
        ),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting ? const CircularProgressIndicator() : const Text('Start cycle'),
        ),
      ],
    );
  }
}
