import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budget_buddy_mobile/core/auth_storage.dart';
import 'package:budget_buddy_mobile/features/auth/auth_state.dart';

class MockAuthStorage extends Mock implements AuthStorage {}

void main() {
  test('login saves the returned token and marks the user authenticated', () async {
    final mockAuthStorage = MockAuthStorage();
    when(() => mockAuthStorage.saveToken(any())).thenAnswer((_) async {});

    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onPost(
      '/api/auth/login',
      (server) => server.reply(200, {'id': 'user_1', 'email': 'a@example.com', 'token': 'returned-token'}),
      data: {'email': 'a@example.com', 'password': 'correct-password'},
    );

    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dio),
      authStorageProvider.overrideWithValue(mockAuthStorage),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(authStateProvider.notifier);
    await notifier.login('a@example.com', 'correct-password');

    expect(container.read(authStateProvider).value?.isAuthenticated, isTrue);
    verify(() => mockAuthStorage.saveToken('returned-token')).called(1);
  });

  test('login surfaces an error state on invalid credentials', () async {
    final mockAuthStorage = MockAuthStorage();
    final dio = Dio();
    final dioAdapter = DioAdapter(dio: dio);
    dioAdapter.onPost(
      '/api/auth/login',
      (server) => server.reply(401, {'error': 'Invalid email or password'}),
      data: {'email': 'a@example.com', 'password': 'wrong-password'},
    );

    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dio),
      authStorageProvider.overrideWithValue(mockAuthStorage),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(authStateProvider.notifier);
    await notifier.login('a@example.com', 'wrong-password');

    expect(container.read(authStateProvider).hasError, isTrue);
    verifyNever(() => mockAuthStorage.saveToken(any()));
  });
}
