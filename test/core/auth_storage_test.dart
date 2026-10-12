import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budget_buddy_mobile/core/auth_storage.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late MockSecureStorage mockStorage;
  late AuthStorage authStorage;

  setUp(() {
    mockStorage = MockSecureStorage();
    authStorage = AuthStorage(storage: mockStorage);
  });

  test('saveToken writes under the fixed key', () async {
    when(() => mockStorage.write(key: any(named: 'key'), value: any(named: 'value')))
        .thenAnswer((_) async {});

    await authStorage.saveToken('abc123');

    verify(() => mockStorage.write(key: 'auth_token', value: 'abc123')).called(1);
  });

  test('readToken returns null when nothing is stored', () async {
    when(() => mockStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);

    expect(await authStorage.readToken(), isNull);
  });

  test('readToken returns the stored token', () async {
    when(() => mockStorage.read(key: 'auth_token')).thenAnswer((_) async => 'abc123');

    expect(await authStorage.readToken(), 'abc123');
  });

  test('clearToken deletes the stored token', () async {
    when(() => mockStorage.delete(key: any(named: 'key'))).thenAnswer((_) async {});

    await authStorage.clearToken();

    verify(() => mockStorage.delete(key: 'auth_token')).called(1);
  });
}
