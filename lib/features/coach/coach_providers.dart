import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_state.dart';
import '../dashboard/dashboard_providers.dart';
import '../expenses/expenses_providers.dart';

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
      // The coach can log an expense or change the cycle via its tools — any of the other three
      // screens' data can go stale after a chat reply, so refresh them explicitly rather than
      // relying on an implicit dispose/recreate when their tab is left and returned to.
      ref.invalidate(dashboardSummaryProvider);
      ref.invalidate(activeCycleProvider);
      ref.invalidate(expensesProvider);
    } catch (_) {
      state = [...state, const CoachMessage(content: 'Sorry, that message could not be sent — try again.', isUser: false)];
    }
  }
}

final coachMessagesProvider = NotifierProvider<CoachMessagesNotifier, List<CoachMessage>>(CoachMessagesNotifier.new);
