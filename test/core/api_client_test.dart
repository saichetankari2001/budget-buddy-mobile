import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budget_buddy_mobile/core/api_client.dart';
import 'package:budget_buddy_mobile/core/auth_storage.dart';

class MockAuthStorage extends Mock implements AuthStorage {}

void main() {
  late MockAuthStorage mockAuthStorage;

  setUp(() {
    mockAuthStorage = MockAuthStorage();
  });

  // Note on these two tests: the brief sketched asserting via
  // `dio.options.headers`/a `sawAuthHeader` flag, but those don't actually
  // observe what the interceptor sent. http_mock_adapter 0.6.1's `reply()`
  // callback doesn't expose the matched RequestOptions either, but
  // `replyCallback()` does (its data callback receives `RequestOptions`),
  // so we capture that directly — the real source of truth for what dio
  // sent on the wire, per-request, after the interceptor ran.
  test('attaches the stored token as a Bearer Authorization header', () async {
    when(() => mockAuthStorage.readToken()).thenAnswer((_) async => 'my-token');

    final dio = createApiClient(mockAuthStorage);
    final dioAdapter = DioAdapter(dio: dio);
    RequestOptions? capturedOptions;
    dioAdapter.onGet('/api/expenses', (server) {
      server.replyCallback(200, (options) {
        capturedOptions = options;
        return [];
      });
    });

    await dio.get('/api/expenses');

    expect(capturedOptions?.headers['Authorization'], 'Bearer my-token');
  });

  test('sends no Authorization header when there is no stored token', () async {
    when(() => mockAuthStorage.readToken()).thenAnswer((_) async => null);

    final dio = createApiClient(mockAuthStorage);
    final dioAdapter = DioAdapter(dio: dio);
    RequestOptions? capturedOptions;
    dioAdapter.onGet('/api/expenses', (server) {
      server.replyCallback(200, (options) {
        capturedOptions = options;
        return [];
      });
    });

    await dio.get('/api/expenses');

    expect(capturedOptions?.headers.containsKey('Authorization'), isFalse);
  });

  test('base URL points at the deployed Budget Buddy API', () {
    final dio = createApiClient(mockAuthStorage);
    expect(dio.options.baseUrl, 'https://budget-buddy-1aur.vercel.app');
  });

  test('clears the stored token and calls onUnauthorized on a 401 response', () async {
    when(() => mockAuthStorage.readToken()).thenAnswer((_) async => 'stale-token');
    when(() => mockAuthStorage.clearToken()).thenAnswer((_) async {});
    bool unauthorizedCalled = false;

    final dio = createApiClient(mockAuthStorage, onUnauthorized: () => unauthorizedCalled = true);
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onGet('/api/dashboard/summary', (server) => server.reply(401, {'error': 'Not authenticated'}));

    await expectLater(dio.get('/api/dashboard/summary'), throwsA(isA<DioException>()));

    verify(() => mockAuthStorage.clearToken()).called(1);
    expect(unauthorizedCalled, isTrue);
  });
}
