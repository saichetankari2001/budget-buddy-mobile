import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_state.dart';

class CoachMessage {
  const CoachMessage({required this.content, required this.isUser});
  final String content;
  final bool isUser;
}

class CoachMessagesNotifier extends Notifier<List<CoachMessage>> {
  @override
  List<CoachMessage> build() => [];

  Future<void> sendMessage(String message) async {
    state = [...state, CoachMessage(content: message, isUser: true)];

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/api/cycles/chat', data: {'message': message});
      final reply = response.data['reply'] as String;
      state = [...state, CoachMessage(content: reply, isUser: false)];
    } catch (_) {
      state = [...state, const CoachMessage(content: 'Sorry, that message could not be sent — try again.', isUser: false)];
    }
  }
}

final coachMessagesProvider = NotifierProvider<CoachMessagesNotifier, List<CoachMessage>>(CoachMessagesNotifier.new);
