import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:budget_buddy_mobile/features/auth/login_screen.dart';
import 'package:budget_buddy_mobile/features/auth/auth_state.dart';
import 'package:budget_buddy_mobile/core/auth_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthStorage extends Mock implements AuthStorage {}

void main() {
  testWidgets('renders email, password, and a log-in button', (tester) async {
    final mockAuthStorage = MockAuthStorage();
    when(() => mockAuthStorage.readToken()).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authStorageProvider.overrideWithValue(mockAuthStorage)],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Log in'), findsOneWidget);
  });
}
