import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:budget_buddy_mobile/core/auth_storage.dart';
import 'package:budget_buddy_mobile/features/auth/auth_state.dart';
import 'package:budget_buddy_mobile/features/auth/signup_screen.dart';
import 'package:budget_buddy_mobile/main.dart';

class MockAuthStorage extends Mock implements AuthStorage {}

void main() {
  testWidgets(
    'a successful signup replaces the pushed SignupScreen with the tab shell, not a stuck screen',
    (tester) async {
      final mockAuthStorage = MockAuthStorage();
      when(() => mockAuthStorage.readToken()).thenAnswer((_) async => null);
      when(() => mockAuthStorage.saveToken(any())).thenAnswer((_) async {});

      final dio = Dio();
      final dioAdapter = DioAdapter(dio: dio);
      dioAdapter.onPost(
        '/api/auth/signup',
        (server) => server.reply(200, {'token': 'new-token'}),
        data: {'email': 'new@example.com', 'password': 'password123'},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStorageProvider.overrideWithValue(mockAuthStorage),
            dioProvider.overrideWithValue(dio),
          ],
          child: const BudgetBuddyApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Start unauthenticated on LoginScreen, then push SignupScreen the same way the real app
      // does (Navigator.push from the "Sign up" link) so the pushed-route-stays-on-top bug is
      // actually exercised, not just the provider state change.
      await tester.tap(find.text('No account? Sign up'));
      await tester.pumpAndSettle();
      expect(find.byType(SignupScreen), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'new@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign up'));
      await tester.pumpAndSettle();

      // The signup succeeded: SignupScreen must be gone (popped) and the tab shell showing
      // underneath, not stuck behind the still-on-top pushed route.
      expect(find.byType(SignupScreen), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );
}
