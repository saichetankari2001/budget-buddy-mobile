import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:budget_buddy_mobile/features/auth/auth_state.dart';
import 'package:budget_buddy_mobile/features/dashboard/dashboard_providers.dart';

void main() {
  test('dashboardSummaryProvider parses totalSpentThisMonth and healthScore', () async {
    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onGet(
      '/api/dashboard/summary',
      (server) => server.reply(200, {
        'totalSpentThisMonth': 120.5,
        'healthScore': {'value': 68, 'hasScore': true},
      }),
    );

    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);

    final summary = await container.read(dashboardSummaryProvider.future);

    expect(summary.totalSpentThisMonth, 120.5);
    expect(summary.healthScore.value, 68);
    expect(summary.healthScore.hasScore, isTrue);
  });

  test('activeCycleProvider returns null when there is no active cycle', () async {
    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onGet(
      '/api/cycles/active',
      (server) => server.reply(200, null),
    );

    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);

    final cycle = await container.read(activeCycleProvider.future);

    expect(cycle, isNull);
  });

  test('activeCycleProvider returns the active cycle map when one exists', () async {
    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onGet(
      '/api/cycles/active',
      (server) => server.reply(200, {'id': 'cycle_1', 'startingAmount': 500.0}),
    );

    final container = ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
    addTearDown(container.dispose);

    final cycle = await container.read(activeCycleProvider.future);

    expect(cycle, isNotNull);
    expect(cycle!['id'], 'cycle_1');
  });
}
