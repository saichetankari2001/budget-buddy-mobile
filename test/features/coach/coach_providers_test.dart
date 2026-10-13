import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:budget_buddy_mobile/features/auth/auth_state.dart';
import 'package:budget_buddy_mobile/features/coach/coach_providers.dart';

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
}
