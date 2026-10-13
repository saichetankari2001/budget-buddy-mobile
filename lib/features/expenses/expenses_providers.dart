import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../auth/auth_state.dart';

class Expense {
  const Expense({required this.id, required this.amount, required this.description, required this.date, required this.categoryName});
  final String id;
  final double amount;
  final String description;
  final DateTime date;
  final String? categoryName;

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        description: json['description'] as String,
        date: DateTime.parse(json['date'] as String),
        categoryName: (json['category'] as Map<String, dynamic>?)?['name'] as String?,
      );
}

class Category {
  const Category({required this.id, required this.name});
  final String id;
  final String name;

  factory Category.fromJson(Map<String, dynamic> json) => Category(id: json['id'] as String, name: json['name'] as String);
}

class ExpensesRepository {
  ExpensesRepository(this._dio);
  final Dio _dio;

  Future<void> addExpense({
    required double amount,
    required String description,
    required String categoryId,
    required DateTime date,
  }) async {
    // Any non-2xx response throws a DioException by default — this method intentionally does
    // NOT catch it. A failed save must propagate as a real error the UI shows, never be
    // swallowed into something that looks like success (see this plan's Review Focus item 5).
    //
    // date.toUtc() matters: the backend's Zod schema (createExpenseSchema) uses z.string().datetime(),
    // which requires a UTC-suffixed ("Z") ISO-8601 string and rejects a local-time string with a 400.
    // A plain DateTime (e.g. DateTime.now()) is local time, so its toIso8601String() has no trailing
    // "Z" — same bug class Task 9 hit and fixed for the money-cycle endDate. Caught here via manual
    // verification against the real deployed API (not by any unit test, since none exercises the real
    // date string against the real Zod schema).
    await _dio.post('/api/expenses', data: {
      'amount': amount,
      'description': description,
      'categoryId': categoryId,
      'date': date.toUtc().toIso8601String(),
    });
  }
}

final expensesRepositoryProvider = Provider<ExpensesRepository>((ref) => ExpensesRepository(ref.watch(dioProvider)));

final expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/expenses');
  return (response.data as List).map((json) => Expense.fromJson(json as Map<String, dynamic>)).toList();
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/api/categories');
  return (response.data as List).map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
});
