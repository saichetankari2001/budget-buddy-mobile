import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:budget_buddy_mobile/features/auth/auth_state.dart';
import 'package:budget_buddy_mobile/features/coach/coach_providers.dart';
import 'package:budget_buddy_mobile/features/dashboard/dashboard_providers.dart';
import 'package:budget_buddy_mobile/features/expenses/expenses_providers.dart';

void main() {
  test('sendMessage appends the user message then the coach reply to the message list', () async {
    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onPost(
      '/api/cycles/chat',
      (server) => server.reply(200, {'reply': 'Logged your coffee.'}),
      data: {'message': 'I spent \$5 on coffee'},
    );

    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);

    final notifier = container.read(coachMessagesProvider.notifier);
    await notifier.sendMessage('I spent \$5 on coffee');

    final messages = container.read(coachMessagesProvider);
    expect(messages, hasLength(2));
    expect(messages[0].isUser, isTrue);
    expect(messages[0].content, 'I spent \$5 on coffee');
    expect(messages[1].isUser, isFalse);
    expect(messages[1].content, 'Logged your coffee.');
  });

  test('a successful sendMessage invalidates dashboard/cycle/expenses providers so stale data refreshes', () async {
    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onPost(
      '/api/cycles/chat',
      (server) => server.reply(200, {'reply': 'Logged your coffee.'}),
      data: {'message': 'I spent \$5 on coffee'},
    );
    dioAdapter.onGet('/api/dashboard/summary', (server) => server.reply(200, {
          'totalSpentThisMonth': 5.0,
          'healthScore': {'value': 0, 'hasScore': false},
        }));
    dioAdapter.onGet('/api/cycles/active', (server) => server.reply(200, null));
    dioAdapter.onGet('/api/expenses', (server) => server.reply(200, []));

    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);

    // Read each provider once before sendMessage so each has an existing instance to invalidate.
    await container.read(dashboardSummaryProvider.future);
    await container.read(activeCycleProvider.future);
    await container.read(expensesProvider.future);

    var dashboardRebuilt = false;
    var cycleRebuilt = false;
    var expensesRebuilt = false;
    container.listen(dashboardSummaryProvider, (_, __) => dashboardRebuilt = true);
    container.listen(activeCycleProvider, (_, __) => cycleRebuilt = true);
    container.listen(expensesProvider, (_, __) => expensesRebuilt = true);

    await container.read(coachMessagesProvider.notifier).sendMessage('I spent \$5 on coffee');

    expect(dashboardRebuilt, isTrue);
    expect(cycleRebuilt, isTrue);
    expect(expensesRebuilt, isTrue);
  });
}
