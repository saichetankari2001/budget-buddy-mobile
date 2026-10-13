import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:budget_buddy_mobile/features/auth/auth_state.dart';
import 'package:budget_buddy_mobile/features/expenses/expenses_providers.dart';

void main() {
  test('expensesProvider parses the expense list', () async {
    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onGet(
      '/api/expenses',
      (server) => server.reply(200, [
        {'id': 'exp_1', 'amount': 20.0, 'description': 'Groceries', 'date': '2026-10-01T00:00:00.000Z', 'category': {'id': 'cat_1', 'name': 'Food'}},
      ]),
    );

    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);

    final expenses = await container.read(expensesProvider.future);

    expect(expenses, hasLength(1));
    expect(expenses.first.description, 'Groceries');
    expect(expenses.first.amount, 20.0);
  });

  test('addExpense throws on a non-2xx response, rather than silently succeeding', () async {
    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onPost('/api/expenses', (server) => server.reply(500, {'error': 'Internal error'}));

    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);

    expect(
      () => container.read(expensesRepositoryProvider).addExpense(
            amount: 10,
            description: 'Coffee',
            categoryId: 'cat_1',
            date: DateTime.now(),
          ),
      throwsA(isA<DioException>()),
    );
  });
}
