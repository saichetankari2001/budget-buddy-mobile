import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_state.dart';
import '../dashboard/dashboard_providers.dart';
import '../expenses/expenses_providers.dart';

/// Reads the real reason a chat message was rejected, instead of a generic fallback —
/// specifically surfaces the server's own validation message (e.g. "too long") when present,
/// since that's exactly the kind of failure a user can actually act on by editing their message.
String _chatErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final details = data['details'];
      if (details is Map) {
        final fieldErrors = details['fieldErrors'];
        if (fieldErrors is Map) {
          final messageErrors = fieldErrors['message'];
          if (messageErrors is List && messageErrors.isNotEmpty) {
            return 'Sorry, that message could not be sent — ${messageErrors.first}.';
          }
        }
      }
      if (data['error'] is String) {
        return 'Sorry, that message could not be sent — ${data['error']}.';
      }
    }
  }
  return 'Sorry, that message could not be sent — try again.';
}

class CoachMessage {
  const CoachMessage({required this.content, required this.isUser});
  final String content;
  final bool isUser;
}

class CoachMessagesNotifier extends Notifier<List<CoachMessage>> {
  Future<void>? _historyLoaded;

  /// Exposed so tests can await the startup history fetch deterministically instead of
  /// racing it with an arbitrary delay.
  Future<void>? get historyLoaded => _historyLoaded;

  @override
  List<CoachMessage> build() {
    _historyLoaded = _loadHistory();
    return [];
  }

  // The chat screen otherwise starts blank on every app launch even though the conversation is
  // saved server-side (the web app already shows it) — fetch and prepend it once, silently
  // falling back to an empty chat if there's no active cycle yet or the request fails, since the
  // user can still start a fresh conversation either way.
  Future<void> _loadHistory() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/cycles/active');
      final data = response.data as Map<String, dynamic>?;
      if (data == null) return;

      final rawMessages = (data['messages'] as List).cast<Map<String, dynamic>>();
      // The server returns newest-first; the chat view wants oldest-first.
      final loaded = rawMessages.reversed
          .map((m) => CoachMessage(content: m['content'] as String, isUser: m['kind'] == 'USER'))
          .toList();
      state = [...loaded, ...state];
    } catch (_) {
      // Swallowed deliberately — a failed history fetch shouldn't block sending new messages.
    }
  }

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
    } catch (error) {
      state = [...state, CoachMessage(content: _chatErrorMessage(error), isUser: false)];
    }
  }
}

final coachMessagesProvider = NotifierProvider<CoachMessagesNotifier, List<CoachMessage>>(CoachMessagesNotifier.new);
